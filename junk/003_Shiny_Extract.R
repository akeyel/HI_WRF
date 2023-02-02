### Encoding: ISO 8859-1 (system default)

# Create a way for users to pull out the data they want

# Plan: Users download the data as a bundle with this script. They then run this script
# by dragging and dropping it into an R console. The script then pops up a SHINY
# GUI that lets them extract the data in the format they want it.

# Install required package if it is not installed
if (!require(shiny)){
  install.packages('shiny')
}
require(shiny)


#' Get day of year for year, month, day input
#' 
#' @param year the input year
#' @param month the input month
#' @param day the input day
#'
#' @return the day of the year
get.DOY = function(year, month, day){
  
  # Determine if it is a leap year
  days = get.days(year)
  
  # Sum up days from months
  Jan = 31
  Feb = 28
  Mar = 31
  Apr = 30
  May = 31
  Jun = 30
  Jul = 31
  Aug = 31
  Sep = 30
  Oct = 31
  Nov = 30
  Dec = 31
  
  if (days == 366){  Feb = 29  }
  months = c(Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)
  
  month.days = 0
  if (month != 1){
    month.days = sum(months[1:(month - 1)])
  }
  
  # Add days from days
  doy = month.days + day
  
  return(doy)
}

#' Function to get number of days in a year (copied from wnv_hlpr.R)
#'
#' Does not work for years 1900 and before or after 2100 (i.e. it does not handle the Century cases)
#'
#' @param year The year to examine
#'
#' @return The number of days in the year (365 for non-leap years, 366 for a leap year)
#'
get.days = function(year){
  
  # Add check - not designed for 1900 leap year, and won't work past 2400
  if (year <= 1900 | year >= 2100){ stop("Not designed years <= 1900 or >= 2100")}
  
  # Days are 365 unless it is a leap year
  days = 365
  if (year %% 4 == 0){
    days = 366
  }
  return(days)
}



#' Function for actually processing the data
#'
#'
ProcessData = function(Island, Variable, Scenario, Aggregation, StartDate,
                       EndDate, TemporalRes,
                       Format,
                       leap.years, break.point = 7320){
  
# For testing purposes:
  # Island = "Oahu"
  # Variable = "Precipitation"
  # Scenario = "present"
  # Aggregation = "SUM"
  # StartDate = "1990-01-01"
  # EndDate = "1990-01-07"
  # TemporalRes = 7
  # Format = "CSV"
  # leap.years = c(3, 7, 11, 15, 19)
  # break.point = 7320
  
# break.point = 366 * 20 # Should be 20 years worth of data, and assume every year is a leap year to avoid shorting myself and having it exit early
  #**# NEED TO THINK ABOUT HOW TO SET UP MONTHLY INTERVALS - THAT WOULD BE TRICKY, UNLESS WE FIXED IT TO START AT THE BEGINNING OF THE MONTH

  # Check that dates are in the correct format
  #**# CODE OUT
  
  # Split out dates into parts
  start.parts = strsplit(StartDate, '-')[[1]]
  start.year = start.parts[1]
  start.month = start.parts[2]
  start.day = start.parts[3]
  end.parts = strsplit(EndDate, '-')[[1]]
  end.year = end.parts[1]
  end.month = end.parts[2]
  end.day = end.parts[3]
  
  #**# ADD CHECKS
  # Check that StartDate is less than EndDate
  
  # Check that StartDate and EndDate are within the simulation window

  
  #**# For now, hardcoding to my paths. This will need to be adjusted
  storage.path = "D:/hawaii_local/Vars" #**# NOT USED YET
  base.path = "C:/hawaii_local/Vars"
  out.path = sprintf("C:/hawaii_local/Vars/%s/ProcessedPPT", Island)
  rainfall.grid = sprintf("%s/grids/RainfallAtlas_%s.csv", base.path, Island)
  
  if (Variable == "Precipitation"){
    var = "RAINNC"
    var.label = "DailyPPT"
  }
  
  # Select island, variable, and file with the starting date
  data.path = sprintf("%s/%s/%s_%s/%s", base.path, Island, var, Scenario, var.label)
  in.file = sprintf("%s/%s_%s_%s_year_%s.rda", data.path, var.label, var, Scenario, start.year)

  load(in.file) # loads the day.ppt.array object
  
  days = 365
  if (start.year %in% leap.years){ days = 366 }

  # Find the starting date
  # Convert year, month, day to day of year
  start.doy = get.DOY(as.numeric(start.year), as.numeric(start.month), as.numeric(start.day))
  end.doy = get.DOY(as.numeric(end.year), as.numeric(end.month), as.numeric(end.day))
  
  # Start values at first day
    
  this.doy = start.doy
  FirstDOY = this.doy
  FirstYear = as.numeric(start.year)
  #**# What if end.doy is the same as start.doy, and they are just trying to get out a different format?
  #**# For now, they just can't do that - add a check that makes sure end.doy is at least one day later than start.doy.
  is.finished = 0
  stop.count = 0
  temporal.count = 1
  FileCount = 1
  current.year = as.numeric(start.year)
  while(is.finished == 0){

    these.values = day.ppt.array[ ,,this.doy]
    
    if (temporal.count == 1){
      current.values = day.ppt.array[,,this.doy] #**# NEED TO DEAL WITH OBJECT NAME - THIS WON'T WORK FOR TEMPERATURE RIGHT NOW.
    }else{
      # Otherwise, perform the desired operation on the values
      if (toupper(Aggregation) == 'SUM'){
        current.values = current.values + these.values
      }
    }
    
    if (temporal.count == as.numeric(TemporalRes)){
      
      # Save out the file
      save.out(current.values, TemporalRes, OutputSpecs, Format, out.path,
               Island, Scenario, Variable, Aggregation, FirstDOY, FirstYear,
               rainfall.grid)
      
      # Reset current.values
      #FileCount = FileCount + 1 # Increment to prevent files from saving over each other. #**# May want a more informative indicator
      FirstDOY = this.doy + 1 # Set the starting DOY for the next file
      FirstYear = current.year
      # Roll over if last day is reached
      if (this.doy == days){
        FirstDOY = 1
        FirstYear = current.year + 1
        }
      temporal.count = 0 # Zero, because it will immediately increment on the next timestep
    }
    temporal.count = temporal.count + 1
    
  
    # Check if end day has been reached
    if (current.year == end.year & this.doy == end.doy){
      #**# Do we need more than this? (what to do about partial? Drop and warn user?)
      break
    }else{
      this.doy = this.doy + 1
      if (this.doy == days + 1){
        this.doy = 1
        current.year = current.year + 1
        # Load new file #**# WILL NEED TO BE MODIFIED FOR MAUI & HAWAII DUE TO CHUNKS
        in.file = sprintf("%s/%s_%s_%s_year_%s.rda", data.path, var.label, var, Scenario, current.year)
        load(in.file) # loads the day.ppt.array object
        
        days = 365
        if (current.year %in% leap.years){
          days = 366
        }
      }
    }
    
    # Have an emergency break for the while loop in case something goes wrong and it enters an infinte loop
    stop.count = stop.count + 1
    if (stop.count == break.point){
      message(sprintf("Something went wrong with the processing. Loop exited after %s iterations", break.point))
      break
    }
  }
}





islands = c("Oahu", "Kauai", "Maui", "Hawaii")
variables = c("Precipitation", "Temperature")
scenarios = c("Present", "RCP4.5", "RCP8.5")
#temporal.resolution = c("Daily", "Monthly", "Annual")
output.formats = c("Raster and Hawaii Rainfall Atlas", "R Array and Native_WRF") # , "WGS84"
#output.formats = c("R", "Raster") #"NetCDF", "Individual Rasters", "Aggregate Raster"

# Scenario specific information
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.


# Define UI ----
# The user interface is a series of arguments passed to a command
ui <- fluidPage(
  
  # Set up sidebar panel
  sidebarPanel(
    
    # Select Focal Island #**# For now, mosaicking is not supported  
    selectInput("Island", "Island:", choices = islands),

    # Select Focal Variable
    selectInput("Variable", "Variable:", choices = variables),
    
    selectInput("Scenario", "Scenario:", choices = scenarios),

    selectInput("Aggregation", "Aggregation:", choices = c("SUM")),
    
    textInput("StartDate", "Start Date:", "1990-01-01"),
    
    textInput("EndDate", "End Date:", "1990-01-07"),
    
    numericInput("TemporalRes", "Temporal Resolution (days)", 7),
    
    # Select an output resolution / grid alignment
    selectInput("Format", "Output Format:", choices = output.formats),
    
    # Select an output format
#    selectInput("Format", "Select Format:",
#                choices = output.formats),
    
    # Create a button to press when ready
    actionButton("RunProcess", "PROCESS!")
    
  ),
  
  ## Set up main plot panel
  #**# EMPTY FOR NOW
  mainPanel(
    plotOutput("MainPlot")
  )
  
) # End of user interface


# Define server logic ----
server <- function(input, output, session) {
  
  ### Server for the main plot
  output$MainPlot = renderPlot({
    plot(1,1, col = 'white', xaxt = 'n', yaxt = 'n',xlab = "", ylab = "")
  },
  width = 400, height = 400) #**# Is there a way to make this depend on the browser size? fillPage was reaching an upper limit of tiny, and not adjusting
  
  observeEvent(input$RunProcess, {
    out.message = sprintf("Running process for %s %s %s %s %s %s %s %s %s",
                          input$Island, input$Variable, input$Scenario, input$Aggregation,
                          input$StartDate, input$EndDate, input$TemporalRes,
                          input$Format)

    showNotification(out.message)
    
    ProcessData(input$Island, input$Variable, input$Scenario, input$Aggregation,
                input$StartDate, input$EndDate, input$TemporalRes,
                input$OutputSpecs, leap.years)    
    
    finished.message = "Processing Completed"
    #finished.message = "No processing performed. This script is still being developed"
    showNotification(finished.message)
    
  })
  
}


### Run the app
shinyApp(ui, server) #, session


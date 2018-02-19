packages.used=c("dplyr", "plotly", "shiny", "leaflet", "scales", 
                "lattice", "htmltools", "maps", "data.table", 
                "dtplyr")

# check packages that need to be installed.
packages.needed=setdiff(packages.used, 
                        intersect(installed.packages()[,1], 
                                  packages.used))
# install additional packages
if(length(packages.needed)>0){
  install.packages(packages.needed, dependencies = TRUE)
}

library(shiny)
library(leaflet)
library(scales)
library(lattice)
library(dplyr)
library(htmltools)
library(maps)
library(plotly)
library(data.table)
library(dtplyr)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Read in the dataset
  data <- hospital 
  
  state <- reactive({
    state<-input$state
  })
  
  v1 <- reactive({
    v1 <- data[data$State == paste(state()), ]
  })
  
  output$tablerank = renderDataTable({
    data1 <- v1()
    data1[,c(1,2,3,4,5,7,19)]
  },options = list(orderClasses = TRUE))
  
})

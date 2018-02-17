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

# calculate scores for a hospital 

calScore <- function(row,care.vec){
  
  # weight suggested for 7 criterion
  origin.weight <- c(11,11,11,11,2,2,2) 
  
  # care weight for 7 criterion
  care.weight <- origin.weight*care.vec/sum(origin.weight*care.vec)
  
  # hospital scores for 7 criterion
  criterion.score <- as.numeric(row[12:18])
  
  temp <- ifelse(is.na(criterion.score),0,care.weight)
  update.weight <- temp/sum(temp)
  
  score <- update.weight*criterion.score
  return(sum(score,na.rm = TRUE))
}

# switch payment to dollar signs

payswitch <- function(payment){
  if(is.na(payment)) {return("Not Avaliable")}
  else {if(payment<=1.5) {return("$")}
    else{if(payment<2.5) {return("$$")}
      else{return("$$$")}}}
}


shinyServer(function(input, output) {
  
  # Read in the dataset
  load("../data/Hospital.RData")
  data <- hospital
  
  state <- reactive({input$state})
  
  care1 <- reactive({input$care1}) # Mortality
  care2 <- reactive({input$care2}) # Safety of care
  care3 <- reactive({input$care3}) # Readmission rate
  care4 <- reactive({input$care4}) # Patient experience
  care5 <- reactive({input$care5}) # Effectiveness of care
  care6 <- reactive({input$care6}) # Timeliness of care
  care7 <- reactive({input$care7}) # Efficient use of medical imaging
  
  v2 <- reactive({v2 <- data[data$State == paste(state()), ]})
  
  care.origin <- reactive(care.origin <- c(care1(),care2(),care3(),
                                           care4(),care5(),care6(),care7()))
  
  output$tablerank = renderDataTable({
    # Dataset for the selected state
    data.state <- v2()
    
    # Care vector for 7 criterion
    care.vec <- as.numeric(care.origin())
    
    # Scores of hospitals in the selected state
    score <- apply(data.frame(data.state),1,calScore,care.vec = care.vec)
    
    # orders for hospitals
    ord <- order(score,decreasing = TRUE)
    
    rank <- 1:nrow(data.state)
    rankedtable <- cbind(rank,data.state[ord,c(1,2,3,4,5,7,19)])
    rankedtable$payment <- apply(data.frame(rankedtable$payment),1,payswitch)
    colnames(rankedtable) <- c("Rank","Hospital Name","Address","City",
                               "State","ZIP","TEL","Cost")
    
    rankedtable
    },options = list(orderClasses = TRUE))
  
})

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
library(mapproj)
library(randomForest)
library(ggplot2)
library(rpart)

# calculate scores for a hospital 

calScore <- function(row,care.vec){
  # weight suggested for 7 criterion
  origin.weight <- c(11,11,11,11,2,2,2) 
  # care weight for 7 criterion
  care.weight <- origin.weight*care.vec/sum(origin.weight*care.vec)
  # hospital scores for 7 criterion
  criterion.score <- as.numeric(c(row[c(15,17,19,21,23,25,27)]))
  
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

# switch overall rating

orswitch <- function(rating){
  if(is.na(rating)){return("Not Available")}
  else {return(as.numeric(rating))}
}

shinyServer(function(input, output){
  #read data
  load("./hos.RData")
  
  data <- hos
  
  #Inputs
  
  state<-reactive({state<-input$state})
  type <- reactive({type <- input$type})
  
  care1 <- reactive({input$care1}) # Mortality
  care2 <- reactive({input$care2}) # Safety of care
  care3 <- reactive({input$care3}) # Readmission rate
  care4 <- reactive({input$care4}) # Patient experience
  care5 <- reactive({input$care5}) # Effectiveness of care
  care6 <- reactive({input$care6}) # Timeliness of care
  care7 <- reactive({input$care7}) # Efficient use of medical imaging
  
  v1<-reactive({
    if (state() == "Select") {v1<-hos} 
      else {
        selectstate<-state()
        v1<- hos %>% filter(State == state())}})  
  
  v2 <- reactive({
    if (type() == "Select") {v2 <- v1()}
      else{
        selecttype <- type()
        v2 <- v1() %>% filter(Hospital.Type == type())}})
  
  care.origin <- reactive(care.origin <- c(care1(),care2(),care3(),
                                           care4(),care5(),care6(),care7()))
  
  # Outputs
    
  output$tableinfo = renderDataTable(
      {
        data1 <- v2()
        infotable <- data1[, c(2, 3, 4, 9, 13)]
        infotable$Hospital.overall.rating <- apply(data.frame(as.numeric(data1$Hospital.overall.rating)),
                                                          1,orswitch)
        colnames(infotable) <- c("Hospital Name","Address","City","Type",
                             "Overall Rating")
        infotable
    },options = list(orderClasses = TRUE, iDisplayLength = 5, lengthMenu = c(5, 10, 15, 20)))
  
  
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
    rankedtable <- cbind(rank,data.state[ord,c(2,3,4,5,6,8,9,29)])
    rankedtable$payment <- apply(data.frame(rankedtable$payment),1,payswitch)
    colnames(rankedtable) <- c("Rank","Hospital Name","Address","City",
                               "State","ZIP","TEL","Type","Cost")
    
    rankedtable
  },options = list(orderClasses = TRUE, iDisplayLength = 5, lengthMenu = c(5, 10, 15, 20)))
  

  hospIcons <- iconList(emergency = makeIcon("emergency_icon.png", iconWidth = 25, iconHeight =30),
                        critical = makeIcon("critical_icon.png", iconWidth = 25, iconHeight =30),
                        children = makeIcon("children_icon.png", iconWidth = 20, iconHeight =30))
  
      
    
  output$map <- renderLeaflet({
    content <- paste(sep = "<br/>",
                     paste("<font size=1.8>","<font color=green>","<b>",v2()$Hospital.Name,"</b>"),
                     paste("<font size=1>","<font color=black>",v2()$Address),
                     paste(v2()$City, v2()$State, v2()$ZIP.Code, sep = " "),  
                     paste("(",substr(v2()[ ,"Phone.Number"],1,3),") ",substr(v2()[ ,"Phone.Number"],4,6),"-",substr(v2()[ ,"Phone.Number"],7,10),sep = ""), 
                     paste("<b>","Hospital Type: ","</b>",as.character(v2()$Hospital.Type)),  
                     paste("<b>","Provides Emergency Services: ","</b>",as.character(v2()[ ,"Emergency.Services"])),
                     paste("<b>","Overall Rating: ","</b>", as.character(v2()[ ,"Hospital.overall.rating"])))
   
    
   mapStates = map("state", fill = TRUE, plot = FALSE)
   leaflet(data = mapStates) %>% addTiles() %>%
     addPolygons(fillColor = topo.colors(10, alpha = NULL), stroke = FALSE) %>%
     addMarkers(v2()$lon, v2()$lat, popup = content, icon = hospIcons[v2()$TF], clusterOptions = markerClusterOptions())
  })
 }
)
  
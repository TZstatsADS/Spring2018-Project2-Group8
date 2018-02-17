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


shinyServer(function(input, output){
  #read data
  load("../Output/hos.RData")
  
  data <- hos
  
  #Inputs
  
  state<-reactive({state<-input$state})
  
  care1 <- reactive({input$care1}) # Mortality
  care2 <- reactive({input$care2}) # Safety of care
  care3 <- reactive({input$care3}) # Readmission rate
  care4 <- reactive({input$care4}) # Patient experience
  care5 <- reactive({input$care5}) # Effectiveness of care
  care6 <- reactive({input$care6}) # Timeliness of care
  care7 <- reactive({input$care7}) # Efficient use of medical imaging
  
  v1<-reactive({
    if (state() == "None") {v1<-hos} 
      else {
        selectstate<-state()
        v1<- hos %>% filter(State == state())}})  
  
  v2 <- reactive({v2 <- data[data$State == paste(state()), ]})
  
  care.origin <- reactive(care.origin <- c(care1(),care2(),care3(),
                                           care4(),care5(),care6(),care7()))
  
  # Outputs
    
  output$tableinfo = renderDataTable(
      {
        data1 <- v1()
        data1[, c(1, 2, 3, 8, 11)]
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
    rankedtable <- cbind(rank,data.state[ord,c(1,2,3,4,5,7,19)])
    rankedtable$payment <- apply(data.frame(rankedtable$payment),1,payswitch)
    colnames(rankedtable) <- c("Rank","Hospital Name","Address","City",
                               "State","ZIP","TEL","Cost")
    
    rankedtable
  },options = list(orderClasses = TRUE, iDisplayLength = 5, lengthMenu = c(5, 10, 15, 20)))
  

    hospIcons <- iconList(
    ship = makeIcon("hospital_icon.png",iconWidth = 25,
                    iconHeight = 30))
  
      
    
  output$map <- renderLeaflet({
   content <- paste(sep = "<br/>",
                    v1()$Name,  
                    paste(v1()$Address, v1()$City, v1()$State, v1()$ZIP.Code, sep = " "),  
                    v1()[ ,7], 
                    paste("Hospital Type:", (v1()$Type)),  
                    paste("Provides Emergency Services:", (v1()[ , 10])),
                    paste("Overall Rating:", as.character(v1()[ , 11]))
                    )
   
   
   leaflet() %>%
     addTiles() %>%  
     addMarkers(hos$lon, hos$lat,
               popup = content, icon = hospIcons, clusterOptions = markerClusterOptions())
    
   mapStates = map("state", fill = TRUE, plot = FALSE)
   leaflet(data = mapStates) %>% addTiles() %>%
     addPolygons(fillColor = topo.colors(10, alpha = NULL), stroke = FALSE) %>%
     addMarkers(v1()$lon, v1()$lat, popup = content, icon = hospIcons, clusterOptions = markerClusterOptions())
   })
 }
)
  
  
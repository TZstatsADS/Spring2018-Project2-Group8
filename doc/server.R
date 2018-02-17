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

shinyServer(function(input, output){
  #read data
  load("~/Desktop/ads_proj2/Project2/Output/hos.RData")
  #subset data depending on user input in Shiny app
  
    state<-reactive({
    state<-input$state
    })
    
    
    v1<-reactive({
      if (state() == "None") {
        v1<-hos
      } 
      else {
        selectstate<-state()
        v1<- hos %>% filter(State == state())}})  
    
    output$tablerank = renderDataTable(
      {
      data1 <- v1()
      data1[, c(1, 2, 3, 8, 11)]
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
  
  
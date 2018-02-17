packages.used=c("shiny", "plotly", "shinydashboard", "leaflet")

# check packages that need to be installed.
packages.needed=setdiff(packages.used, 
                        intersect(installed.packages()[,1], 
                                  packages.used))
# install additional packages
if(length(packages.needed)>0){
  install.packages(packages.needed, dependencies = TRUE)
}


library(shiny)
library(plotly)
library(leaflet)
library(shinydashboard)

  dashboardPage(
    dashboardHeader(title = "Hospitals For You"),
    skin = "green",
    dashboardSidebar(
      selectInput("state", label = "State", 
                choices = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
                            "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
                            "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN",
                            "TX","UT","VT","VA","WA","WV","WI","WY"), selected = "AL"),
      strong("How do you care about these criterion for hospitals?"),
      
      # Criterion for hospitals
      radioButtons("care1",label = "Mortality",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care2",label = "Safety of Care",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care3",label = "Readmission rate",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care4",label = "Patient Experience",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care5",label = "Effectiveness of Care",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care6",label = "Timeliness of Care",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2),
      
      radioButtons("care7",label = "Efficient Use of Medical Imaging",
                   choices = list("Very care"=3,"Care"=2,"Not care"=1),
                   selected = 2)
    ),
    dashboardBody(
      fluidRow(
        tabBox(width=12,
               tabPanel(title="Map",width = 12,solidHeader = T,leafletOutput("map"))
              ),
        tabBox(width = 12,
           
           tabPanel('MediCare Assessment',
                    dataTableOutput("tableinfo"),
                    tags$style(type="text/css", '#myTable tfoot {display:none;}')),
           tabPanel('Personalized Ranking',
                    dataTableOutput("tablerank"),
                    tags$style(type="text/css", '#myTable tfoot {display:none;}')
                    ))
    )
        
      )
    )
    
  

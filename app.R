#Run before executing code from console
#install.packages('devtools')
#install_github("nik01010/dashboardthemes")

library(rodbcext)
library(RODBC)
library(shinydashboard)
library(shiny)
library(shinyjs)
library(dplyr)
library(leaflet)
library(devtools)
library(shinythemes)
library(RODBCext)
library(dashboardthemes)

# build connnection
conn = odbcConnect("db_name", "user_name", "pwd")
df_locations = sqlQuery(conn, "SELECT * FROM [Team07_W19].[dbo].[Locations] l INNER JOIN [Team07_W19].[dbo].[Counts] c ON l.LocationID = c.LocationID")

#parse data; add average column for bicycle count data
df_locations['AVG_count'] = rowMeans(df_locations[,23:26])

#ignore cases with missing data
df_locations = df_locations[complete.cases(df_locations), ]

#keep only the first instance for a given location
df_locations = df_locations[!duplicated(df_locations[,c("Latitude","Longitude")]),]

# save data to database
saveDataToDatabase <- function(data) {
  varTypes = as.character(data$TYPE_NAME)
  
  query <- 
    paste0("INSERT INTO [Team07_W19].[dbo].[Survey] ", "(", paste0(names(data), collapse = ", "), ") ",
           "VALUES (", paste0(rep("?", length(data)), collapse = ", "), ")")
  
  sqlExecute(conn, 
             query,
             data = data)
  
}

#UI component of App
ui <- dashboardPage(
  dashboardHeader(title = "ASA"),

  #Side bar components
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home Page", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Input: Counts, Location", tabName = "dummy", icon = icon("poll")),
      menuItem("Data Input: Survey", tabName = "survey", icon = icon("th")),
      menuItem("Viz: Static Plot", tabName = "DVS", icon = icon("chart-area")),
      menuItem("Viz: Dynamic Map", tabName = "DV", icon = icon("map-marked-alt"))
    )),
  
  #Body content
  dashboardBody(

    #Custom Theme imported from dashboardthemes  
    shinyDashboardThemes(
      theme = "blue_gradient"
    ),
    
    #Tab components
    tabItems(

      #Landing tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                box(width = 12,
                    h1("City of Portland Bike Count",style="text-align:center;"),
                    tags$p(""),
                    div(img(src="my_image.png", height=400, width=600),style="text-align:center;"),
                    tags$p(""),
                    tags$p("The City of Portland has created this website app to collect and display data regarding bicyclists interacting with intersections in the city. Volunteers collect information in the forms of counts at intersections and in-person surveys of bicyclists which can be submitted to the database using this app. Additionally this app allows users to see the collected data visually."
                           , style="font-size:18px, style=text-align:center;"),
                    h6("Authors:  Arihan Jalan, Audrey Tay, Sidney Hutchison")
                )
              )
      ),
      
      #Static Visualization tab content
      tabItem(tabName = "DVS",
              fluidRow(
                box(width = 12,
                  h1("Temperature vs. Average Bicycle Count",style="text-align:center;"),
                  tags$p(""),
                  div(img(src="static_graph.png"),style="text-align:center;"),
                  tags$p("*The number of bicycles at a given location is computed by averaging the 'HelmetMale', 'HelmetFemale', 'NoHelmetMale', 'NoHelmetFemale' for given temperature."),
                  tags$p(""),
                  tags$p("The graph above shows the Temperature vs. Average Bicycle Count data for bicyclists. One set of points (color coded in orange) shows the counts of bikers wearing helmets while the other set of points (color coded in blue) shows the counts of bikers not wearing helmets. Based on the graph we can see that as temperature increases, the number of bikers both wearing helmets and not wearing helmets increases to an optimal point at around 75 F. We can also see that there are more bikers with helmets on than those without helmets in general."
                         , style="font-size:18px")
                )
              )),
  
      
      #Content form for dummy form
      tabItem(tabName = "dummy",
              fluidRow(
                       box(width=5,
                         titlePanel("Location Count Submission Form"),

                             column(5,
                             textInput("Volunteer", "Volunteer Name"),
                             textInput("Intersection", "Intersection"),
                             textInput("Weather", "Weather"),
                             textInput("TimePeriod", "Time Period"),
                             textInput("Date", "Date"))),
                         
                          br(),br(),br(),
                       fluidRow(box(
                             column(3,
                             textInput("NorthBoundLeft", "North Bound Left"),
                             textInput("NorthBoundRight", "North Bound Right"),
                             textInput("NorthBoundThrough", "North Bound Through")),

                              column(3,
                             textInput("SouthBoundLeft", "South Bound Left"),
                             textInput("SouthBoundRight", "South Bound Right"),
                             textInput("SouthBoundThrough", "South Bound Through")),

                             column(3,
                              textInput("EastBoundLeft", "East Bound Left"),
                             textInput("EastBoundRight", "East Bound Right"),
                             textInput("EastBoundThrough", "East Bound Through")),

                              column(3,
                             textInput("WestBoundLeft", "West Bound Left"),
                             textInput("WestBoundRight", "West Bound Right"),
                             textInput("WestBoundThrough", "West Bound Through"))
                         )),
                         br(),br(),
                       fluidRow(box(
                           column(4,
                              textInput("HelmetMale", "Helmet Male"),
                             textInput("HelmetFemale", "Helmet Female"),
                             textInput("NoHelmetMale", "No Helmet Male"),
                             textInput("NoHelmetFemale", "No Helmet Female"))
                         )),

                            actionButton("", "Submit", class = "btn-primary")
              )      
            ),

      #Content form for Survey; sends data to SQL database
      tabItem(tabName = "survey",
              fluidRow(
                # state using shinyjs based on Javascript
                shinyjs::useShinyjs(),
                
                column(6,
                       wellPanel(
                         titlePanel("Survey Data Input Form"),
                         div(id = "form",
                             
                              textInput("DateTime","Date", placeholder="YYYY-MM-DD"),
                              textInput("VolunteerName","Your Name", placeholder="String; e.g.- John Doe"),
                              textInput("LocationName","Recorded Location", placeholder= "String; e.g.- Seattle"),
                              textInput("TripPurpose","Trip Purpose", placeholder= "String; e.g.- Business, Casual, etc."),
                              textInput("TripOrigin","Trip Origin", placeholder= "String; e.g.- Portland"),
                              textInput("TripDestination","Trip Destination", placeholder= "String; e.g.- Seattle"),
                              textInput("BicycleFrequency","Frequency of Bicycle Travel per week", placeholder= "Number; e.g.- 2"),
                             
                             
                             actionButton("submit", "Submit", class = "btn-primary")
                         ),
                         shinyjs::hidden(
                           # create an hidden div
                           div(
                             id = "thankyou_msg",
                             h3("Thanks, your response was submitted successfully!"),
                             actionLink("submit_another", "Submit another response")
                           )
                         )  
                       )
                )
              )),
              
      #Tab content for dynamic visualization
      tabItem(
              tabName = "DV",
              h2("Average Bicycle count by Intersection",style="text-align:center;"),
              leafletOutput("mymap"),
              selectInput("trafficClass", "Traffic Class", c("low", "medium", "high", "all"), selected="all"),
              
              p("The number of bicycles at a given location is computed by averaging the 'HelmetMale', 'HelmetFemale', 'NoHelmetMale', 'NoHelmetFemale' for a given intersection. Locations that did not have geolocation data are omitted. If data is marked with the incorrect geolocation information (different intersections having same geolocation, or latitude, longitude data)- only the first instance of the same latitude, longitude pair is kept."),
              p(""),
              p("The map above visualizes the average bicycle count for a given intersection in Portland.The blue circles represent the bicycle counts at the specified intersections. The size of a blue circle is larger if the bicycle count is larger at that location. The map allows the user to see the bicycle count data of an intersection through the lens of the vehicular traffic class of those intersections. For example, the user can choose to look at all intersections simultaneously or they can choose to only look at the intersections with a particular traffic class: high, low, or medium.")
                      )
    )
  )
)

#Server component of app
server <- function(input, output) {

  trafficClass <- reactive ({input$trafficClass})

  output$mymap <- renderLeaflet({
    print(input$trafficClass)
    df_locations_small = df_locations
    if(input$trafficClass != "all")(
      df_locations_small = (df_locations %>% filter(TrafficClass == input$trafficClass))
    )
    #addCircles(data = df_locations, lat = ~ Latitude, lng = ~ Longitude, label = ~Intersection, radius = ~sqrt(AVG_Count) * 30) 
    leafy <- leaflet() %>% addTiles() %>% addCircles(data = df_locations_small, lat = ~ Latitude, lng = ~ Longitude, label = ~Intersection, weight = 1, radius = ~sqrt(AVG_count) * 30, color="blue", fillOpacity = 0.5) 
    leafy <- leafy %>% setView(-122.6744, 45.53633, zoom = 12)
    return(leafy)
  })
  
  # define the header
  fieldsAll <- c("DateTime", "VolunteerName", "LocationName", "TripPurpose", "TripOrigin", "TripDestination", "BicycleFrequency")
  
  # get the system time
  timestamp <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%OS")
  
  # gather form data into a format  
  formData <- reactive({
    data <- sapply(fieldsAll, function(x) input[[x]])
    data <- c(data)
    data <- t(data)
    data <- as.data.frame(data)
  })
  
  # action to take when submit button is pressed
  observeEvent(input$submit, {
    saveDataToDatabase(formData())
    shinyjs::reset("form")
    shinyjs::hide("form")
    shinyjs::show("thankyou_msg")
  })
  
  # action to take when submit_another button is pressed
  observeEvent(input$submit_another, {
    shinyjs::show("form")
    shinyjs::hide("thankyou_msg")
  }) 
}

shinyApp(ui, server)
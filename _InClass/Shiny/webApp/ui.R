library(shiny)
library(xts)
data("AirPassengers")
myDat<-as.xts(AirPassengers)

shinyUI(fluidPage(
  titlePanel("An Interactive Histogram!"),
  
  sidebarLayout(
    sidebarPanel(
      dateRangeInput('date',
                label = "testing this",
                start = as.Date(start(myDat)) ,  
                end = as.Date(end(myDat)),
                min = as.Date(start(myDat)),
                max = as.Date(end(myDat))
      )
    ),
    #the below is being passed to my server code output field
    mainPanel(plotOutput("timeSeries")
    )
  )
  
  
))
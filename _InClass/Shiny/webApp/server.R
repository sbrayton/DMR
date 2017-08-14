library(shiny)
library(xts)
data("AirPassengers")
myDat<-as.xts(AirPassengers)

shinyServer(function(input, output){

  
  output$timeSeries <- renderPlot({
    plot(myDat[paste(input$date[1], input$date[2],
                     sep="/")],
         min=paste("Air", input$date[1], 
                   "till", input$date[2]))
    
  })
})
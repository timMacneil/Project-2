#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(ggplot2)
library(tree)

# Reads in pokemon data and converts NA values to "None".  Only 'Type 2' has NA values because the Pokemon
# is only one type.  This translates that appropriately for the data.  Also adds a Total Statistic setting.
pokeData = read_csv("pokemon.csv")
pokeData[is.na(pokeData)] = "None"
pokeData <- mutate(pokeData, statTotal = Attack + Defense + Speed + HP 
                                         + pokeData$'Sp. Def' + pokeData$'Sp. Atk') 

shinyServer(function(input, output, session) {
  
  #reactive value to adjust displayed data
  displayData <- reactive({
    
    if(!input$modified){ #data has not been adjusted     
      newData <- pokeData
    }
    
    else{ #data has been adjusted to meet specifications given by user
      newData <- pokeData[pokeData$'Type 1'== input$type1 & pokeData$'Type 2'== input$type2
                          & pokeData$HP>input$hp & pokeData$Attack>input$att
                          & pokeData$Defense>input$def & pokeData$Speed>input$spd
                          & pokeData$'Sp. Atk'>input$spAtt & pokeData$'Sp. Def'>input$spDef,]
    }
  })
  
  
  # Download button for the table display
  output$dlData <- downloadHandler(
    filename = "Pokemon List.csv",
    content = function(file) {
      write.csv(displayData(), file)
    },
    contentType = "csv"
  )
  
  
  # Download button for the histogram plot
  output$dlPng <- downloadHandler(
    filename = "Pokemon Histogram.png",
    
    content = function(file) {
      #creates histogram to download
      png(file)
      plotData <- displayData()
      bins <- seq( min(plotData$statTotal), max(plotData$statTotal), length.out = 20)
      hist(plotData$statTotal, breaks = bins, xlab = "Stat Total for Pokemon",
           main = "Histogram of Stat Totals")
      dev.off()
    },
    contentType = "png"
  )
  
  #creates histogram of total statistics of the pokemon currently selected
  output$statTotPlot <- renderPlot({
    
    #gets data to display 
    plotData <- displayData()
    
    #creates bin sizes and creates histogram
    bins <- seq( min(plotData$statTotal), max(plotData$statTotal), length.out = 20)
    hist(plotData$statTotal, breaks = bins, xlab = "Stat Total for Pokemon",
         main = "Histogram of Stat Totals")
  })
  
  #Creates Tree of stat totals
  output$statSupLearn2 <- renderPlot({
    
    #gets data to display
    plotData <- displayData()

    #creates tree
    fitTree <- tree(statTotal~ Attack, data = plotData)
    plot(fitTree)
    text(fitTree)
  })
  
  #Creates Tree of stat totals
  output$statSupLearn1 <- renderPlot({
    
    #gets data to display
    plotData <- displayData()
    
    #creates tree based on user input
    if(input$treeStat == 'Attack')
    {
      fitTree <- tree(statTotal~ Attack, data = plotData)
    }
    else if(input$treeStat == 'Defense')
    {
      fitTree <- tree(statTotal~ Defense, data = plotData)
    }
    else if(input$treeStat == 'HP')
    {
      fitTree <- tree(statTotal~ HP, data = plotData)
    }
    else if(input$treeStat == 'Speed')
    {
      fitTree <- tree(statTotal~ Speed, data = plotData)
    }
    else if(input$treeStat == 'Sp. Atk')
    {
      fitTree <- tree(statTotal~ pokeData'Sp. Atk', data = plotData)
    }
    else
    {
      fitTree <- tree(statTotal~ pokeData$'Sp. Def', data = plotData)     
    }
    plot(fitTree)
    text(fitTree)
  })
  
  #creates plots for attack and defense of the pokemon currently selected
  output$statCompPlot <- renderPlot({
    
    #gets data to display
    plotData <- displayData()

    # creates plots comparing total attack to total defense
    g <- ggplot(plotData, aes(x = Attack + Speed + `Sp. Atk`, y = HP + Defense + `Sp. Def`))
    g + geom_point() + xlab("Combined Attack Stats") + ylab("Combined Defense Stats")
  })
  
  # table for pokemon data
  output$list <- renderTable({   
    displayData()
  })
  
  # Shows location of cursor for data in the attack/defense plot
  output$pokeInfo <- renderText({
    paste0("Total Attack=", input$plotClick$x, "\nTotal Defense=", input$plotClick$y)
  })
  
  output$webLink <- renderUI({
    url <- a("the Hackathon challenge", href="https://www.kaggle.com/terminus7/pokemon-challenge")
    tagList("Data set was provided from kaggle by T7 as part of ", url)
  })
})
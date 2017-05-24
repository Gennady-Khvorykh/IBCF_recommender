library(shiny)
library(recommenderlab)

# Load data 
books <- readRDS("books.RDS")
model <- readRDS("IBCF_model.RDS")
r <- readRDS("rating.RDS")

# Initiate rating of new user (new session)
rating <- matrix(NA, nrow = 1, ncol(r))

# Time in seconds to wait for user response
response <- 7

## Define server logic
shinyServer(function(input, output, session){
  
  # Set variables
  cold <- TRUE
  views <- 0
  book.isbn <- 0
  
  # To restart timer() after clicking image
  observe({
    
    # Listen to cklick to restart timer
    ignore <- input$clickimg
    
    # Aything that calls `autoInvalidate` will atomatically invalidate
    autoInvalidate <<- reactiveTimer(1000 * response, session)
  })
  
  # Define timer()
  timer <- reactive({
    
    autoInvalidate()
    
    # Listen to ckick 
    ignore <- input$clickimg
    
    # Start countwoun
    eventTime <- Sys.time() + response
    
    output$timer <- renderText({
      invalidateLater(1000, session)
      paste("Timer: ", round(difftime(eventTime, Sys.time(), units = "secs")),
            "secs")
    })
    
  })
  
  # Create recommendations
  recommend <- reactive({
    
    # Set trigger for the event
    timer()
    
    if (cold || length(input$clickimg) == 0 || book.isbn == input$clickimg) {
      #Recommend 3 random books
      recom <- books[sample.int(nrow(books), size = 3), ]
      cold <<- FALSE
      
    } else {
      #Predict on the base of model
      
      user.choice <- which(books$ISBN == input$clickimg)
      
      rating[user.choice] <- 10
      
      rating.mat <- as(rating, "realRatingMatrix")
      rating.mat <- binarize(rating.mat, minRating = 4)
      
      pred <- predict(model, rating.mat)
      best3 <- bestN(pred, n = 3)
      best <- getList(best3)[[1]]
      recom <- books[as.numeric(best), ]
      book.isbn <<- input$clickimg
    }
    
    # Count and output views 
    views <<- views + 1
    output$views <- renderText({
      paste("Views:", views)
    })
    
    recom
  })
  
  # Output items recommended
  output$imageGrid <- renderUI({
    
    # Get items recommended
    books <- recommend()
    
    # Show items recommended
    fluidRow(
      apply(books, 1, function(x) {
        column(3, tags$img(src = x[2],
                           width = 300, 
                           class = "clickimg",
                           "data-value" = x[1])
        )})
    )
  })
})
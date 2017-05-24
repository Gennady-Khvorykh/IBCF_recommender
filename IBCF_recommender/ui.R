## Set user interface
shinyUI(basicPage(
  titlePanel("Item-based recommender system"),
  p("Click book you like the most"), 
  
  # Output images
  uiOutput("imageGrid"),
  p(textOutput("timer")),
  p(textOutput("views")),
  
  # Javascript code to follow clicks on images
  tags$script(HTML(
    "$(document).on('click', '.clickimg', function() {",
    "Shiny.onInputChange('clickimg', $(this).data('value'));",
    "});"
  )),
  
  # Credentials
  p("This application is made by", a("Gennady Khvorykh.", href="http://followbigdata.com"), "See the", a("source code.", href=""))
))
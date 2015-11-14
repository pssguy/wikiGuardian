# Set up reactive values initially as null

values <- reactiveValues()



## function which takes point clicked and then gets guardian data
getDate = function(data,location,session) {
  if (is.null(data))
    return(NULL)
  
  # need to adjust from milliseconds from origin
  values$trueDate <-
    as.Date(as.POSIXct((data$date) / 1000, origin = '1970-01-01 00:10:00 GMT'))
  values$name <- data$name
  ## these seem to work
  vals <- unlist(str_split(input$name,","))
  values$name <- vals[1]
  #print(values$trueDate)
  #print(values$name)
}







## obtain wiki search results
data <- eventReactive(input$goButton1,{
  if (is.null(input$name)) {
    return()
  }  else {
    vals <- unlist(str_split(input$name,","))
    
    theName <- str_replace_all(vals[1]," ","_")
    wikiURL <- paste0("http://en.wikipedia.org/wiki/",theName)
  }
  
  startDate <- as.character(input$daterange1[1])
  endDate <- as.character(input$daterange1[2])
  
  print(startDate)
  
  
  df <- wp_trend(
    page = theName,
    from = startDate,
    to   = endDate,
    
    lang = c("en")
  )
  
  df$id <- 1:nrow(df)
  
  print(glimpse(df))
  
  info = list(df = df,wikiURL = wikiURL)
  return(info)
  
})


# produce chart

observeEvent(input$goButton1,{
  print("enterchart")
  if (is.null(input$name))
    return()
  print("enterchart and should be working")
  df <- data()$df
  all_values <- function(x) {
    if (is.null(x))
      return(NULL)
    row <- df[df$id == x$id,c("date","count")]
    paste0(format(row), collapse = "<br />")
  }
  
  
  data()$df %>% ggvis( ~ date, ~ count,key:= ~ id) %>%
    layer_points() %>%
    add_tooltip(all_values, "click") %>%
    add_axis("x", title = "") %>%
    add_axis("y", title = "") %>%
    handle_click(getDate) %>%
    bind_shiny("ggChart")
  
})









# Print the Wikipedia Entry sidebar

output$testvcard <- renderUI({
  url <- data()$wikiURL
  
  
  test <- http_status(GET(url))
  
  if (test$category == "client error")
    return()
  
  
  
  vcard <- read_html(url) %>%
    html_nodes(".vcard")
  
  
  if (length(vcard) == 0)
    return()
  
  vcardInfo <- vcard[[1]]
  
  HTML(as(vcardInfo,"character"))
})

# Guardian Headlines

output$headlinesDT <- DT::renderDataTable({
  print(values$trueDate)
  if (is.null(values$trueDate))
    return()
  
  
  theName <-
    str_replace_all(isolate(values$name)," ","+") # this does mean no change until new name is entered but leaves old table up
  #  encapsulate for exact name
  theName <- paste0("%22",theName,"%22")
  
  results <- get_guardian(
    theName,
    from.date = values$trueDate,
    to.date = values$trueDate,
    
    api.key = "enteryourshere"
  )
  
  print(glimpse(results))
  
  if (nrow(results) == 1 & is.na(results$id[1])) {
    DT::datatable(
      blankdf,rownames = FALSE,escape = FALSE,options = list(
        paging = FALSE, searching = FALSE,info = FALSE
      )
    )
  } else {
    results %>%
      mutate(link = paste0(
        "<a href=\"",webUrl,"\" target=\"_blank\">", webTitle,"</a>"
      )) %>%
      select(link) %>%
      DT::datatable(
        rownames = FALSE,escape = FALSE,options = list(
          paging = FALSE, searching = FALSE,info = FALSE
        )
      )
  }
  
  
  
})

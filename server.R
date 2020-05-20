server <- function(input, output) {
 
  # -------------------------------------------------------------------------
  # Tab 1 - All charities tab  --------------------------------------------
  # -------------------------------------------------------------------------
  
  # Inputs ----------------------------------------------------------
  
  # Button to reset all all filters ---------------------------------------
  
   observeEvent(input$reset_all, {
    shinyjs::reset("all_inputs")
     Sys.sleep(5)
     click("activate_search")
  })


# Data prep ---------------------------------------------------------------

  # Subsetting data based on filters chosen  ----------

  subsetted_reshaped_data <- eventReactive(input$activate_search, {
    charity_data_reshape %>%
      filter(activities %in% input$chosen_activities) %>%
      filter(purposes %in% input$chosen_purpose) %>%
      filter(beneficiaries %in% input$chosen_benef)
  }, ignoreNULL = FALSE) #allows the inital state of app to be populated

    
  subsetted_data <- eventReactive(input$activate_search, {
          
    
    activ_purp_benef_charities <- subsetted_reshaped_data() %>%
      distinct(charity_number)
    
    charity_data_main %>%
      filter(charity_number %in% activ_purp_benef_charities$charity_number) %>%
      filter(main_operating_location %in% input$chosen_area, geographical_spread %in% input$chosen_geo_spread) %>%
      filter(income_banding %in% input$income) %>%
      filter(expenditure_banding %in% input$expend) %>%
      filter(reg_year <= input$year_reg[2] & reg_year >= input$year_reg[1]) %>%
      filter(charity_status %in% input$chosen_status) %>%
      filter(str_detect(str_to_lower(charity_name), str_to_lower(input$search_text)) | str_detect(str_to_lower(objectives), str_to_lower(input$search_text)))
  
   
    }, ignoreNULL = FALSE) #allows the inital state of app to be populated
  
  # Outputs ---------------------------------------------------------------
  
  # Value boxes -----------------------------------
  
  output$count_box <- renderValueBox({
    valueBox(
      comma(nrow(subsetted_data()), digits = 0), "Number of charities",
      icon = icon("hand-holding-heart", lib = "font-awesome"),
      color = "orange"
    )
  })

  output$perct_box <- renderValueBox({
    valueBox(
      paste0(round(nrow(subsetted_data()) / nrow(charity_data_main) * 100, 1), "%"), "of total Scottish charities",
      icon = icon("hand-holding-heart", lib = "font-awesome"),
      color = "orange"
    )
  })

  output$median_income <- renderValueBox({
    valueBox(
      paste0("£", comma(median(subsetted_data()$most_recent_year_income, na.rm = TRUE), digits = 0)), "Median income",
      icon = icon("coins", lib = "font-awesome"),
      color = "orange"
    )
  })



  # Activites, beneficiaries, purposes bar charts  --------------------------
  
  output$act_ben_purp_plots <- renderPlot({
    
    for_graphs <- subsetted_reshaped_data() %>%
      filter(charity_number %in% subsetted_data()$charity_number)
 
  
    # Bar chart of activites counts
    act_plot <- aggregate_count_function(for_graphs, activities) %>%
      ggplot(aes(x = reorder(activities, -count), y = count)) +
      geom_col(fill = "seagreen") +
      scale_y_continuous(labels = scales::comma) +
      theme_classic(base_size = 15) +
      labs(y = "Number of charities", x = "Activities")

    # Bar chart of purposes counts
    purpose_plot <- aggregate_count_function(for_graphs, purposes) %>%
      ggplot(aes(x = reorder(purposes, -count), y = count)) +
      geom_col(fill = "seagreen") +
      scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
      scale_y_continuous(labels = scales::comma) +
      theme_classic(base_size = 15) +
      labs(y = "Number of charities", x = "Purposes")

    # Bar chart of beneficiaries counts
    benef_plot <- aggregate_count_function(for_graphs, beneficiaries) %>%
      ggplot(aes(x = reorder(beneficiaries, -count), y = count)) +
      geom_col(fill = "seagreen") +
      scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
      scale_y_continuous(labels = scales::comma) +
      theme_classic(base_size = 15) +
      labs(y = "Number of charities", x = "Beneficiaries")

    #Use patchwork library to view 3 plots together
    (act_plot | benef_plot) /
      purpose_plot
  })

  
  # Geographical spread bar chart --------------------------
  
  output$area_cover_count <- renderPlot({
    subsetted_data() %>%
    #order the levels of geographical spread to move from smallest spread to largest
      mutate(geographical_spread = fct_relevel(
        geographical_spread,
        "Local point/community",
        "1 local Scottish authority",
        "2+ local Scottish authorities",
        "Broad area",
        "All/most of Scotland",
        "Scotland & other UK",
        "UK and overseas",
        "Overseas only"
      )) %>%
      ggplot(aes(x = geographical_spread)) +
      geom_bar(fill = "seagreen") +
      scale_y_continuous(labels = scales::comma) +
      theme_classic(base_size = 15) +
      labs(title = "Charities by geographical spread", x = "Geographic spread", y = "Number of charities") +
      coord_flip()
  })
  
  
  # Income and expenditure graph  --------------------------
  
  # Count number of charities in each income banding 
  output$money_graph <- renderPlot({
    income_sum <- subsetted_data() %>%
      group_by(income_banding) %>%
      summarise(count = n()) %>%
      rename(banding = income_banding)
    
    # Count number of charities in each expenditure banding 
    expend_sum <- subsetted_data() %>%
      group_by(expenditure_banding) %>%
      summarise(count = n()) %>%
      rename(banding = expenditure_banding)

    # Bind income and expentidure counts together into single dataframe
    money_data <- bind_rows("Expentiture" = expend_sum, "Income" = income_sum, .id = "money") %>%
      mutate(money = factor(money, levels = c("Income", "Expentiture"))) %>%
      mutate(banding = fct_relevel(banding, "0-5k", "5-10k", "10-100k", "100k+"))
    

    # Barchart of income and expenditure 
    ggplot(money_data, aes(x = banding, y = count, fill = money)) +
      geom_col(position = "dodge") +
      theme_classic(base_size = 15) +
      scale_y_continuous(labels = scales::comma) +
      labs(title = "Charities by most recent year income & expenditures", x = "Income & expenditure bandings (£)", y = "Number of charities") +
      scale_fill_manual("Money", values = c("seagreen", "indianred1"))
  })

  # Wordcloud of objectives --------------------------
  
  output$wordcloud <- renderPlot({

    # color palette
    pal <- brewer.pal(8, "Dark2")

    # using function made in 'functions.R' file to prep text data to be in format for wordcloud
    words_for_wordcloud <- prep_for_wordcloud(subsetted_data(), "objectives")

    # this stops the words getting cut off in the wordcloud
    par(mar = rep(0, 4))
    
    # plot wordcloud of 40 most common words
    words_for_wordcloud %>%
      with(wordcloud(word, count, max.words = 40, rot.per = 0, colors = pal))
    
   
  })

  # Map of charity address postcode locations --------------------------

  output$postcode_map <- renderLeaflet({
    
    combined_label <- paste(subsetted_data()$charity_name, "<br>", subsetted_data()$geographical_spread, "<br>")
    
    leaflet(data = subsetted_data()) %>%
      addTiles() %>%
      addMarkers(~longitude, ~latitude,
        popup = combined_label,
        clusterOptions = markerClusterOptions()
      )
  })

  #leafletProxy updates the markers without re-creating the whole map every time user changes input https://www.youtube.com/watch?v=G5BDubIyQZY
 observe({leafletProxy("postcode_map", data=subsetted_data()) %>%
            clearMarkers() %>%
            addMarkers(~longitude, ~latitude,
                    popup =  paste(subsetted_data()$charity_name, "<br>", subsetted_data()$geographical_spread, "<br>"),
                    clusterOptions = markerClusterOptions())
            })
  

  # Map of main operating areas of charities --------------------------
  
  # Count of number of charities at each boundary area
  output$boundary_map <- renderLeaflet({
    op_area_count <- subsetted_data() %>%
      group_by(main_operating_location) %>%
      summarise(count = n())

    # Join counts onto bondary geographical shape data 
    boundary_data_count <- boundary_data %>%
      left_join(op_area_count, by = c("name" = "main_operating_location"))

    # Creating bins of counts to colour accordingly - red the highest count to light yellow lowest count
    bins <- c(0, 100, 200, 500, 1000, 2000, Inf)
    pal <- colorBin("YlOrRd", domain = boundary_data_count$count)

    boundary_data_count %>%
      leaflet() %>%
      addTiles() %>%
      addProviderTiles(providers$OpenStreetMap) %>%
      addPolygons(
        fillColor = ~ pal(count),
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlight = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.7,
          bringToFront = TRUE
        ),
        label = paste(boundary_data_count$name, ":", comma(boundary_data_count$count, digits = 0)),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        )
      ) %>%
      addLegend("topleft",
        pal = pal, values = ~count,
        title = "Count of charities",
        opacity = 1
      )
  })


  # Button to download filtered dataset --------------------------
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste("scottish_charity_extract", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(subsetted_data(), file)
    }
  )

  
  # Datatable of filtered data --------------------------
  
  output$table_out <- DT::renderDT({

    # change url column for hyperlinks
    subsetted_data_hyperlink <- subsetted_data() %>%
      mutate(website = ifelse(is.na(website), website, paste0("<a href='", website, "' target='_blank'>", website, "</a>")))


    datatable(

      subsetted_data_hyperlink %>%
        select(-c(clean_postcode, longitude, latitude, reg_year, income_banding, expenditure_banding)),
      escape = FALSE, # needed for the hyperlink column
      extensions = "Buttons",
      rownames = TRUE,
      options = list(
        scrollX = TRUE,
        scrollCollapse = TRUE,
        # widen certain columns which contain a low of text
        columnDefs = list(
          list(width = "1100px", targets = c(15)),
          list(width = "700px", targets = c(12)),
          list(width = "400px", targets = c(13:14))
        ),
        autoWidth = TRUE
          )
        )
      
    
  })



  # -------------------------------------------------------------------------
  # Tab 2 - Single purpose tab  --------------------------------------------
  # -------------------------------------------------------------------------
  
  # Data prep ----------------------------------------------------------

  single_choice_number_of_purposes <- eventReactive(input$activate_search2, {
    single_choice_chosen_purpose_charities <- charity_data_reshape %>%
      filter(purposes == input$single_purpose_chosen_purpose) %>%
      distinct(charity_number)

    single_choice_chosen_word_charities <- charity_data_main %>%
      filter(str_detect(str_to_lower(charity_name), str_to_lower(input$single_purpose_search_text)) | str_detect(str_to_lower(objectives), str_to_lower(input$single_purpose_search_text))) %>%
      distinct(charity_number)


    charity_data_reshape %>%
      filter(charity_number %in% single_choice_chosen_purpose_charities$charity_number) %>%
      filter(charity_number %in% single_choice_chosen_word_charities$charity_number) %>%
      select(charity_number, purposes) %>%
      distinct(charity_number, purposes)
  }, ignoreNULL = FALSE) #allows the inital state of app to be populated

  single_choice_charities <- reactive({
    single_choice_number_of_purposes() %>%
      distinct(charity_number)
  })

  # Outputs ----------------------------------------------------------
  
  # Values box ----------------
  
  output$single_purpose_count_box <- renderValueBox({
    valueBox(
      comma(nrow(single_choice_charities()), digits = 0), "Number of charities",
      icon = icon("hand-holding-heart", lib = "font-awesome"),
      color = "orange"
    )
  })

  # Bar chart of other puroses  ----------------
  
  output$single_choice_most_other_purposes <- renderPlot({
    single_choice_number_of_purposes() %>%
      group_by(purposes) %>%
      summarise(number_of_charities = n()) %>%
      arrange(desc(number_of_charities)) %>%
      ungroup() %>%
      mutate(prop = number_of_charities / nrow(single_choice_charities())) %>%
      mutate(purposes = fct_reorder(purposes, prop, .desc = TRUE)) %>%
      ggplot(aes(x = purposes, y = prop)) +
      geom_col(fill = "seagreen") +
      scale_y_continuous(labels = scales::percent) +
      scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
      theme_classic(base_size = 15) +
      ylab("Number of charities")

  })
  
  # Table of other purpose combinations  ----------------

  output$single_choice_merged_purposes <- renderFormattable({
    single_choice_number_of_purposes() %>%
      arrange(charity_number, purposes) %>%
      group_by(charity_number) %>%
      mutate(all_purposes = paste0(purposes, collapse = "+")) %>%
      slice(1) %>%
      ungroup() %>%
      select(all_purposes) %>%
      group_by(all_purposes) %>%
      summarise(count = n()) %>%
      ungroup() %>%
      mutate(prop = round(count / sum(count), 3)) %>%
      arrange(desc(prop)) %>%
      filter(prop > 0.01) %>%
      mutate(prop = percent(prop, digits = 1)) %>%
      mutate(all_purposes = ifelse(str_count(all_purposes, pattern = "\\+") < 6, all_purposes, "more than 5 purposes")) %>% #when have more than 5 purposes then categorise as too much info/doesn't fit into table
      rename(Count = count, Purposes = all_purposes, Prop = prop) %>%
      formattable(align = c("l", "r", "r"), full_width = F, list(Count = color_bar("#FA614B66")))
  })


  # Map of main operating areas of charities --------------------------
  
  output$single_choice_operating_areas <- renderLeaflet({
    
    # Count of number of charities at each boundary area
    op_area_count <- charity_data_main %>%
      filter(charity_number %in% single_choice_charities()$charity_number) %>%
      group_by(main_operating_location) %>%
      summarise(count = n())

    # Join counts onto bondary geographical shape data 
    boundary_data_count <- boundary_data %>%
      left_join(op_area_count, by = c("name" = "main_operating_location"))
   
    # Creating bins of counts to colour accordingly - red the highest count to light yellow lowest count
    bins <- c(0, 100, 200, 500, 1000, 2000, Inf)
    pal <- colorBin("YlOrRd", domain = boundary_data_count$count)

    boundary_data_count %>%
      leaflet() %>%
      addTiles() %>%
      addProviderTiles(providers$OpenStreetMap) %>%
      addPolygons(
        fillColor = ~ pal(count),
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlight = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.7,
          bringToFront = TRUE
        ),
        label = paste(boundary_data_count$name, ":",  comma(boundary_data_count$count, digits = 0)),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        )
      ) %>%
      addLegend("topleft",
        pal = pal, values = ~count,
        title = "Count of charities",
        opacity = 1
      )
  })
}


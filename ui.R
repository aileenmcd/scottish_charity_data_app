dashboardPage(
  dashboardHeader(title = "Scottish Charities"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("All charities", tabName = "filterdata", icon = icon("hands-helping", lib = "font-awesome")),
      menuItem("Single purpose", tabName = "single", icon = icon("ribbon", lib = "font-awesome"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        "filterdata",
        fluidRow(column(
          width = 12,
          box(
            title = "Filters", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
            useShinyjs(),
            div(
              id = "all_inputs",
              fluidRow(
                column(
                  4,
                  pickerInput(
                    inputId = "chosen_area",
                    label = "Area:",
                    choices = areas,
                    selected = areas,
                    options = list(`actions-box` = TRUE, title = "Please select area"),
                    multiple = T
                  )
                ),
                column(
                  4,
                  pickerInput(
                    inputId = "chosen_purpose",
                    label = "Purposes:",
                    choices = purposes,
                    selected = purposes,
                    options = list(`actions-box` = TRUE, title = "Please select charitable purpose"),
                    multiple = T
                  )
                ),
                column(
                  4,
                  pickerInput(
                    inputId = "chosen_geo_spread",
                    label = "Area cover:",
                    choices = geo_spread,
                    selected = geo_spread,
                    options = list(`actions-box` = TRUE, title = "Please select area cover"),
                    multiple = T
                  )
                )
              ),
              fluidRow(
                column(
                  4,
                  textInput(inputId = "search_text", label = "Search:", placeholder = "Search single term")
                ),
                column(4, br(), actionButton("hideshow", "Hide/show extra filters"), actionButton("reset_all", "Reset all"), actionButton("activate_search", "Search!"))
              ),

              # code that helped with toggling additional filters to show https://github.com/daattali/advanced-shiny/tree/master/simple-toggle
              conditionalPanel(
                condition = "input.hideshow % 2 != 0",

                fluidRow(
                  column(
                    4,
                    pickerInput(
                      inputId = "chosen_benef",
                      label = "Beneficiaries:",
                      choices = benef,
                      selected = benef,
                      options = list(`actions-box` = TRUE, title = "Please select beneficiaries"),
                      multiple = T
                    )
                  ),

                  column(
                    4,
                    pickerInput(
                      inputId = "chosen_activities",
                      label = "Activites:",
                      choices = activities,
                      selected = activities,
                      options = list(`actions-box` = TRUE, title = "Please select activities"),
                      multiple = T
                    )
                  ),

                  column(
                    4,
                    pickerInput(
                      inputId = "chosen_status",
                      label = "Status:",
                      choices = status,
                      selected = status,
                      options = list(`actions-box` = TRUE, title = "Please chose status"),
                      multiple = T
                    )
                  )
                ),

                fluidRow(
                  column(
                    4,
                    sliderInput(
                      inputId = "year_reg",
                      label = "Year of Registration",
                      min = min_reg_year,
                      max = max_reg_year,
                      value = c(min_reg_year, max_reg_year),
                      sep = "" # stops comma for thousand format
                    )
                  ),





                  column(
                    4,
                    pickerInput(
                      inputId = "income",
                      label = "Income:",
                      choices = levels(factor(income_bands)),
                      selected = income_bands,
                      options = list(`actions-box` = TRUE, title = "Please select beneficiaries"),
                      multiple = T
                    )
                  ),
                  column(
                    4,
                    pickerInput(
                      inputId = "expend",
                      label = "Expenditure:",
                      choices = levels(factor(expend_bands)),
                      selected = expend_bands,
                      options = list(`actions-box` = TRUE, title = "Please select beneficiaries"),
                      multiple = T
                    )
                  )


                  #
                )
              )
            )
          )
        )),
        fluidRow(
          valueBoxOutput("count_box") %>% withSpinner(color = "#3c8dbc"),
          valueBoxOutput("perct_box") %>% withSpinner(color = "#3c8dbc"),
          valueBoxOutput("median_income") %>% withSpinner(color = "#3c8dbc")
        ),
        fluidRow(
          box(
            title = "Activities, befenficiaries & purposes", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
            plotOutput("act_ben_purp_plots") %>% withSpinner(color = "#3c8dbc")
          )
        ),
        fluidRow(
          box(
            title = "Worldcloud of objectives", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
            plotOutput("wordcloud") %>% withSpinner(color = "#3c8dbc")
          )
        ),
        fluidRow(box(
          title = "Area cover & finances", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
          column(6, plotOutput("area_cover_count")),
          column(6, plotOutput("money_graph"))
        )),
        fluidRow(box(
          title = "Locations", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
          column(6, h4("Map of charity addresses"), leafletOutput("postcode_map")),
          column(6, h4("Map of main operating areas of charities"), leafletOutput("boundary_map"))
        )),
        fluidRow(box(
          title = "Raw data", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
          downloadButton("download_data"), br(), DT::dataTableOutput("table_out")
        ))
      ),
      tabItem(
        "single",
        fluidRow(
          column(
            7,
            box(
              title = "Filters", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,

              column(
                6,
                pickerInput(
                  inputId = "single_purpose_chosen_purpose",
                  label = "Purpose:",
                  choices = purposes,
                  selected = purposes[1]
                )
              ),
              column(
                6,
                textInput(inputId = "single_purpose_search_text", label = "Search:", placeholder = "Search single term")
              )
            )
          ),

          column(
            5, br(),
            valueBoxOutput("single_purpose_count_box", width = 12) %>% withSpinner(color = "#3c8dbc")
          )
        ),

        fluidRow(box(
          title = "Other purposes", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
          plotOutput("single_choice_most_other_purposes") %>% withSpinner(color = "#3c8dbc")
        )),
        fluidRow(box(
          title = "Other purposes & main operating area", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
          column(6, leafletOutput("single_choice_operating_areas") %>% withSpinner(color = "#3c8dbc")),
          column(6, formattableOutput("single_choice_merged_purposes") %>% withSpinner(color = "#3c8dbc"))
        ))
      )
    )
  )
)
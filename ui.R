dashboardPage(
  dashboardHeader(title = "Scottish Charities"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "info", icon = icon("info-circle", lib = "font-awesome")),
      menuItem("All charities", tabName = "filterdata", icon = icon("hands-helping", lib = "font-awesome")),
      menuItem("Single purpose", tabName = "single", icon = icon("ribbon", lib = "font-awesome"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        "info",
        h4("Overview"),
        div(class = "separator"),
        tags$p("This app allows exploration and visualisation of charities in Scotland. It uses information from the OSCR Scottish Charity Register (found ", tags$a("here", href ="https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download/"), ") supplied by the Office of the Scottish Charity Regulator and licensed under the Open Government Licence v.3.0. The licence can be found ", tags$a("here", href ="http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"), "."), 
        div(class = "separator"),
        tags$p("Users can not only visualise the data (via charts, maps and high level figures) but also download a subset of the main dataset as csv file to allow further exploration by the user. For more information on the data see the ", tags$a("data dictionary", href = "https://www.oscr.org.uk/media/3788/2018-07-20-description-of-charity-register-download-fields-updated-08_11_2019.pdf"),"."),
        div(class = "separator"),
        h4("Purpose"),
        div(class = "separator"),
        tags$p("To make it easier to get insights and an overview of charities in Scotland at a high level. The app allows users to generate insights and comparisons between different areas and purposes. Users can look at questions and problems such as:"),

        tags$div(
          tags$ul(
            tags$li("How many education charities are in my area that only operate locally?"),
tags$li("How do the number of sports charities within Edinburgh compare to Stirling?, How many of these are for younger people?"),
tags$li("I want to volunteer to a very small charity (perhaps income less than £10k in the last year) that has a main office close to me. I want to generate a list of these charities and easy links to their websites."),
tags$li("How many charities are there in Scotland who mainly operates overseas and what are their main purposes and recent income/expentiture levels?"))),
tags$p("...and many more."),
div(class = "separator"),
tags$p("You might be looking to donate, volunteer or want to know more information about charities in a particular area, with a particular purpose or beneficiary group. Alternatively you might be looking to set up own charity that has a particular purpose and you want to know about other charities are already out there with that purpose in case it's possible to get involved in and/or donate to these."),
div(class = "separator"),
tags$p("I hope this app will help with these searches."),
        div(class = "separator"),
        h4("Demo video"),
        div(class = "separator"),
        tags$p("A short demo video of how to use the app ", tags$a("here", href = "https://youtu.be/vbxAOwAMaqQ")),
div(class = "separator"),
h4("Further information/instructions and full code"),
div(class = "separator"),
tags$p("The README of the Github page for this project",tags$a("here", href = "https://github.com/aileenmcd/scottish_charity_data_app"), "has a more detailed breakdown of each part of the app, with guided instructions and screenshots. It also includes more information on the data used, as well as all the code and packages used." ),
div(class = "separator"),
h4("Updating the data"),
div(class = "separator"),
tags$p("Currently the app does not connect directly to the Scottish Charity Register site and is manually refreshed. The data is currently up to date of 02/09/2020."),
div(class = "separator"),
h4("Feedback and contact"),
div(class = "separator"),
tags$p("Always welcome feedback and comments for improvement. Also note it’s a free version of the hosting site so it allows a limited number hours of the app a month."),
tags$div(
  tags$ul(
    tags$li("Email: aileenlmcdonald@gmail.com"),
    tags$li("Twitter: ", tags$a("here", href = "https://twitter.com/mcd_ails")),
    tags$li("LinkedIn: ", tags$a("here", href = "https://www.linkedin.com/in/aileenmcdonald/")) 
        ))),
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
                column(4, br(), actionButton("hideshow", "Hide/show extra filters")),
                column(4, br(), actionButtonStyled("activate_search", "Search!", type = "success", class="btn-lg"), actionButtonStyled("reset_all", "Reset all", type = "danger"))
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
            title = "Activities, beneficiaries & purposes", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,
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
        )),
        # Terms & condition of data requires acknowledge the source of this data
        fluidRow(align = "center", "This app uses information from the Scottish Charity Register (found ", tags$a("here", href = "https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download/"),") supplied by the Office of the Scottish Charity Regulator and licensed under the Open Government Licence v.3.0. The license can be found", tags$a("here", href = "http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"), ".")
        
      ),
      tabItem(
        "single",
        fluidRow(
          column(
            7,
            box(
              title = "Filters", width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE,

              column(
                4,
                pickerInput(
                  inputId = "single_purpose_chosen_purpose",
                  label = "Purpose:",
                  choices = purposes,
                  selected = purposes[1]
                )
              ),
              column(
                5,
                textInput(inputId = "single_purpose_search_text", label = "Search:", placeholder = "Search single term")
              ), 
              column(3, br(),
                     actionButtonStyled("activate_search2", "Search!", type = "success", class="btn-lg"))
            )),
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
        )),
        # Terms & condition of data requires acknowledge the source of this data
        fluidRow(align = "center", "This app uses information from the Scottish Charity Register (found ", tags$a("here", href = "https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download/"),") supplied by the Office of the Scottish Charity Regulator and licensed under the Open Government Licence v.3.0. The license can be found", tags$a("here", href = "http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"), ".")
        
      )
    )
  )
)

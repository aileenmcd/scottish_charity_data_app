# -------------------------------------------------------------------------
# Libraries and data load  --------------------------------
# -------------------------------------------------------------------------

# Load in libraries
library("tidyverse")
library("janitor")
library("splitstackshape")
library("shiny")
library("shinydashboard")
library("DT")
library("shinyWidgets")
library("tm")
library("wordcloud")
library("leaflet")
library("stringr")
library("formattable")
library("lubridate")
library("sf")
library("patchwork")
library("tidytext")
library("rmapshaper")
library("shinyjs")
library("formattable")
library("shinycssloaders")



# Source in functions 
source("scripts/functions.R")

# Load in clean data (cleaned via running 'data_prep.R' script)
charity_data_main <- read_csv("clean_data/clean_charity_data_main.csv")
charity_data_reshape <- read_csv("clean_data/clean_charity_data_reshape.csv")
boundary_data <- st_read("clean_data/clean_boundary_data.shp", quiet = TRUE)

# -------------------------------------------------------------------------
# Distinct category lists for user inputs  --------------------------------
# -------------------------------------------------------------------------

# Variables which can have more than one possible entry
purposes <- as.character(unique(charity_data_reshape$purposes))
activities <- as.character(unique(charity_data_reshape$activities))
benef <- as.character(unique(charity_data_reshape$beneficiaries))

# Variables which only have one entry
areas <- sort(unique(charity_data_main$main_operating_location))
geo_spread <- as.character(sort(unique(charity_data_main$geographical_spread)))
status <- unique(charity_data_main$charity_status)

# Registration year
min_reg_year <- min(lubridate::year(charity_data_main$registered_date))
max_reg_year <- max(lubridate::year(charity_data_main$registered_date))

# Income & expenditure banding
income_bands <- factor(unique(charity_data_main$income_banding), levels = c("0-5k", "5-10k", "10-100k", "100k+", "unknown"))
expend_bands <- factor(unique(charity_data_main$expenditure_banding), levels = c("0-5k", "5-10k", "10-100k", "100k+", "unknown"))




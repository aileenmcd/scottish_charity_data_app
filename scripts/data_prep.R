
# Libraries
library("tidyverse")
library("janitor")
library("httr")
library("splitstackshape") 
library("stringr")
library("lubridate")
library("sf")
library("rmapshaper")
library("readr")

# -------------------------------------------------------------------------
# Loading data -------------------------------------------------------
# -------------------------------------------------------------------------

# Loading data from website downloads but in future plan to have directly loading from the websites (code for this in 'scripts/direct_data_downloads.R' 

# Get OSCR data from https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download/
charity_filename <- str_subset(list.files(path = "data/"), "CharityExport")
charity_data <- read_csv(paste0("raw_data/", charity_filename))

# Get postcode data (has latitute and longitute of postcodes in UK that allow mapping of postcodes)
postcodes <- read_csv("raw_data/ukpostcodes.csv") %>%
  mutate(clean_postcode = toupper(str_replace_all(postcode, " ", ""))) %>%
  select(longitude, latitude, clean_postcode)

# Get Scottish Authority geographical boundary data 
# this data is found at https://borders.ukdataservice.ac.uk/easy_download.html and its the 'Scottish Local Administrative Units Level 1 2011' file
boundary_data <- st_read("raw_data/BoundaryData/scotland_laulevel1_2011.shp", quiet = TRUE)


# -------------------------------------------------------------------------
# Cleaning data - main dataset --------------------------------------------
# -------------------------------------------------------------------------

# Initial data cleaning ----------------------------------------------------------

charity_data_main <- charity_data %>%
  clean_names() %>%
  select(-c(mailing_cycle, regulatory_type)) %>%
  mutate(registered_date = as.Date(substr(registered_date, 1, 10), format = "%d/%m/%Y")) %>%
  mutate(reg_year = lubridate::year(registered_date)) %>%
  mutate(clean_postcode = toupper(str_replace_all(postcode, " ", ""))) %>%
  left_join(postcodes, by = "clean_postcode") # left join the postcode data to append the longitute and latitude for each postcode for plotting on a map


# Income & expenditure banding ----------------------------------------------------------

charity_data_main <- charity_data_main %>%
  mutate(
    income_banding =
      cut(most_recent_year_income,
          breaks = c(0, 5000, 10000, 100000, Inf), right = FALSE,
          labels = c("0-5k", "5-10k", "10-100k", "100k+")
      )
  ) %>%
  mutate(
    expenditure_banding =
      cut(most_recent_year_expenditure,
          breaks = c(0, 5000, 10000, 100000, Inf), right = FALSE,
          labels = c("0-5k", "5-10k", "10-100k", "100k+")
      )
  ) %>%
  mutate(income_banding = fct_explicit_na(income_banding, "unknown")) %>%
  mutate(expenditure_banding = fct_explicit_na(expenditure_banding, "unknown"))


# Geographical data prep ------------------------------------------------------------

# Shorten category length (for simplicity) & make an ordered factor from lowest geographical spread area to the largest
charity_data_main <- charity_data_main %>%
  mutate(geographical_spread = case_when(
    str_detect(tolower(geographical_spread), "scotland and other parts of the uk") ~ "Scotland & other UK",
    str_detect(tolower(geographical_spread), "operations cover all or most of scotland") ~ "All/most of Scotland",
    str_detect(tolower(geographical_spread), "broad area") ~ "Broad area",
    str_detect(tolower(geographical_spread), "more than one local authority") ~ "2+ local Scottish authorities",
    str_detect(tolower(geographical_spread), "within one local authority area") ~ "1 local Scottish authority",
    str_detect(tolower(geographical_spread), "local point") ~ "Local point/community",
    TRUE ~ geographical_spread
  ))


# -------------------------------------------------------------------------
# Cleaning data - purposes, beneficiaries, activites data -----------------
# -------------------------------------------------------------------------

# Reshaping purposes, beneficiaries, activites -----------------------------------------------------
# Split out the purposes, beneficiaries, activites columns and reshape (because each charity can have more than one purpose, beneficiary and activity 
charity_data_reshape <- charity_data_main %>%
  select(charity_number, activities, purposes, beneficiaries) %>%
  # remove ' symbol at start and end of strings
  map(~ str_remove_all(., "^\'|\'$")) %>%
  # cSplit only allows a single character as the separator and so replace the ',' to an artibitary character (have chosen %) to seperate by
  map(~ str_replace_all(., "','", "%")) %>%
  as_tibble() %>%
  splitstackshape::cSplit(
    c("activities", "purposes", "beneficiaries"),
    sep = "%",
    direction = "wide"
  ) %>%
  pivot_longer(
    cols = starts_with("activities"),
    names_to = "activities_name",
    values_to = "activities",
    values_drop_na = TRUE
  ) %>%
  pivot_longer(
    cols = starts_with("purposes"),
    names_to = "purposes_name",
    values_to = "purposes",
    values_drop_na = TRUE
  ) %>%
  pivot_longer(
    cols = starts_with("beneficiaries"),
    names_to = "beneficiaries_name",
    values_to = "beneficiaries",
    values_drop_na = TRUE
  ) %>%
  select(-c("activities_name", "purposes_name", "beneficiaries_name"))

# Renaming categories (to reduce length/for simplicity) -----------------------------------------------------
charity_data_reshape <- charity_data_reshape %>%
  mutate(activities = case_when(
    str_detect(tolower(activities), "organisations") ~ "gives to orgs",
    str_detect(tolower(activities), "itself") ~ "does activities",
    str_detect(tolower(activities), "individuals") ~ "gives to individuals",
    str_detect(tolower(activities), "none") ~ "none of these"
  )) %>%
  mutate(beneficiaries = case_when(
    str_detect(tolower(beneficiaries), "ethnic") ~ "ethnic/racial",
    str_detect(tolower(beneficiaries), "disabilities") ~ "disabilities/health",
    str_detect(tolower(beneficiaries), "older") ~ "older",
    str_detect(tolower(beneficiaries), "other defined") ~ "other",
    str_detect(tolower(beneficiaries), "charities") ~ "charities/vol.",
    str_detect(tolower(beneficiaries), "children") ~ "young",
    str_detect(tolower(beneficiaries), "no specific") ~ "no group/community"
  )) %>%
  mutate(purposes = case_when(
    str_detect(tolower(purposes), "education") ~ "education",
    str_detect(tolower(purposes), "religion") ~ "religion",
    str_detect(tolower(purposes), "arts") ~ "arts",
    str_detect(tolower(purposes), "environmental") ~ "environ",
    str_detect(tolower(purposes), "animal") ~ "animals",
    str_detect(tolower(purposes), "in need by reason") ~ "needs",
    str_detect(tolower(purposes), "poverty") ~ "poverty",
    str_detect(tolower(purposes), "health") ~ "health",
    str_detect(tolower(purposes), "poverty") ~ "poverty",
    str_detect(tolower(purposes), "recreational facilities") ~ "recreation",
    str_detect(tolower(purposes), "human rights") ~ "rights",
    str_detect(tolower(purposes), "sport") ~ "sport",
    str_detect(tolower(purposes), "religious") ~ "religious/racial",
    str_detect(tolower(purposes), "saving") ~ "saving lives",
    str_detect(tolower(purposes), "equality") ~ "equality/diversity",
    str_detect(tolower(purposes), "analogous") ~ "analogous",
    str_detect(tolower(purposes), "citizenship or community development") ~ "community"
  ))




# -------------------------------------------------------------------------
# Cleaning data - LA boundary area data  ----------------------------------
# -------------------------------------------------------------------------

# Re-cateogorise some of the authority names as for some there are a mismatch between the names and boundaries of the authorities in the charity data and the LA data, so do some manual changes here so they match up
boundary_data <- boundary_data %>%
  ms_simplify() %>%
  select(name, geometry) %>%
  mutate(name = as.character(name)) %>%
  mutate(name = case_when(
    name == "Aberdeen City" ~ "Aberdeen",
    name == "Dumfries and Galloway" ~ "Dumfries & Galloway",
    name == "Edinburgh, City of" ~ "City of Edinburgh",
    name == "Perth and Kinross" ~ "Perth & Kinross",
    name == "Argyll and Bute Islands" ~ "Argyll & Bute",
    name == "Argyll and Islands" ~ "Argyll & Bute",
    str_detect(name, "Helensburgh") ~ "Argyll & Bute",
    name == "North Ayrshire mainland" ~ "North Ayrshire",
    name == "Arran and Cumbrae" ~ "North Ayrshire",
    name == "North East Moray" ~ "Moray",
    name == "West Moray" ~ "Moray",
    str_detect(name, "Western Isles") ~ "Western Isles",
    name %in% c(
      "Badenoch and Strathspey", "Caithness and Sutherland", "Inverness and Nairn",
      "Lochaber", "Ross and Cromarty", "Skye and Lochalsh"
    ) ~ "Highland",
    TRUE ~ name
  ))

# code for help in how to to aggregate the polygons in the geometric data https://stackoverflow.com/questions/49354393/r-how-do-i-merge-polygon-features-in-a-shapefile-with-many-polygons-reproducib
boundary_data <- boundary_data %>%
  group_by(name) %>%
  summarise(geometry = sf::st_union(geometry)) %>%
  st_transform("+proj=longlat +datum=WGS84")

# -------------------------------------------------------------------------
# Save clean data files for app  -----------------------------------------
# -------------------------------------------------------------------------

write_csv(charity_data_main, "clean_data/clean_charity_data_main.csv")
write_csv(charity_data_reshape, "clean_data/clean_charity_data_reshape.csv")
st_write(boundary_data, "clean_data/clean_boundary_data.shp")
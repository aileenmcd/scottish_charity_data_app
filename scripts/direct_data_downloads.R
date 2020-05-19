# -------------------------------------------------------------------------
# Loading data directly from sites ----------------------------------------
# -------------------------------------------------------------------------

# If want to load data directly from the websites in the future would replace the current data load section in the 'data_prep.R' file with this. 

library(downloader)

# Get charity zip file
downloader::download("https://www.oscr.org.uk/umbraco/Surface/FormsSurface/CharityRegDownload", dest="data/CharityRegDownload.zip", mode="wb")
unzip("CharityRegDownload.zip", exdir = "./")
# the file name changes when the register is updated so need to find the name
charity_filename <- str_subset(list.files(path = "data/"), "CharityExport")
charity_data <- read_csv(paste0("data/", charity_filename))

# Get postcode zip file
downloader::download("https://www.freemaptools.com/download/full-postcodes/ukpostcodes.zip", dest="data/postcode.zip", mode="wb")
unzip("postcode.zip", exdir = "./")
postcodes <- read_csv("data/ukpostcodes.csv") %>%
  mutate(clean_postcode = toupper(str_replace_all(postcode, " ", ""))) %>%
  select(longitude, latitude, clean_postcode)

# Get Scottish Authority geographical boundary data 
# this data is found at https://borders.ukdataservice.ac.uk/easy_download.html and its the 'Scottish Local Administrative Units Level 1 2011' file
downloader::download("https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/Scotland_laulevel1_2011.zip", dest="data/Scotland_laulevel1_2011.zip", mode="wb")
unzip("Scotland_laulevel1_2011.zip", exdir = "./")
boundary_data <- st_read("data/BoundaryData/scotland_laulevel1_2011.shp", quiet = TRUE)
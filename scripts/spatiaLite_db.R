# spatiaLite DB in R

# Fri Jun 23 13:48:38 2017 ------------------------------

# Following PISCES as an example:

# Load Packages -----------------------------------------------------------

suppressMessages({
	library(tidyverse);
	library(lubridate);
	library(RSQLite);
	library(magrittr);
	library(DBI);
	library(sf)
	library(dbplyr)
})

# Connecting to SpatiaLite DB with DPLYR ----------------------------------

# https://datascienceplus.com/working-with-databases-in-r/

# or just connect
rana_db <- src_sqlite("data_output/rana_sf.sqlite", create = F) 

# check list of table names
src_tbls(rana_db)

# check size of tables
map(src_tbls(rana_db), ~dim(dbReadTable(rana_db$con, .))) %>% 
	set_names(., src_tbls(rana_db))

# Connecting to SpatiaLite DB with SF -------------------------------------

db <- "~/Box\ Sync/GIS/pisces.sqlite"
dbcon <- dbConnect(dbDriver("SQLite"), db)
dbListTables(dbcon) # list all tables in DB

# to view fields within a table
dbListFields(dbcon, "lakes")

# to pull out tables non-spatial:
#rivs <- dbReadTable(dbcon, "major_rivers") # this makes table weird if spatial
cvas <- dbReadTable(dbcon, "cvas")

# to pull out from spatial 
rivs<-st_read(db, "major_rivers")

# disconnect
dbDisconnect(dbcon)

# CONNECTING AND ADDING TO RANA SF ----------------------------------------

rb <- "data_output/rana_sf.sqlite"
rbcon <- dbConnect(dbDriver("SQLite"), rb)
dbListTables(rbcon) # list all tables in DB

rivs <- st_read(rb, "major_rivers")

dbDisconnect(rbcon)


## ADD TO A DB OTHER DB
rb2 <- "data_output/rana_sf2.sqlite"

st_write(rivs, dsn = rb2, layer = 'maj_rivers', driver = 'SQLite')
dbListTables(dbConnect(dbDriver("SQLite"), rb2))

# Copy a Table from DPLYR sqlite connection;
rabo_db <- src_sqlite("data_output/rana_sf.sqlite", create = F)
dna_extract <- tbl(rabo_db, "dna_extract") %>% collect()

# make connection to new DB
rabo_db2 <- src_sqlite("data_output/rana_sf2.sqlite", create = F)

# copy
copy_to(rabo_db2, dna_extract, temporary = FALSE)

dbListTables(dbConnect(dbDriver("SQLite"), rb2))

# READ IN LAYERS ----------------------------------------------------------

# read layers in db:
h8<-st_read("data_output/rana_sf.sqlite", "HUC8FullState")
h8 <- st_transform(h8, crs=4326)
h8 <- h8 %>% 
	as("Spatial")

st_layers(fname)
rivs <- st_read(fname, "major_rivers")
rivs <- st_transform(rivs, crs = 4326) # transform to WGS84
head(rivs)

# Connecting and Plotting SQLITE ------------------------------------------

leaflet() %>%
	addTiles() %>% 
	addProviderTiles("Esri.WorldImagery", group = "ESRI Aerial") %>%
	addProviderTiles("Esri.WorldTopoMap", group = "Topo") %>%
	addCircleMarkers(data=rb, group="RABO", weight=1, 
									 color = "orange", opacity = 0.7, 
									 labelOptions= labelOptions(noHide = F,
									 													 style = list(
									 													 	"color" = "black",
									 													 	"font-family" = "serif",
									 													 	"font-style" = "italic",
									 													 	"box-shadow" = "3px 3px rgba(0,0,0,0.25)",
									 													 	"font-size" = "12px",
									 													 	"border-color" = "rgba(0,0,0,0.5)")),
									 label = paste0("FieldID: ", rb$Name,
									 							 "Description: ", rb$Description)) %>%
	addLayersControl(
		baseGroups = c("ESRI Aerial", "Topo"),
		overlayGroups = c("RABO"),
		options = layersControlOptions(collapsed = T))


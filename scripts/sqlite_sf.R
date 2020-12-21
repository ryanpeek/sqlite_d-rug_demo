# creating or linking to spatialite SQLite database:


# BACKGROUND A ------------------------------------------------------------

# check out this page:
## https://simonwillison.net/2017/Dec/12/location-time-zone-api/

## $ wget https://github.com/evansiroky/timezone-boundary-builder/releases/download/2017c/timezones.shapefile.zip
## $ unzip timezones.shapefile.zip
## $ cd dist
## $ spatialite timezones.db
## SpatiaLite version ..: 4.3.0a   Supported Extensions:
##	...
## Enter SQL statements terminated with a ";"
## spatialite> .loadshp combined_shapefile timezones CP1252 23032
## ==
## 	Loading shapefile at 'combined_shapefile' into SQLite table 'timezones'

## BEGIN;
## CREATE TABLE "timezones" (
## 	"PK_UID" INTEGER PRIMARY KEY AUTOINCREMENT,
## 	"tzid" TEXT);
## SELECT AddGeometryColumn('timezones', 'Geometry', 23032, 'MULTIPOLYGON', 'XY');
## COMMIT;

## Inserted 414 rows into 'timezones' from SHAPEFILE
## ==
## spatialite> 


# BACKGROUND B ------------------------------------------------------------

# library(sf)
# library(RSQLite)
# db <- "test-2.3.sqlite"
# dbcon <- dbConnect(dbDriver("SQLite"), db)
# dbListTables(dbcon)
# dbListFields(dbcon, "HighWays")
# hw = dbReadTable(dbcon, "HighWays")
# st_as_sfc(hw$Geometry, spatialite = TRUE)
# tn = dbReadTable(dbcon, "Towns")
# st_as_sfc(tn$Geometry, spatialite = TRUE)


# Libraries ---------------------------------------------------------------

suppressMessages({
	library(tidyverse);
	library(lubridate);
	library(RSQLite);
	library(magrittr);
	library(DBI);
	library(dbplyr);
	library(sf);
	library(foreign) # to read .dbf
})


# CREATE NEW SQLITE DB WITH SPATIALITE ------------------------------------

# in command line:
# spatialite data_output/rana_sf.sqlite


# add shps w spatialite ---------------------------------------------------

# .loadshp data/gis/HUC12_spider h12spider UTF-8

# Connect to DB: src_sqlite-----------------------------------------------------------

dplyr::src_sqlite('data_output/rana_sf.sqlite') 


# option A
rana_db <- src_sqlite("data_output/rana_sf.sqlite", create = F) 
src_tbls(rana_db) # see tables in DB

# connect to DB: dbConnect ------------------------------------------------

db <- "rana_sf.sqlite"
dbcon <- dbConnect(dbDriver("SQLite"), db)
dbListTables(dbcon)
dbListFields(dbcon, "HighWays")
hw = dbReadTable(dbcon, "HighWays")

# see table dim
#dim(dbReadTable(rana_db$con, "rb_range"))

# delete a table
#rana_db$con %>% db_drop_table(table='rb_range') # delete a table

# read in shps directly ---------------------------------------------------

# read in a few shapes:
rb_range <- st_read("data/gis/Rb_Potential_Range_CAandOR.shp") %>% 
	st_transform(crs = 4326) %>% st_as_sfc()

rb_2010 <- st_read("data/gis/Rboylii_All_Records_thru_2010_full_v4.shp") %>%
	st_transform(crs = 4326)

h12_spider <- st_read("data/gis/HUC12_spider.shp") %>% 
	st_transform(crs = 4326)

h12_spider_pts <- st_read("data/gis/HUC12_spider_pts.shp") %>% 
	st_transform(crs = 4326)

h8_simple <- st_read("data/gis/h8_OR_CA_simple.shp") %>% 
	st_transform(crs = 4326)

ca_dams <- st_read("data/gis/CA_dams.shp") %>% 
	st_transform(crs = 4326)

hw_condition <- read.dbf("data/gis/HUC_condition_1.dbf")
hw_climate <- read.dbf("data/gis/HUC_climate_1.dbf")
hw_variables <- read.dbf("data/gis/HUC_cond_clim_variables.dbf")

# write to sqlite ---------------------------------------------------------

# connect to db
db <- "data_output/rana_sf.sqlite"
dbcon <- dbConnect(dbDriver("SQLite"), db)
dbListTables(dbcon) # list all tables in DB

#st_write(h8_simple, dsn = db, layer = 'h8_OR_CA_simple', driver = 'SQLite', delete_layer = TRUE) # to overwite existing layer

#st_write(h12_spider, dsn = db, layer = 'h12_spider', driver = 'SQLite')
#st_write(h12_spider_pts, dsn = db, layer = 'h12_spider_pts', driver = 'SQLite')
#st_write(rb_range, dsn=db, layer='rabo_range', driver='SQLite', delete_layer = TRUE)
#st_write(rb_2010, dsn=db, layer='rabo_records_2010_v4', driver='SQLite')

st_write(ca_dams, dsn=db, layer='ca_dams', driver='SQLite', delete_layer=TRUE)

dbListTables(dbConnect(dbDriver("SQLite"), db))


# ADD a table -------------------------------------------------------------

# copy tables
copy_to(dbcon, hw_climate, temporary = FALSE)
copy_to(dbcon, hw_condition, temporary = FALSE)
copy_to(dbcon, hw_variables, temporary = FALSE)

dbListTables(dbConnect(dbDriver("SQLite"), db))



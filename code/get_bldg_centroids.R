# get_bldg_centroids.R
# LP 10/19/2020
# 
# Downloads Building footprints by state from https://github.com/microsoft/USBuildingFootprints
#  and optionally by county and tract. Does calculations and returns output in the projection 
#  provided.
# Produces shapefiles of building *centroids* in relevant state plane projections for each 
# study site. 
#
# Writes out individual files in state plane projection for QA, 
# as well as a single file in WGS84 for loading into model prediction process
#
# Modules to load in brain 
# R-4.0.2
# GDAL
# GEOS
# PROJ
# UDUNITS
library(utils)
library(sf)
library(tigris)
library(magrittr)
library(dplyr)
library(stringr)

read_remote_spatial <- function(url){
  temp <- tempfile()
  tdir <- tempdir()
  download.file(url, temp)
  datafile <- unzip(temp, exdir = tdir)
  state_bldgs <- read_sf(datafile)
  unlink(temp)
  unlink(tdir)
  state_bldgs
}

#' Title
#'
#' @param state_fip 
#' @param county_fip 
#' @param tract_fips 
#' @param year 
#'
#' @return an sf data frame
#'
#' @examples bronx <- get_building_centroids(
#'   state_fip = '36', 
#'   county_fip = '005', 
#'   tract_fips = NULL, 
#'   year = 2010, 
#'   url = 'https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewYork.zip'
#' )
get_building_centroids <- function(state_fip, county_fip = NULL, tract_fips = NULL, centroid = TRUE, version = 'v2'){
  # Get Census Tiger Files
  census.tracts <- tracts(state = state_fip, county = county_fip, cb = FALSE, year = 2010, class = 'sf') %>% st_transform(4326)

  # Get Building Footprints from Msft
  state_names <- unique(tigris::fips_codes[, c('state_code', 'state_name')])
  bldg_footprint_url <- paste0('https://usbuildingdata.blob.core.windows.net/usbuildings-v2/', state_names$state_name, '.geojson.zip')
  names(bldg_footprint_url) <- state_fips$state_code
  url <- bldg_footprint_url[[state_fip]]
  
  # Download the file for state
  bldgs <- read_remote_spatial(url)
  bldgs <- st_make_valid(bldgs)
  
  # Filter to counties or tracts
  bldgs.joined <- st_join(bldgs, census.tracts, st_intersects)
  if(!is.null(county_fip)){bldgs.joined <- bldgs.joined %>% filter(COUNTYFP10 == county_fip)}
  if(!is.null(tract_fips)){bldgs.joined <- bldgs.joined %>% filter(TRACTCE10 %in% tract_fips)}
  
  # Find centroid 
  st_agr(bldgs.joined) <- 'constant'
  bldg.centroids <- st_centroid(bldgs.joined, byid=TRUE)
  return(bldg.centroids)
}
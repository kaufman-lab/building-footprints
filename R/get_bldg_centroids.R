
#' Download Building Footprints from Microsoft
#'
#' @param state USPS state abbreviation
#' @param county_fips vector of 3 digit county FIPS codes to filter data by (optional)
#' @param centroid return centroids of buildings (default FALSE)
#' @param version version of data (1 or 2, default 2)
#'
#' @return an sf data frame of building footprints, plus county FIP and name if county_fips is specified
#' @export
#' @examples \dontrun{bronx_centroids <- get_buildings(
#'   state = 'NY',
#'   county_fips = '005',
#'   centroid = TRUE
#' )}
get_buildings <- function(state = unique(tigris::fips_codes$state), county_fips = NULL, centroid = FALSE, version = 2){
  state <- match.arg(state)
  stopifnot(is.logical(centroid) && length(centroid == 1))
  stopifnot(version %in% c(1,2))

  if(!is.null(county_fips)){
    # Check counties are valid
    county_fips <- stringr::str_pad(county_fips, 3, pad = '0')
    matching_counties <- tigris::fips_codes %>% dplyr::filter(state == .env$state) %>% dplyr::filter(county_code %in% county_fips)
    if(nrow(matching_counties) == 0){
      stop(glue::glue(
        "Counties ({stringr::str_flatten(county_fips, collapse = ', ')}) not found in {state}.
      Refer to tigris::fips_codes or https://www.census.gov/library/reference/code-lists/ansi.html#county for valid options."
      ))
    }
    # Pull county sfs from tigris
    county <- suppressMessages(tigris::counties(state, year = 2020, progress_bar = FALSE)) %>%
      dplyr::select(county_fips = GEOID, county_name = NAME) %>%
      sf::st_transform(4326)
  }

  # Get Building Footprints from Msft
  url <- get_building_download_url(state, version)
  bldgs <- st_read_remote(url, quiet = TRUE)
  bldgs <- sf::st_make_valid(bldgs)
  invalid <- which(!sf::st_is_valid(bldgs))
  if(length(invalid) > 0){
    warning(glue::glue("{length(invalid)} buildings had invalid geometry and were removed from the output data set"))
    bldgs <- bldgs[-invalid, ]
  }

  # Filter to counties or tracts if needed
  if(!is.null(county_fips)){
    bldgs <- sf::st_join(bldgs, county, sf::st_intersects) %>%
      dplyr::filter(substr(county_fips, 3, 5) %in% .env$county_fips)
  }

  # Find centroid if needed
  if(isTRUE(centroid)){
    sf::st_agr(bldgs) <- 'constant'
    bldgs <- sf::st_centroid(bldgs, byid = TRUE)
  }

  bldgs
}

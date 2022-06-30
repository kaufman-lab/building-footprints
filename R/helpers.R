#' Get download URL for a state
#'
#' @param state USPS abbreviation
#' @param version 1 or 2
#' @return url
#'
#' @export
get_building_download_url <- function(state = unique(tigris::fips_codes$state), version){
  state <- match.arg(state)
  stopifnot(version %in% c(1,2))
  base <- dplyr::case_when(
    version == 1L ~ 'https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/',
    version == 2L ~ 'https://usbuildingdata.blob.core.windows.net/usbuildings-v2/',
    TRUE ~ NA_character_
  )
  ext <- dplyr::case_when(
    version == 1L ~ '.zip',
    version == 2L ~ '.geojson.zip',
    TRUE ~ NA_character_
  )
  state <- stringr::str_replace_all(tigris::fips_codes[tigris::fips_codes$state == state, 'state_name'][1], ' ', '')
  glue::glue('{base}{state}{ext}')
}

#' Use sf::st_read on a remote, compressed file
#'
#' @param url url of file
#' @param compressed is file compressed?
#' @param ... params to be passed to sf::st_read
#' @return output of sf::st_read
#'
#' @export
st_read_remote <- function(url, compressed = TRUE, ...){
  temp <- tempfile()
  tdir <- tempdir()
  download.file(url, temp)
  if(compressed){ datafile <- unzip(temp, exdir = tdir) }else{ datafile <- temp }
  out <- sf::st_read(datafile, ...)
  unlink(temp)
  unlink(tdir)
  out
}


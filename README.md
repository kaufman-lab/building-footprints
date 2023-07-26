
<!-- README.md is generated from README.Rmd. Please edit that file -->

# msftBuildingFootprints

## Installation

You can install this from [GitHub](https://github.com/) with:

``` r
install.packages("devtools") # if needed
devtools::install_github("kaufman-lab/msftBuildingFootprints")
```

Downloads building footprints from the open [Microsoft Maps data
set](https://github.com/Microsoft/USBuildingFootprints) and returns it
as an [sf](https://r-spatial.github.io/sf/) data frame.

The primary package function is `get_buildings`, which handles:

-   Downloading and unzipping data from Microsoft
-   Loading it into R as an `sf` data frame.
-   Optionally filtering it by county
-   Optionally converting building footprints to centroids

Note that Microsoft distributes the data as whole states, which must be
loaded in whole into memory even if the user chooses only a subset of
counties. California, the largest file, weighs in at 3.35 GB compressed.
Therefore running this package for large states can have significant
hardware demands.

## Example

Mapping building centroids in Lamoille County, Vermont.

``` r
library(msftBuildingFootprints)
library(sf)
bldgs <- get_buildings("VT", county_fips = '015', centroid = TRUE)
plot(st_geometry(bldgs))
```

<img src="man/figures/README-example-1.svg" width="100%" />

#' @title Project Geographic Coordinates to Metric (km)
#' @description
#' Converts WGS84 lon/lat coordinates to planar metric coordinates
#' in kilometres using the ETRS89 Lambert Azimuthal Equal-Area
#' projection (EPSG:3035). The original lon/lat columns are
#' retained alongside the projected `coord_x_km` and
#' `coord_y_km` columns.
#' @param data_coords
#' A data frame with `dataset_name` as row names and columns
#' `coord_long` and `coord_lat` (decimal degrees, WGS84), as
#' returned by `get_coords()`.
#' @return
#' A data frame with the same row names and columns as
#' `data_coords`, plus two additional columns:
#' \describe{
#'   \item{`coord_x_km`}{Easting in kilometres (EPSG:3035).}
#'   \item{`coord_y_km`}{Northing in kilometres (EPSG:3035).}
#' }
#' @details
#' The EPSG:3035 projection (ETRS89-LAEA) is the standard
#' equal-area projection for European spatial analyses. Using
#' metric coordinates instead of degrees is necessary for
#' distance-based spatial modelling (e.g., Moran eigenvectors)
#' because degree distances are not uniform across latitudes.
#'
#' The function requires the \pkg{sf} package to perform
#' coordinate transformation. Dataset names (row names) are
#' preserved unchanged in the output.
#' @seealso [get_coords()], [prepare_spatial_predictors_for_fit()]
#' @export
project_coords_to_metric <- function(data_coords = NULL) {
  assertthat::assert_that(
    is.data.frame(data_coords),
    msg = "data_coords must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("coord_long", "coord_lat") %in% names(data_coords)
    ),
    msg = paste0(
      "data_coords must contain columns",
      " 'coord_long' and 'coord_lat'"
    )
  )

  assertthat::assert_that(
    nrow(data_coords) > 0,
    msg = "data_coords must have at least one row"
  )

  # Convert to sf, transform to EPSG:3035, extract XY in metres

  vec_dataset_names <-
    rownames(data_coords)

  xy_m <-
    data_coords |>
    tibble::rownames_to_column("dataset_name") |>
    sf::st_as_sf(
      coords = c("coord_long", "coord_lat"),
      crs = 4326
    ) |>
    sf::st_transform(crs = 3035) |>
    sf::st_coordinates()

  res <-
    data_coords |>
    dplyr::mutate(
      coord_x_km = xy_m[, "X"] / 1000,
      coord_y_km = xy_m[, "Y"] / 1000
    )

  rownames(res) <- vec_dataset_names

  return(res)
}

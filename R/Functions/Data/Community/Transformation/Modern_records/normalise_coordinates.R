#' @title Normalise Coordinates
#' @description
#' Converts a coordinate table to a standard tibble with explicit dataset
#' names and coordinate columns.
#' @param data_coordinates
#' A data frame with `coord_long` and `coord_lat` columns. Dataset names may
#' be stored either in a `dataset_name` column or in row names.
#' @return
#' A tibble with `dataset_name`, `coord_long`, and `coord_lat` columns.
#' @export
normalise_coordinates <- function(data_coordinates = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_coordinates),
    msg = "data_coordinates must be a data frame."
  )

  if (
    "dataset_name" %in% base::names(data_coordinates)
  ) {
    data_coordinates_normalised <-
      tibble::as_tibble(data_coordinates)
  } else {
    data_coordinates_normalised <-
      data_coordinates |>
      tibble::rownames_to_column("dataset_name") |>
      tibble::as_tibble()
  }

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "coord_long", "coord_lat") %in%
        base::names(data_coordinates_normalised)
    ),
    msg = stringr::str_c(
      "data_coordinates must contain dataset names and columns ",
      "'coord_long' and 'coord_lat'."
    )
  )

  res_coordinates_normalised <-
    data_coordinates_normalised |>
    dplyr::select(dataset_name, coord_long, coord_lat)

  return(res_coordinates_normalised)
}

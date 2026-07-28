#' @title Normalize Coordinates
#' @description
#' Converts a coordinate table to a standard tibble with explicit dataset
#' names and coordinate columns.
#' @param data_source
#' A data frame with `coord_long` and `coord_lat` columns. Dataset names may
#' be stored either in a `dataset_name` column or in row names.
#' @return
#' A tibble with `dataset_name`, `coord_long`, and `coord_lat` columns.
#' @export
normalize_coordinates <- function(data_source = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame."
  )

  if (
    "dataset_name" %in% base::names(data_source)
  ) {
    data_coordinates <-
      tibble::as_tibble(data_source)
  } else {
    data_coordinates <-
      data_source |>
      tibble::rownames_to_column("dataset_name") |>
      tibble::as_tibble()
  }

  assertthat::assert_that(
    base::all(
      c("dataset_name", "coord_long", "coord_lat") %in%
        base::names(data_coordinates)
    ),
    msg = stringr::str_c(
      "data_source must contain dataset names and columns ",
      "'coord_long' and 'coord_lat'."
    )
  )

  res <-
    data_coordinates |>
    dplyr::select(dataset_name, coord_long, coord_lat)

  return(res)
}

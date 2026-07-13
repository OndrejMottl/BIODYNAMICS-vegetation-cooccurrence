#' @title Make Cross-Validation Location Table
#' @description
#' Collapses aligned model samples to unique sampling locations for
#' location-level cross-validation. Complete paleo cores and modern plots are
#' represented by one row each.
#' @param data_sample_ids
#' Data frame with one row per aligned model sample and a location identifier
#' column named by `location_column`.
#' @param data_coords_projected
#' Data frame with one row per sampling location, location identifiers in row
#' names, and finite `coord_x_km` and `coord_y_km` columns.
#' @param location_column
#' Character scalar naming the location identifier column in
#' `data_sample_ids`. Defaults to `"dataset_name"`.
#' @return
#' Tibble with one row per sampled location and columns `location_id`,
#' `coord_x_km`, `coord_y_km`, `n_samples`, and `row_indices`. `row_indices` is
#' a list-column of integer row positions in `data_sample_ids`.
#' @details
#' Locations follow their first appearance in `data_sample_ids`. Every sampled
#' location must have exactly one projected coordinate row. Coordinate rows
#' without aligned samples are omitted.
#' @examples
#' data_sample_ids <-
#'   tibble::tibble(dataset_name = c("core_a", "core_a", "core_b"))
#' data_coords_projected <-
#'   data.frame(
#'     coord_x_km = c(10, 20),
#'     coord_y_km = c(30, 40),
#'     row.names = c("core_a", "core_b")
#'   )
#' make_cross_validation_location_table(
#'   data_sample_ids = data_sample_ids,
#'   data_coords_projected = data_coords_projected
#' )
#' @export
make_cross_validation_location_table <- function(
    data_sample_ids = NULL,
    data_coords_projected = NULL,
    location_column = "dataset_name") {
  assertthat::assert_that(
    base::is.data.frame(data_sample_ids),
    msg = "`data_sample_ids` must be a data frame."
  )

  assertthat::assert_that(
    base::nrow(data_sample_ids) > 0L,
    msg = "`data_sample_ids` must contain at least one row."
  )

  assertthat::assert_that(
    base::is.data.frame(data_coords_projected),
    msg = "`data_coords_projected` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(location_column),
    base::length(location_column) == 1L,
    !base::is.na(location_column),
    base::nzchar(location_column),
    location_column %in% base::colnames(data_sample_ids),
    msg = stringr::str_c(
      "`location_column` must name one column in",
      " ",
      "`data_sample_ids`."
    )
  )

  assertthat::assert_that(
    base::all(
      base::c("coord_x_km", "coord_y_km") %in%
        base::colnames(data_coords_projected)
    ),
    msg = stringr::str_c(
      "`data_coords_projected` must contain `coord_x_km` and",
      " ",
      "`coord_y_km`."
    )
  )

  assertthat::assert_that(
    base::is.numeric(data_coords_projected[["coord_x_km"]]),
    base::is.numeric(data_coords_projected[["coord_y_km"]]),
    msg = "Projected coordinate columns must be numeric."
  )

  vec_location_ids <-
    data_sample_ids |>
    dplyr::pull(dplyr::all_of(location_column)) |>
    base::as.character()

  assertthat::assert_that(
    !base::any(base::is.na(vec_location_ids)),
    base::all(base::nzchar(vec_location_ids)),
    msg = "Sample location identifiers must be non-missing strings."
  )

  vec_unique_location_ids <-
    vec_location_ids[!base::duplicated(vec_location_ids)]

  vec_coordinate_location_ids <-
    base::rownames(data_coords_projected)

  assertthat::assert_that(
    !base::is.null(vec_coordinate_location_ids),
    base::length(vec_coordinate_location_ids) ==
      base::nrow(data_coords_projected),
    !base::any(base::is.na(vec_coordinate_location_ids)),
    base::all(base::nzchar(vec_coordinate_location_ids)),
    !base::any(base::duplicated(vec_coordinate_location_ids)),
    msg = stringr::str_c(
      "`data_coords_projected` row names must uniquely identify",
      " ",
      "sampling locations."
    )
  )

  vec_coordinate_indices <-
    base::match(
      x = vec_unique_location_ids,
      table = vec_coordinate_location_ids
    )

  if (
    base::any(base::is.na(vec_coordinate_indices))
  ) {
    cli::cli_abort(
      stringr::str_c(
        "Every sampled location must have exactly one projected",
        " ",
        "coordinate row."
      )
    )
  }

  data_coordinates_selected <-
    data_coords_projected[
      vec_coordinate_indices,
      base::c("coord_x_km", "coord_y_km"),
      drop = FALSE
    ]

  if (
    !base::all(
      base::is.finite(base::as.matrix(data_coordinates_selected))
    )
  ) {
    cli::cli_abort(
      "Every sampled location must have finite projected coordinates."
    )
  }

  list_row_indices <-
    vec_unique_location_ids |>
    purrr::map(
      .f = ~ base::as.integer(base::which(vec_location_ids == .x))
    )

  res <-
    tibble::tibble(
      location_id = vec_unique_location_ids,
      coord_x_km = data_coordinates_selected[["coord_x_km"]],
      coord_y_km = data_coordinates_selected[["coord_y_km"]],
      n_samples = purrr::map_int(list_row_indices, base::length),
      row_indices = list_row_indices
    )

  return(res)
}

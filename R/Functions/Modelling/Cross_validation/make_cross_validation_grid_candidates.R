#' @title Make Cross-Validation Grid Candidates
#' @description
#' Derives candidate spatial-grid widths from projected extent, location
#' density, and a target number of locations per occupied cell.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()] with
#' finite `coord_x_km` and `coord_y_km` columns.
#' @param target_locations_per_cell
#' Single positive numeric target occupancy. Defaults to `5`.
#' @param grid_size_multipliers
#' Numeric vector of unique positive multipliers applied to the density-derived
#' baseline width. Defaults to `2 ^ seq(-2, 2)`.
#' @return
#' Tibble with one row per candidate and columns describing candidate ID, cell
#' width, baseline width, multiplier, location count, projected extents, area,
#' and target occupancy.
#' @details
#' The baseline width is the square root of projected bounding-box area divided
#' by the expected occupied-cell count, where expected cells equal location
#' count divided by target occupancy. Candidate widths therefore adapt to each
#' spatial ID rather than using fixed kilometre widths by tier.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     coord_x_km = c(0, 0, 10, 10),
#'     coord_y_km = c(0, 10, 0, 10)
#'   )
#' make_cross_validation_grid_candidates(
#'   data_locations = data_locations,
#'   target_locations_per_cell = 1,
#'   grid_size_multipliers = c(0.5, 1, 2)
#' )
#' @export
make_cross_validation_grid_candidates <- function(
    data_locations = NULL,
    target_locations_per_cell = 5,
    grid_size_multipliers = 2 ^ base::seq(-2, 2)) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) >= 2L,
    msg = "`data_locations` must contain at least two rows."
  )

  assertthat::assert_that(
    base::all(
      base::c("coord_x_km", "coord_y_km") %in%
        base::colnames(data_locations)
    ),
    msg = "`data_locations` must contain projected coordinate columns."
  )

  flag_valid_target <-
    base::is.numeric(target_locations_per_cell) &&
    base::length(target_locations_per_cell) == 1L &&
    base::is.finite(target_locations_per_cell) &&
    target_locations_per_cell > 0

  assertthat::assert_that(
    flag_valid_target,
    msg = "`target_locations_per_cell` must be a positive number."
  )

  assertthat::assert_that(
    base::is.numeric(grid_size_multipliers),
    base::length(grid_size_multipliers) > 0L,
    base::all(base::is.finite(grid_size_multipliers)),
    base::all(grid_size_multipliers > 0),
    !base::any(base::duplicated(grid_size_multipliers)),
    msg = stringr::str_c(
      "`grid_size_multipliers` must contain unique positive finite",
      " ",
      "numbers."
    )
  )

  vec_coord_x <-
    data_locations |>
    dplyr::pull("coord_x_km")

  vec_coord_y <-
    data_locations |>
    dplyr::pull("coord_y_km")

  assertthat::assert_that(
    base::is.numeric(vec_coord_x),
    base::is.numeric(vec_coord_y),
    base::all(base::is.finite(vec_coord_x)),
    base::all(base::is.finite(vec_coord_y)),
    msg = "Projected coordinates must contain finite numeric values."
  )

  extent_x_km <-
    base::max(vec_coord_x) - base::min(vec_coord_x)

  extent_y_km <-
    base::max(vec_coord_y) - base::min(vec_coord_y)

  if (
    extent_x_km <= 0 || extent_y_km <= 0
  ) {
    cli::cli_abort(
      "Projected coordinates must span a positive extent on both axes."
    )
  }

  n_locations <-
    base::nrow(data_locations)

  extent_area_km2 <-
    extent_x_km * extent_y_km

  expected_occupied_cells <-
    n_locations / target_locations_per_cell

  baseline_grid_cell_size_km <-
    base::sqrt(extent_area_km2 / expected_occupied_cells)

  vec_grid_size_multipliers <-
    grid_size_multipliers |>
    base::as.numeric() |>
    base::sort()

  vec_grid_cell_sizes_km <-
    baseline_grid_cell_size_km * vec_grid_size_multipliers

  res <-
    tibble::tibble(
      candidate_id = stringr::str_c(
        "grid_",
        stringr::str_pad(
          base::seq_along(vec_grid_cell_sizes_km),
          width = 3L,
          pad = "0"
        )
      ),
      grid_cell_size_km = vec_grid_cell_sizes_km,
      baseline_grid_cell_size_km = baseline_grid_cell_size_km,
      grid_size_multiplier = vec_grid_size_multipliers,
      n_locations = n_locations,
      extent_x_km = extent_x_km,
      extent_y_km = extent_y_km,
      extent_area_km2 = extent_area_km2,
      target_locations_per_cell = target_locations_per_cell
    )

  return(res)
}

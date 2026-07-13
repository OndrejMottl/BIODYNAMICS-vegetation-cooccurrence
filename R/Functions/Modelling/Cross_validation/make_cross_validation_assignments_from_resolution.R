#' @title Make Cross-Validation Assignments From Fold Resolution
#' @description
#' Dispatches a resolved cross-validation strategy to spatially stratified or
#' leave-one-location-out assignment while preserving one assignment schema.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param data_fold_resolution
#' One-row table returned by [resolve_cross_validation_fold_count()].
#' @param data_grid_calibration
#' Table returned by [calibrate_cross_validation_grid_from_resolution()].
#' @param n_repeats
#' Positive integer number of deterministic spatial assignment repeats.
#' @param seed
#' Non-negative integer assignment seed.
#' @param assignment_source
#' Non-empty character scalar recording assignment provenance.
#' @return
#' Tibble with the shared assignment columns plus `cv_strategy` and
#' `assignment_source`. A no-holdout resolution returns a zero-row tibble with
#' the same schema.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = base::letters[1:6],
#'     coord_x_km = base::seq_len(6L),
#'     coord_y_km = base::seq_len(6L),
#'     n_samples = base::rep(1L, 6L),
#'     row_indices = base::as.list(base::seq_len(6L))
#'   )
#' data_resolution <-
#'   resolve_cross_validation_fold_count(6L, 5L)
#' make_cross_validation_assignments_from_resolution(
#'   data_locations = data_locations,
#'   data_fold_resolution = data_resolution,
#'   data_grid_calibration = tibble::tibble()
#' )
#' @export
make_cross_validation_assignments_from_resolution <- function(
    data_locations = NULL,
    data_fold_resolution = NULL,
    data_grid_calibration = NULL,
    n_repeats = 1L,
    seed = 900723L,
    assignment_source = "per_id") {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_fold_resolution),
    base::nrow(data_fold_resolution) == 1L,
    msg = "`data_fold_resolution` must contain exactly one row."
  )

  vec_required_resolution_columns <-
    base::c("cv_strategy", "effective_folds")

  assertthat::assert_that(
    base::all(
      vec_required_resolution_columns %in%
        base::colnames(data_fold_resolution)
    ),
    msg = "`data_fold_resolution` is missing required columns."
  )

  assertthat::assert_that(
    base::is.data.frame(data_grid_calibration),
    msg = "`data_grid_calibration` must be a data frame."
  )

  flag_valid_assignment_source <-
    base::is.character(assignment_source) &&
    base::length(assignment_source) == 1L &&
    !base::is.na(assignment_source) &&
    base::nzchar(assignment_source)

  assertthat::assert_that(
    flag_valid_assignment_source,
    msg = "`assignment_source` must be a non-empty string."
  )

  cv_strategy_value <-
    data_fold_resolution |>
    dplyr::pull("cv_strategy")

  vec_supported_strategies <-
    base::c(
      "spatially_stratified_group_kfold",
      "leave_one_location_out",
      "none"
    )

  assertthat::assert_that(
    base::is.character(cv_strategy_value),
    base::length(cv_strategy_value) == 1L,
    cv_strategy_value %in% vec_supported_strategies,
    msg = "The resolved `cv_strategy` is not supported."
  )

  data_empty_assignments <-
    tibble::tibble(
      repeat_id = base::integer(),
      fold_id = base::integer(),
      location_id = base::character(),
      grid_cell_id = base::character(),
      n_samples = base::integer(),
      row_indices = base::list(),
      cv_strategy = base::character(),
      assignment_source = base::character()
    )

  if (
    cv_strategy_value == "none"
  ) {
    return(data_empty_assignments)
  }

  data_assignments_resolved <-
    if (
      cv_strategy_value == "leave_one_location_out"
    ) {
      make_leave_one_location_out_assignments(
        data_locations = data_locations
      )
    } else {
      assertthat::assert_that(
        base::all(
          base::c("grid_cell_size_km", "selected") %in%
            base::colnames(data_grid_calibration)
        ),
        msg = "`data_grid_calibration` is missing required columns."
      )

      vec_selected_grid_sizes <-
        data_grid_calibration |>
        dplyr::filter(.data[["selected"]]) |>
        dplyr::pull("grid_cell_size_km")

      assertthat::assert_that(
        base::length(vec_selected_grid_sizes) == 1L,
        msg = "Grouped CV requires exactly one selected grid size."
      )

      effective_folds_value <-
        data_fold_resolution |>
        dplyr::pull("effective_folds")

      make_spatial_cross_validation_assignments(
        data_locations = data_locations,
        n_folds = effective_folds_value,
        n_repeats = n_repeats,
        grid_cell_size_km = vec_selected_grid_sizes[[1L]],
        seed = seed
      )
    }

  res <-
    data_assignments_resolved |>
    dplyr::mutate(
      cv_strategy = cv_strategy_value,
      assignment_source = assignment_source
    )

  return(res)
}

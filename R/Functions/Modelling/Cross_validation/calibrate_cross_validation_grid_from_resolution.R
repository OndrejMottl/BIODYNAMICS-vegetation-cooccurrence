#' @title Calibrate Cross-Validation Grid From Fold Resolution
#' @description
#' Runs spatial-grid calibration only when the resolved cross-validation
#' strategy uses spatially stratified grouped folds.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param data_fold_resolution
#' One-row table returned by [resolve_cross_validation_fold_count()].
#' @param candidate_grid_cell_sizes_km
#' Numeric vector of candidate grid-cell widths in kilometres.
#' @param n_repeats
#' Positive integer number of deterministic assignment repeats.
#' @param occupancy_criterion,target_locations_per_cell,
#' lower_quantile_probability,max_fold_location_difference,
#' max_fold_sample_difference,seed
#' Arguments passed to [calibrate_cross_validation_grid_size()].
#' @return
#' Grid-calibration tibble. Leave-one-location-out and no-holdout strategies
#' return a zero-row tibble with the stable calibration schema.
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
#' calibrate_cross_validation_grid_from_resolution(
#'   data_locations = data_locations,
#'   data_fold_resolution = data_resolution,
#'   candidate_grid_cell_sizes_km = c(1, 10)
#' )
#' @export
calibrate_cross_validation_grid_from_resolution <- function(
    data_locations = NULL,
    data_fold_resolution = NULL,
    candidate_grid_cell_sizes_km = NULL,
    n_repeats = 1L,
    occupancy_criterion = "median",
    target_locations_per_cell = NULL,
    lower_quantile_probability = 0.25,
    max_fold_location_difference = 1L,
    max_fold_sample_difference = Inf,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_resolution),
    base::nrow(data_fold_resolution) == 1L,
    msg = "`data_fold_resolution` must contain exactly one row."
  )

  vec_required_columns <-
    base::c("cv_strategy", "effective_folds")

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_fold_resolution)
    ),
    msg = "`data_fold_resolution` is missing required columns."
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

  data_empty_calibration <-
    tibble::tibble(
      grid_cell_size_km = base::numeric(),
      mean_occupied_cells = base::numeric(),
      minimum_locations_per_cell = base::numeric(),
      lower_quantile_locations_per_cell = base::numeric(),
      median_locations_per_cell = base::numeric(),
      occupancy_criterion = base::character(),
      occupancy_value = base::numeric(),
      target_locations_per_cell = base::numeric(),
      maximum_fold_location_difference = base::numeric(),
      maximum_fold_sample_difference = base::numeric(),
      eligible = base::logical(),
      selected = base::logical(),
      selection_status = base::character()
    )

  if (
    cv_strategy_value != "spatially_stratified_group_kfold"
  ) {
    return(data_empty_calibration)
  }

  effective_folds_value <-
    data_fold_resolution |>
    dplyr::pull("effective_folds")

  res <-
    calibrate_cross_validation_grid_size(
      data_locations = data_locations,
      candidate_grid_cell_sizes_km = candidate_grid_cell_sizes_km,
      n_folds = effective_folds_value,
      n_repeats = n_repeats,
      occupancy_criterion = occupancy_criterion,
      target_locations_per_cell = target_locations_per_cell,
      lower_quantile_probability = lower_quantile_probability,
      max_fold_location_difference = max_fold_location_difference,
      max_fold_sample_difference = max_fold_sample_difference,
      seed = seed
    )

  return(res)
}

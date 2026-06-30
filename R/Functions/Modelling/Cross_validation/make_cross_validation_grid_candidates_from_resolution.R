#' @title Make Cross-Validation Grid Candidates From Fold Resolution
#' @description
#' Derives spatial-grid candidates only for spatially stratified grouped
#' cross-validation.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param data_fold_resolution
#' One-row table returned by [resolve_cross_validation_fold_count()].
#' @param target_locations_per_cell,grid_size_multipliers
#' Arguments passed to [make_cross_validation_grid_candidates()].
#' @return
#' Grid-candidate tibble. Gridless strategies return a zero-row tibble with
#' the stable candidate schema.
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
#' make_cross_validation_grid_candidates_from_resolution(
#'   data_locations = data_locations,
#'   data_fold_resolution = data_resolution
#' )
#' @export
make_cross_validation_grid_candidates_from_resolution <- function(
    data_locations = NULL,
    data_fold_resolution = NULL,
    target_locations_per_cell = 5,
    grid_size_multipliers = 2 ^ base::seq(-2, 2)) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_resolution),
    base::nrow(data_fold_resolution) == 1L,
    "cv_strategy" %in% base::colnames(data_fold_resolution),
    msg = stringr::str_c(
      "`data_fold_resolution` must contain one row and a",
      " ",
      "`cv_strategy` column."
    )
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

  data_empty_candidates <-
    tibble::tibble(
      candidate_id = base::character(),
      grid_cell_size_km = base::numeric(),
      baseline_grid_cell_size_km = base::numeric(),
      grid_size_multiplier = base::numeric(),
      n_locations = base::integer(),
      extent_x_km = base::numeric(),
      extent_y_km = base::numeric(),
      extent_area_km2 = base::numeric(),
      target_locations_per_cell = base::numeric()
    )

  if (
    cv_strategy_value != "spatially_stratified_group_kfold"
  ) {
    return(data_empty_candidates)
  }

  res <-
    make_cross_validation_grid_candidates(
      data_locations = data_locations,
      target_locations_per_cell = target_locations_per_cell,
      grid_size_multipliers = grid_size_multipliers
    )

  return(res)
}

#' @title Make Cross-Validation Branch Assignments
#' @description
#' Reuses a shared pre-resolution assignment for a response-resolution branch
#' when coverage and balance remain valid, otherwise recalibrates that branch.
#' @param data_locations
#' Branch location table returned by
#' [make_cross_validation_location_table()].
#' @param data_fold_resolution
#' One-row branch table returned by [resolve_cross_validation_fold_count()].
#' @param data_shared_assignments
#' Assignment table built from the shared pre-resolution sample universe.
#' @param target_locations_per_cell,grid_size_multipliers,n_repeats,
#' occupancy_criterion,lower_quantile_probability,
#' max_fold_location_difference,max_fold_sample_difference,seed
#' Grid-calibration and assignment controls used only when branch fallback is
#' required.
#' @return
#' Assignment tibble with the stable assignment schema. `assignment_source`
#' is `"shared_pre_resolution"`, `"branch_fallback"`, or
#' `"branch_no_holdout"`.
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
#' data_shared <-
#'   make_leave_one_location_out_assignments(data_locations)
#' make_cross_validation_branch_assignments(
#'   data_locations = data_locations,
#'   data_fold_resolution = data_resolution,
#'   data_shared_assignments = data_shared
#' )
#' @export
make_cross_validation_branch_assignments <- function(
    data_locations = NULL,
    data_fold_resolution = NULL,
    data_shared_assignments = NULL,
    target_locations_per_cell = 5,
    grid_size_multipliers = 2 ^ base::seq(-2, 2),
    n_repeats = 1L,
    occupancy_criterion = "median",
    lower_quantile_probability = 0.25,
    max_fold_location_difference = 1L,
    max_fold_sample_difference = Inf,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  vec_required_location_columns <-
    base::c(
      "location_id",
      "coord_x_km",
      "coord_y_km",
      "n_samples",
      "row_indices"
    )

  assertthat::assert_that(
    base::all(
      vec_required_location_columns %in% base::colnames(data_locations)
    ),
    msg = "`data_locations` is missing required columns."
  )

  assertthat::assert_that(
    base::is.data.frame(data_fold_resolution),
    base::nrow(data_fold_resolution) == 1L,
    base::all(
      base::c("cv_strategy", "effective_folds") %in%
        base::colnames(data_fold_resolution)
    ),
    msg = "`data_fold_resolution` must contain one resolved strategy."
  )

  cv_strategy_value <-
    data_fold_resolution |>
    dplyr::pull("cv_strategy")

  if (
    cv_strategy_value == "none"
  ) {
    res_no_holdout <-
      make_cross_validation_assignments_from_resolution(
        data_locations = data_locations,
        data_fold_resolution = data_fold_resolution,
        data_grid_calibration = tibble::tibble(),
        assignment_source = "branch_no_holdout"
      )

    return(res_no_holdout)
  }

  assertthat::assert_that(
    base::is.data.frame(data_shared_assignments),
    msg = "`data_shared_assignments` must be a data frame."
  )

  vec_required_assignment_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "location_id",
      "grid_cell_id"
    )

  flag_shared_schema_valid <-
    base::all(
      vec_required_assignment_columns %in%
        base::colnames(data_shared_assignments)
    )

  vec_branch_location_ids <-
    data_locations |>
    dplyr::pull("location_id") |>
    base::as.character()

  data_branch_location_values <-
    data_locations |>
    dplyr::select("location_id", "n_samples", "row_indices")

  data_shared_subset <-
    if (
      flag_shared_schema_valid
    ) {
      data_shared_assignments |>
        dplyr::filter(
          .data[["location_id"]] %in% vec_branch_location_ids
        ) |>
        dplyr::select(
          "repeat_id",
          "fold_id",
          "location_id",
          "grid_cell_id"
        ) |>
        dplyr::left_join(
          data_branch_location_values,
          by = "location_id"
        )
    } else {
      tibble::tibble()
    }

  flag_shared_has_rows <-
    base::nrow(data_shared_subset) > 0L

  shared_strategy_value <-
    if (
      flag_shared_has_rows &&
        base::all(base::is.na(data_shared_subset[["grid_cell_id"]]))
    ) {
      "leave_one_location_out"
    } else if (
      flag_shared_has_rows
    ) {
      "spatially_stratified_group_kfold"
    } else {
      "none"
    }

  effective_folds_value <-
    data_fold_resolution |>
    dplyr::pull("effective_folds")

  data_shared_repeat_checks <-
    data_shared_subset |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      n_locations = dplyr::n_distinct(.data[["location_id"]]),
      n_folds = dplyr::n_distinct(.data[["fold_id"]]),
      maximum_location_repetitions = base::max(
        base::tabulate(base::match(
          .data[["location_id"]],
          base::unique(.data[["location_id"]])
        ))
      ),
      .groups = "drop"
    )

  data_shared_balance_checks <-
    data_shared_subset |>
    dplyr::group_by(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::summarise(
      n_locations = dplyr::n(),
      n_samples = base::sum(.data[["n_samples"]]),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      fold_location_difference =
        base::max(.data[["n_locations"]]) -
        base::min(.data[["n_locations"]]),
      fold_sample_difference =
        base::max(.data[["n_samples"]]) -
        base::min(.data[["n_samples"]]),
      .groups = "drop"
    )

  flag_shared_reusable <-
    flag_shared_has_rows &&
    shared_strategy_value == cv_strategy_value &&
    base::nrow(data_shared_repeat_checks) > 0L &&
    base::all(
      data_shared_repeat_checks[["n_rows"]] ==
        base::length(vec_branch_location_ids)
    ) &&
    base::all(
      data_shared_repeat_checks[["n_locations"]] ==
        base::length(vec_branch_location_ids)
    ) &&
    base::all(
      data_shared_repeat_checks[["n_folds"]] == effective_folds_value
    ) &&
    base::all(
      data_shared_repeat_checks[["maximum_location_repetitions"]] == 1L
    ) &&
    base::all(
      data_shared_balance_checks[["fold_location_difference"]] <=
        max_fold_location_difference
    ) &&
    base::all(
      data_shared_balance_checks[["fold_sample_difference"]] <=
        max_fold_sample_difference
    )

  if (
    flag_shared_reusable
  ) {
    res_shared <-
      data_shared_subset |>
      dplyr::mutate(
        cv_strategy = cv_strategy_value,
        assignment_source = "shared_pre_resolution"
      )

    return(res_shared)
  }

  data_branch_grid_candidates <-
    make_cross_validation_grid_candidates_from_resolution(
      data_locations = data_locations,
      data_fold_resolution = data_fold_resolution,
      target_locations_per_cell = target_locations_per_cell,
      grid_size_multipliers = grid_size_multipliers
    )

  data_branch_grid_calibration <-
    calibrate_cross_validation_grid_from_resolution(
      data_locations = data_locations,
      data_fold_resolution = data_fold_resolution,
      candidate_grid_cell_sizes_km = dplyr::pull(
        data_branch_grid_candidates,
        "grid_cell_size_km"
      ),
      n_repeats = n_repeats,
      occupancy_criterion = occupancy_criterion,
      target_locations_per_cell = target_locations_per_cell,
      lower_quantile_probability = lower_quantile_probability,
      max_fold_location_difference = max_fold_location_difference,
      max_fold_sample_difference = max_fold_sample_difference,
      seed = seed
    )

  res_fallback <-
    make_cross_validation_assignments_from_resolution(
      data_locations = data_locations,
      data_fold_resolution = data_fold_resolution,
      data_grid_calibration = data_branch_grid_calibration,
      n_repeats = n_repeats,
      seed = seed,
      assignment_source = "branch_fallback"
    )

  return(res_fallback)
}

#' @title Resolve Cross-Validation Fold Count
#' @description
#' Resolves the smallest viable location-level fold count from a default toward
#' leave-one-location-out while preserving a minimum training-location count.
#' @param n_locations
#' Single positive integer. Number of unique sampling locations available.
#' @param min_train_locations
#' Single positive integer. Minimum number of locations required in every
#' training partition and in the full model.
#' @param default_folds
#' Single integer greater than one. Preferred grouped fold count. Defaults to
#' `5L`.
#' @return
#' One-row tibble with `n_locations`, `default_folds`, `effective_folds`,
#' `min_train_locations`, `min_training_locations_actual`, `cv_strategy`, and
#' `cv_feasibility_status`. `effective_folds` is `NA` when location-level
#' holdout is infeasible.
#' @details
#' Balanced grouped folds are assessed using the largest possible test fold,
#' `ceiling(n_locations / effective_folds)`. If the preferred fold count would
#' remove too many locations, fold count increases until every training
#' partition is viable. A fold count equal to `n_locations` is classified as
#' leave-one-location-out. A full-model-viable ID with no viable holdout is
#' classified for tier-pooled regularization. Other sample, response, and MEM
#' checks belong to the separate CV feasibility assessment.
#' @examples
#' resolve_cross_validation_fold_count(
#'   n_locations = 7L,
#'   min_train_locations = 5L
#' )
#' @export
resolve_cross_validation_fold_count <- function(
    n_locations = NULL,
    min_train_locations = NULL,
    default_folds = 5L) {
  flag_valid_n_locations <-
    base::is.numeric(n_locations) &&
    base::length(n_locations) == 1L &&
    base::is.finite(n_locations) &&
    n_locations >= 1L &&
    n_locations == base::as.integer(n_locations)

  assertthat::assert_that(
    flag_valid_n_locations,
    msg = "`n_locations` must be a single positive integer."
  )

  flag_valid_min_train_locations <-
    base::is.numeric(min_train_locations) &&
    base::length(min_train_locations) == 1L &&
    base::is.finite(min_train_locations) &&
    min_train_locations >= 1L &&
    min_train_locations == base::as.integer(min_train_locations)

  assertthat::assert_that(
    flag_valid_min_train_locations,
    msg = "`min_train_locations` must be a single positive integer."
  )

  flag_valid_default_folds <-
    base::is.numeric(default_folds) &&
    base::length(default_folds) == 1L &&
    base::is.finite(default_folds) &&
    default_folds >= 2L &&
    default_folds == base::as.integer(default_folds)

  assertthat::assert_that(
    flag_valid_default_folds,
    msg = "`default_folds` must be a single integer greater than one."
  )

  n_locations <-
    base::as.integer(n_locations)

  min_train_locations <-
    base::as.integer(min_train_locations)

  default_folds <-
    base::as.integer(default_folds)

  candidate_start <-
    base::min(default_folds, n_locations)

  vec_candidate_folds <-
    base::seq.int(
      from = candidate_start,
      to = n_locations
    )

  vec_min_training_locations <-
    n_locations - base::ceiling(n_locations / vec_candidate_folds)

  vec_viable_candidates <-
    vec_min_training_locations >= min_train_locations

  effective_folds <-
    dplyr::first(
      vec_candidate_folds[vec_viable_candidates],
      default = NA_integer_
    )

  min_training_locations_actual <-
    dplyr::first(
      base::as.integer(
        vec_min_training_locations[vec_viable_candidates]
      ),
      default = NA_integer_
    )

  cv_feasibility_status <-
    dplyr::case_when(
      n_locations < min_train_locations ~ "full_model_infeasible",
      base::is.na(effective_folds) ~
        "tier_pooled_regularization_required",
      effective_folds == n_locations ~
        "leave_one_location_out_required",
      .default = "grouped_kfold_feasible"
    )

  cv_strategy <-
    dplyr::case_when(
      cv_feasibility_status == "grouped_kfold_feasible" ~
        "spatially_stratified_group_kfold",
      cv_feasibility_status == "leave_one_location_out_required" ~
        "leave_one_location_out",
      .default = "none"
    )

  res <-
    tibble::tibble(
      n_locations = n_locations,
      default_folds = default_folds,
      effective_folds = effective_folds,
      min_train_locations = min_train_locations,
      min_training_locations_actual = min_training_locations_actual,
      cv_strategy = cv_strategy,
      cv_feasibility_status = cv_feasibility_status
    )

  return(res)
}

#' @title Assess Cross-Validation Feasibility
#' @description
#' Evaluates full-model and candidate training-partition diagnostics and
#' selects the first viable cross-validation strategy.
#' @param data_partition_diagnostics
#' Data frame with one row for the full model and one row per candidate
#' training partition. Required columns are `cv_strategy`, `effective_folds`,
#' `fold_id`, `n_train_locations`, `n_train_samples`, `n_train_taxa`, and
#' `n_train_mem_locations`. Supported strategies are `"full_model"`,
#' `"spatially_stratified_group_kfold"`, and
#' `"leave_one_location_out"`.
#' @param min_train_locations,min_train_samples,min_train_taxa
#' Positive integer thresholds required in the full model and every selected
#' training partition.
#' @param min_mem_locations
#' Positive integer minimum number of locations required for MEM construction.
#' @return
#' One-row tibble containing full-data counts, feasibility flags, selected
#' `cv_strategy`, `effective_folds`, and `cv_feasibility_status`.
#' @details
#' The full model is checked first. Viable grouped candidates are preferred in
#' ascending fold-count order, followed by leave-one-location-out. A viable
#' full model without any viable holdout requires tier-pooled regularization.
#' @examples
#' data_diagnostics <-
#'   tibble::tibble(
#'     cv_strategy = "full_model",
#'     effective_folds = NA_integer_,
#'     fold_id = 0L,
#'     n_train_locations = 7L,
#'     n_train_samples = 70L,
#'     n_train_taxa = 10L,
#'     n_train_mem_locations = 7L
#'   )
#' assess_cross_validation_feasibility(
#'   data_partition_diagnostics = data_diagnostics,
#'   min_train_locations = 5L,
#'   min_train_samples = 5L,
#'   min_train_taxa = 3L,
#'   min_mem_locations = 4L
#' )
#' @export
assess_cross_validation_feasibility <- function(
    data_partition_diagnostics = NULL,
    min_train_locations = NULL,
    min_train_samples = NULL,
    min_train_taxa = NULL,
    min_mem_locations = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_partition_diagnostics),
    msg = "`data_partition_diagnostics` must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "cv_strategy",
      "effective_folds",
      "fold_id",
      "n_train_locations",
      "n_train_samples",
      "n_train_taxa",
      "n_train_mem_locations"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in%
        base::colnames(data_partition_diagnostics)
    ),
    msg = "`data_partition_diagnostics` is missing required columns."
  )

  vec_thresholds <-
    base::c(
      min_train_locations,
      min_train_samples,
      min_train_taxa,
      min_mem_locations
    )

  assertthat::assert_that(
    base::is.numeric(vec_thresholds),
    base::length(vec_thresholds) == 4L,
    base::all(base::is.finite(vec_thresholds)),
    base::all(vec_thresholds >= 1L),
    base::all(vec_thresholds == base::as.integer(vec_thresholds)),
    msg = "All minimum thresholds must be positive integers."
  )

  min_train_locations <-
    base::as.integer(min_train_locations)

  min_train_samples <-
    base::as.integer(min_train_samples)

  min_train_taxa <-
    base::as.integer(min_train_taxa)

  min_mem_locations <-
    base::as.integer(min_mem_locations)

  vec_supported_strategies <-
    base::c(
      "full_model",
      "spatially_stratified_group_kfold",
      "leave_one_location_out"
    )

  assertthat::assert_that(
    base::all(
      data_partition_diagnostics[["cv_strategy"]] %in%
        vec_supported_strategies
    ),
    msg = "`cv_strategy` contains an unsupported value."
  )

  vec_count_columns <-
    base::c(
      "fold_id",
      "n_train_locations",
      "n_train_samples",
      "n_train_taxa",
      "n_train_mem_locations"
    )

  vec_count_columns |>
    purrr::walk(
      .f = ~ {
        vec_counts <-
          data_partition_diagnostics[[.x]]

        assertthat::assert_that(
          base::is.numeric(vec_counts),
          base::all(base::is.finite(vec_counts)),
          base::all(vec_counts >= 0L),
          base::all(vec_counts == base::as.integer(vec_counts)),
          msg = stringr::str_glue(
            "`{.x}` must contain non-negative integers."
          )
        )
      }
    )

  data_full_model <-
    data_partition_diagnostics |>
    dplyr::filter(.data[["cv_strategy"]] == "full_model")

  assertthat::assert_that(
    base::nrow(data_full_model) == 1L,
    msg = "Diagnostics must contain exactly one `full_model` row."
  )

  data_candidate_partitions <-
    data_partition_diagnostics |>
    dplyr::filter(.data[["cv_strategy"]] != "full_model")

  if (
    base::nrow(data_candidate_partitions) > 0L
  ) {
    vec_effective_folds <-
      data_candidate_partitions |>
      dplyr::pull("effective_folds")

    assertthat::assert_that(
      base::is.numeric(vec_effective_folds),
      base::all(base::is.finite(vec_effective_folds)),
      base::all(vec_effective_folds >= 2L),
      base::all(
        vec_effective_folds == base::as.integer(vec_effective_folds)
      ),
      msg = stringr::str_c(
        "Candidate `effective_folds` values must be finite integers",
        " ",
        "greater than one."
      )
    )
  }

  data_partition_checks <-
    data_partition_diagnostics |>
    dplyr::mutate(
      partition_feasible =
        .data[["n_train_locations"]] >= min_train_locations &
        .data[["n_train_samples"]] >= min_train_samples &
        .data[["n_train_taxa"]] >= min_train_taxa &
        .data[["n_train_mem_locations"]] >= min_mem_locations
    )

  full_model_feasible <-
    data_partition_checks |>
    dplyr::filter(.data[["cv_strategy"]] == "full_model") |>
    dplyr::pull(.data[["partition_feasible"]]) |>
    dplyr::first()

  data_candidate_summary <-
    data_partition_checks |>
    dplyr::filter(.data[["cv_strategy"]] != "full_model") |>
    dplyr::group_by(
      .data[["cv_strategy"]],
      .data[["effective_folds"]]
    ) |>
    dplyr::summarise(
      candidate_feasible = base::all(.data[["partition_feasible"]]),
      n_partitions = dplyr::n(),
      n_distinct_fold_ids = dplyr::n_distinct(.data[["fold_id"]]),
      .groups = "drop"
    )

  assertthat::assert_that(
    base::all(
      data_candidate_summary[["n_partitions"]] ==
        data_candidate_summary[["effective_folds"]]
    ),
    base::all(
      data_candidate_summary[["n_distinct_fold_ids"]] ==
        data_candidate_summary[["effective_folds"]]
    ),
    msg = stringr::str_c(
      "Every candidate must contain one diagnostic row per distinct",
      " ",
      "fold."
    )
  )

  vec_grouped_folds <-
    data_candidate_summary |>
    dplyr::filter(
      .data[["cv_strategy"]] ==
        "spatially_stratified_group_kfold",
      .data[["candidate_feasible"]]
    ) |>
    dplyr::arrange(.data[["effective_folds"]]) |>
    dplyr::pull(.data[["effective_folds"]])

  vec_leave_one_out_folds <-
    data_candidate_summary |>
    dplyr::filter(
      .data[["cv_strategy"]] == "leave_one_location_out",
      .data[["candidate_feasible"]]
    ) |>
    dplyr::arrange(.data[["effective_folds"]]) |>
    dplyr::pull(.data[["effective_folds"]])

  grouped_kfold_feasible <-
    base::length(vec_grouped_folds) > 0L

  leave_one_location_out_feasible <-
    base::length(vec_leave_one_out_folds) > 0L

  selected_grouped_folds <-
    dplyr::first(vec_grouped_folds, default = NA_integer_)

  selected_leave_one_out_folds <-
    dplyr::first(vec_leave_one_out_folds, default = NA_integer_)

  cv_feasibility_status <-
    dplyr::case_when(
      !full_model_feasible ~ "full_model_infeasible",
      grouped_kfold_feasible ~ "grouped_kfold_feasible",
      leave_one_location_out_feasible ~
        "leave_one_location_out_required",
      .default = "tier_pooled_regularization_required"
    )

  cv_strategy <-
    dplyr::case_when(
      cv_feasibility_status == "grouped_kfold_feasible" ~
        "spatially_stratified_group_kfold",
      cv_feasibility_status == "leave_one_location_out_required" ~
        "leave_one_location_out",
      .default = "none"
    )

  effective_folds <-
    dplyr::case_when(
      cv_feasibility_status == "grouped_kfold_feasible" ~
        selected_grouped_folds,
      cv_feasibility_status == "leave_one_location_out_required" ~
        selected_leave_one_out_folds,
      .default = NA_integer_
    )

  res <-
    tibble::tibble(
      n_locations = data_full_model[["n_train_locations"]],
      n_samples = data_full_model[["n_train_samples"]],
      n_taxa = data_full_model[["n_train_taxa"]],
      n_mem_locations = data_full_model[["n_train_mem_locations"]],
      full_model_feasible = full_model_feasible,
      grouped_kfold_feasible = grouped_kfold_feasible,
      leave_one_location_out_feasible =
        leave_one_location_out_feasible,
      cv_strategy = cv_strategy,
      effective_folds = effective_folds,
      cv_feasibility_status = cv_feasibility_status
    )

  return(res)
}

#' @title Assess sjSDM Scientific Predictive Performance
#' @description
#' Applies a versioned predictive-performance policy to repeated spatial CV
#' evidence while keeping technical validity and calibration separate.
#' @param data_model_repeat_metrics
#' Repeat-level model metrics from `summarise_sjsdm_fold_metrics()`.
#' @param data_paired_repeat_metrics
#' Repeat-level model-minus-null improvements from the same summary.
#' @param data_eligible_model_repeat_metrics
#' Repeat-level model metrics restricted to prespecified eligible taxa.
#' @param data_taxon_eligibility
#' Taxon eligibility table containing `mean_tjur_r2` and `eligible`.
#' @param data_fold_diagnostics Fold fitting diagnostics.
#' @param data_predictions Out-of-fold prediction rows.
#' @param list_policy
#' Named policy list containing the versioned thresholds and requirements.
#' @return
#' A named list containing criterion-level evidence and a one-row decision.
#' @details
#' Tjur R2 is treated as a discrimination measure, not a percentage of
#' variance explained. Calibration is diagnostic and cannot silently override
#' the held-out discrimination and proper-score decision.
#' @examples
#' \dontrun{
#' evaluate_sjsdm_scientific_performance(
#'   data_model_repeat_metrics = data_model_metrics,
#'   data_paired_repeat_metrics = data_improvements,
#'   data_eligible_model_repeat_metrics = data_eligible_metrics,
#'   data_taxon_eligibility = data_eligibility,
#'   data_fold_diagnostics = data_diagnostics,
#'   data_predictions = data_predictions,
#'   list_policy = list_policy
#' )
#' }
#' @export
evaluate_sjsdm_scientific_performance <- function(
    data_model_repeat_metrics = NULL,
    data_paired_repeat_metrics = NULL,
    data_eligible_model_repeat_metrics = NULL,
    data_taxon_eligibility = NULL,
    data_fold_diagnostics = NULL,
    data_predictions = NULL,
    list_policy = NULL) {
  purrr::walk(
    base::list(
      data_model_repeat_metrics,
      data_paired_repeat_metrics,
      data_eligible_model_repeat_metrics,
      data_taxon_eligibility,
      data_fold_diagnostics,
      data_predictions
    ),
    ~ assertthat::assert_that(
      base::is.data.frame(.x),
      msg = "Every scientific-performance evidence input must be a data frame."
    )
  )

  vec_policy_fields <-
    base::c(
      "policy_version",
      "minimum_mean_tjur_r2",
      "minimum_repeat_auc",
      "minimum_positive_taxon_fraction",
      "require_log_loss_improvement_all_repeats",
      "require_brier_improvement_all_repeats",
      "minimum_taxon_fold_evaluable_fraction",
      "calibration_role"
    )

  assertthat::assert_that(
    base::is.list(list_policy),
    base::all(vec_policy_fields %in% base::names(list_policy)),
    msg = "list_policy must contain the scientific-performance contract."
  )

  vec_numeric_policy_fields <-
    base::c(
      "minimum_mean_tjur_r2",
      "minimum_repeat_auc",
      "minimum_positive_taxon_fraction",
      "minimum_taxon_fold_evaluable_fraction"
    )
  vec_numeric_policy_values <-
    purrr::map_dbl(
      vec_numeric_policy_fields,
      ~ purrr::chuck(list_policy, .x)
    )

  assertthat::assert_that(
    base::all(base::is.finite(vec_numeric_policy_values)),
    base::all(vec_numeric_policy_values >= 0),
    base::all(vec_numeric_policy_values <= 1),
    base::is.character(purrr::chuck(list_policy, "policy_version")),
    base::length(purrr::chuck(list_policy, "policy_version")) == 1L,
    purrr::chuck(list_policy, "calibration_role") == "diagnostic",
    msg = "The scientific-performance policy contains invalid values."
  )

  vec_logical_policy_fields <-
    base::c(
      "require_log_loss_improvement_all_repeats",
      "require_brier_improvement_all_repeats"
    )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        vec_logical_policy_fields,
        ~ base::is.logical(purrr::chuck(list_policy, .x)) &&
          base::length(purrr::chuck(list_policy, .x)) == 1L
      )
    ),
    msg = "Proper-score policy requirements must be logical scalars."
  )

  vec_model_metric_columns <-
    base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate",
      "fold_taxon_coverage",
      "n_folds_total"
    )
  vec_paired_metric_columns <-
    base::c("repeat_id", "metric_id", "aggregation_id", "estimate")

  assertthat::assert_that(
    base::all(
      vec_model_metric_columns %in%
        base::colnames(data_model_repeat_metrics)
    ),
    base::all(
      vec_model_metric_columns %in%
        base::colnames(data_eligible_model_repeat_metrics)
    ),
    base::all(
      vec_paired_metric_columns %in%
        base::colnames(data_paired_repeat_metrics)
    ),
    base::all(
      base::c("taxon", "mean_tjur_r2", "eligible") %in%
        base::colnames(data_taxon_eligibility)
    ),
    base::all(
      base::c("repeat_id", "fold_id", "fit_status") %in%
        base::colnames(data_fold_diagnostics)
    ),
    base::all(
      base::c(
        "repeat_id",
        "row_index",
        "taxon",
        "prediction_status",
        "predicted_probability"
      ) %in% base::colnames(data_predictions)
    ),
    msg = "Scientific-performance evidence is missing required columns."
  )

  data_model_fold_macro <-
    data_model_repeat_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["aggregation_id"]] == "fold_macro"
    )
  data_eligible_model_fold_macro <-
    data_eligible_model_repeat_metrics |>
    dplyr::filter(
      .data[["prediction_source"]] == "model",
      .data[["aggregation_id"]] == "fold_macro"
    )
  data_paired_fold_macro <-
    data_paired_repeat_metrics |>
    dplyr::filter(.data[["aggregation_id"]] == "fold_macro")

  data_all_tjur <-
    data_model_fold_macro |>
    dplyr::filter(.data[["metric_id"]] == "tjur_r2")
  data_eligible_tjur <-
    data_eligible_model_fold_macro |>
    dplyr::filter(.data[["metric_id"]] == "tjur_r2")
  data_all_auc <-
    data_model_fold_macro |>
    dplyr::filter(.data[["metric_id"]] == "auc")
  data_log_loss_improvement <-
    data_paired_fold_macro |>
    dplyr::filter(.data[["metric_id"]] == "log_loss")
  data_brier_improvement <-
    data_paired_fold_macro |>
    dplyr::filter(.data[["metric_id"]] == "brier_score")

  vec_required_metric_tables <-
    base::list(
      data_all_tjur,
      data_eligible_tjur,
      data_all_auc,
      data_log_loss_improvement,
      data_brier_improvement
    )

  assertthat::assert_that(
    base::all(purrr::map_int(vec_required_metric_tables, base::nrow) > 0L),
    base::all(
      purrr::map_lgl(
        vec_required_metric_tables,
        ~ !base::anyDuplicated(.x[["repeat_id"]])
      )
    ),
    msg = "Required fold-macro metrics must have one row per repeat."
  )

  list_metric_repeat_ids <-
    purrr::map(
      vec_required_metric_tables,
      ~ base::sort(.x[["repeat_id"]])
    )
  vec_reference_repeat_ids <-
    list_metric_repeat_ids |>
    purrr::chuck(1L)

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        list_metric_repeat_ids,
        ~ base::identical(.x, vec_reference_repeat_ids)
      )
    ),
    msg = "Required fold-macro metric repeat IDs must match."
  )

  data_duplicate_diagnostics <-
    data_fold_diagnostics |>
    dplyr::count(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::filter(.data[["n"]] != 1L)
  data_duplicate_predictions <-
    data_predictions |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["row_index"]],
      .data[["taxon"]]
    ) |>
    dplyr::filter(.data[["n"]] != 1L)
  data_expected_fold_counts <-
    data_all_tjur |>
    dplyr::select("repeat_id", "n_folds_total")
  data_observed_fold_counts <-
    data_fold_diagnostics |>
    dplyr::count(.data[["repeat_id"]], name = "n_folds_observed")
  data_fold_count_comparison <-
    dplyr::full_join(
      data_expected_fold_counts,
      data_observed_fold_counts,
      by = "repeat_id",
      relationship = "one-to-one"
    )
  flag_fold_counts_complete <-
    base::nrow(data_fold_count_comparison) ==
      base::length(vec_reference_repeat_ids) &&
    !base::anyNA(data_fold_count_comparison) &&
    base::all(
      data_fold_count_comparison[["n_folds_total"]] ==
        data_fold_count_comparison[["n_folds_observed"]]
    )

  flag_fold_fits_complete <-
    base::nrow(data_fold_diagnostics) > 0L &&
    base::nrow(data_duplicate_diagnostics) == 0L &&
    flag_fold_counts_complete &&
    base::all(data_fold_diagnostics[["fit_status"]] == "ok")
  vec_allowed_prediction_statuses <-
    base::c("ok", "constant_in_training")
  vec_prediction_probabilities_ok <-
    data_predictions[["predicted_probability"]][
      data_predictions[["prediction_status"]] == "ok"
    ]
  vec_prediction_probabilities_constant <-
    data_predictions[["predicted_probability"]][
      data_predictions[["prediction_status"]] ==
        "constant_in_training"
    ]
  flag_predictions_complete <-
    base::nrow(data_predictions) > 0L &&
    base::nrow(data_duplicate_predictions) == 0L &&
    base::all(
      data_predictions[["prediction_status"]] %in%
        vec_allowed_prediction_statuses
    ) &&
    base::all(
      base::is.finite(vec_prediction_probabilities_ok)
    ) &&
    base::all(base::is.na(vec_prediction_probabilities_constant))

  mean_all_tjur_r2 <-
    base::mean(data_all_tjur[["estimate"]])
  mean_eligible_tjur_r2 <-
    base::mean(data_eligible_tjur[["estimate"]])
  minimum_repeat_auc <-
    base::min(data_all_auc[["estimate"]])
  minimum_log_loss_improvement <-
    base::min(data_log_loss_improvement[["estimate"]])
  minimum_brier_improvement <-
    base::min(data_brier_improvement[["estimate"]])
  minimum_taxon_fold_coverage <-
    base::min(data_all_tjur[["fold_taxon_coverage"]])

  vec_finite_taxon_tjur <-
    data_taxon_eligibility[["mean_tjur_r2"]][
      base::is.finite(data_taxon_eligibility[["mean_tjur_r2"]])
    ]
  proportion_positive_taxa <-
    base::mean(vec_finite_taxon_tjur > 0)

  flag_require_log_loss <-
    purrr::chuck(
      list_policy,
      "require_log_loss_improvement_all_repeats"
    )
  flag_require_brier <-
    purrr::chuck(
      list_policy,
      "require_brier_improvement_all_repeats"
    )

  data_performance_criteria <-
    tibble::tibble(
      criterion_id = base::c(
        "fold_fits_complete",
        "predictions_complete",
        "all_taxa_mean_tjur_r2",
        "eligible_taxa_mean_tjur_r2",
        "minimum_repeat_auc",
        "log_loss_improvement_all_repeats",
        "brier_improvement_all_repeats",
        "positive_taxon_fraction",
        "minimum_taxon_fold_evaluable_fraction"
      ),
      domain = base::c(
        base::rep("technical", 2L),
        base::rep("scientific_prediction", 7L)
      ),
      observed_value = base::c(
        base::as.numeric(flag_fold_fits_complete),
        base::as.numeric(flag_predictions_complete),
        mean_all_tjur_r2,
        mean_eligible_tjur_r2,
        minimum_repeat_auc,
        minimum_log_loss_improvement,
        minimum_brier_improvement,
        proportion_positive_taxa,
        minimum_taxon_fold_coverage
      ),
      threshold_value = base::c(
        1,
        1,
        purrr::chuck(list_policy, "minimum_mean_tjur_r2"),
        purrr::chuck(list_policy, "minimum_mean_tjur_r2"),
        purrr::chuck(list_policy, "minimum_repeat_auc"),
        0,
        0,
        purrr::chuck(list_policy, "minimum_positive_taxon_fraction"),
        purrr::chuck(
          list_policy,
          "minimum_taxon_fold_evaluable_fraction"
        )
      ),
      comparison = base::c(
        "equal",
        "equal",
        "greater_than_or_equal",
        "greater_than_or_equal",
        "greater_than",
        "greater_than",
        "greater_than",
        "greater_than_or_equal",
        "greater_than_or_equal"
      ),
      required = base::c(
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        flag_require_log_loss,
        flag_require_brier,
        TRUE,
        TRUE
      ),
      passed = base::c(
        flag_fold_fits_complete,
        flag_predictions_complete,
        mean_all_tjur_r2 >=
          purrr::chuck(list_policy, "minimum_mean_tjur_r2"),
        mean_eligible_tjur_r2 >=
          purrr::chuck(list_policy, "minimum_mean_tjur_r2"),
        minimum_repeat_auc >
          purrr::chuck(list_policy, "minimum_repeat_auc"),
        minimum_log_loss_improvement > 0,
        minimum_brier_improvement > 0,
        proportion_positive_taxa >=
          purrr::chuck(
            list_policy,
            "minimum_positive_taxon_fraction"
          ),
        minimum_taxon_fold_coverage >=
          purrr::chuck(
            list_policy,
            "minimum_taxon_fold_evaluable_fraction"
          )
      )
    ) |>
    dplyr::mutate(
      criterion_status = dplyr::if_else(
        base::is.finite(.data[["observed_value"]]),
        "evaluated",
        "not_evaluable"
      )
    )

  data_technical_criteria <-
    data_performance_criteria |>
    dplyr::filter(.data[["domain"]] == "technical")
  data_scientific_criteria <-
    data_performance_criteria |>
    dplyr::filter(
      .data[["domain"]] == "scientific_prediction",
      .data[["required"]]
    )

  flag_technical_pass <-
    base::all(data_technical_criteria[["passed"]])
  flag_scientific_evidence_complete <-
    base::all(
      data_scientific_criteria[["criterion_status"]] == "evaluated"
    )
  flag_scientific_pass <-
    flag_scientific_evidence_complete &&
    base::all(data_scientific_criteria[["passed"]])

  vec_failed_criteria <-
    data_performance_criteria |>
    dplyr::filter(
      .data[["required"]],
      .data[["criterion_status"]] != "evaluated" |
        !.data[["passed"]]
    ) |>
    dplyr::pull(.data[["criterion_id"]])

  vec_failed_null_criteria <-
    base::c(
      "log_loss_improvement_all_repeats",
      "brier_improvement_all_repeats"
    )
  flag_null_skill_failed <-
    base::any(vec_failed_criteria %in% vec_failed_null_criteria)

  scientific_prediction_status <-
    dplyr::case_when(
      !flag_technical_pass || !flag_scientific_evidence_complete ~
        "insufficient_evidence",
      flag_scientific_pass ~ "pass",
      flag_null_skill_failed ~ "fail_null_skill",
      TRUE ~ "fail_discrimination"
    )

  data_calibration <-
    data_model_fold_macro |>
    dplyr::filter(
      .data[["metric_id"]] %in%
        base::c("calibration_intercept", "calibration_slope")
    )
  data_calibration_counts <-
    data_calibration |>
    dplyr::count(.data[["metric_id"]])
  flag_calibration_complete <-
    base::nrow(data_calibration_counts) == 2L &&
    base::all(base::is.finite(data_calibration[["estimate"]]))

  calibration_status <- "not_evaluable"

  if (
    flag_calibration_complete
  ) {
    vec_calibration_intercepts <-
      data_calibration |>
      dplyr::filter(.data[["metric_id"]] == "calibration_intercept") |>
      dplyr::pull(.data[["estimate"]])
    vec_calibration_slopes <-
      data_calibration |>
      dplyr::filter(.data[["metric_id"]] == "calibration_slope") |>
      dplyr::pull(.data[["estimate"]])

    flag_intercept_range_contains_zero <-
      base::min(vec_calibration_intercepts) <= 0 &&
      base::max(vec_calibration_intercepts) >= 0
    flag_slope_range_contains_one <-
      base::min(vec_calibration_slopes) <= 1 &&
      base::max(vec_calibration_slopes) >= 1

    calibration_status <-
      dplyr::if_else(
        flag_intercept_range_contains_zero &&
          flag_slope_range_contains_one,
        "acceptable",
        "caution"
      )
  }

  decision_reasons <-
    dplyr::if_else(
      base::length(vec_failed_criteria) == 0L,
      NA_character_,
      stringr::str_c(vec_failed_criteria, collapse = ";")
    )

  data_performance_decision <-
    tibble::tibble(
      policy_version = purrr::chuck(list_policy, "policy_version"),
      technical_cv_status = dplyr::if_else(
        flag_technical_pass,
        "pass",
        "fail"
      ),
      scientific_prediction_status = scientific_prediction_status,
      calibration_status = calibration_status,
      decision_reasons = decision_reasons
    )

  res <-
    base::list(
      data_performance_criteria = data_performance_criteria,
      data_performance_decision = data_performance_decision
    )

  return(res)
}

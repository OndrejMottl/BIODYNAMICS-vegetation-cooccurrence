#' @title Assess a Paired Spatial MEM Benchmark
#' @description
#' Compares exact and fast spatial MEM runs on identical repetitions against
#' the Issue 138 technical and predictive regression allowances.
#' @param data_benchmark_runs
#' One row per repetition and spatial MEM strategy.
#' @param list_policy
#' Issue 138 benchmark policy. Defaults to
#' [build_sjsdm_staged_benchmark_policy()].
#' @return
#' Named list with paired comparisons, gate results, and one decision row.
#' @export
evaluate_spatial_mev_paired_benchmark <- function(
    data_benchmark_runs = NULL,
    list_policy = build_sjsdm_staged_benchmark_policy()) {
  vec_required_columns <-
    base::c(
      "repetition_id",
      "spatial_mev_strategy",
      "mean_log_loss",
      "mean_auc",
      "mean_tjur_r2",
      "evaluable_taxon_coverage",
      "technical_cv_status",
      "assignment_hash",
      "artifact_schema_hash"
    )

  vec_policy_fields <-
    base::c(
      "policy_version",
      "maximum_log_loss_regression",
      "maximum_auc_regression",
      "maximum_tjur_r2_regression",
      "maximum_coverage_regression"
    )

  assertthat::assert_that(
    base::is.data.frame(data_benchmark_runs),
    base::all(
      vec_required_columns %in% base::colnames(data_benchmark_runs)
    ),
    msg = "`data_benchmark_runs` is missing required columns."
  )

  assertthat::assert_that(
    base::is.list(list_policy),
    base::all(vec_policy_fields %in% base::names(list_policy)),
    msg = "`list_policy` is missing predictive benchmark thresholds."
  )

  vec_numeric_columns <-
    base::c(
      "repetition_id",
      "mean_log_loss",
      "mean_auc",
      "mean_tjur_r2",
      "evaluable_taxon_coverage"
    )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        vec_numeric_columns,
        ~ base::is.numeric(data_benchmark_runs[[.x]]) &&
          base::all(base::is.finite(data_benchmark_runs[[.x]]))
      )
    ),
    msg = "Paired MEM benchmark metrics must be finite numeric values."
  )

  vec_character_columns <-
    base::c(
      "spatial_mev_strategy",
      "technical_cv_status",
      "assignment_hash",
      "artifact_schema_hash"
    )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        vec_character_columns,
        ~ base::is.character(data_benchmark_runs[[.x]]) &&
          base::all(!base::is.na(data_benchmark_runs[[.x]])) &&
          base::all(base::nzchar(data_benchmark_runs[[.x]]))
      )
    ),
    msg = "Paired MEM benchmark identifiers must be non-empty strings."
  )

  data_pair_counts <-
    data_benchmark_runs |>
    dplyr::count(
      .data[["repetition_id"]],
      name = "n_rows"
    ) |>
    dplyr::left_join(
      data_benchmark_runs |>
        dplyr::group_by(.data[["repetition_id"]]) |>
        dplyr::summarise(
          n_strategies =
            dplyr::n_distinct(.data[["spatial_mev_strategy"]]),
          .groups = "drop"
        ),
      by = "repetition_id",
      relationship = "one-to-one"
    )

  flag_complete_pairs <-
    base::nrow(data_pair_counts) > 0L &&
    base::all(data_pair_counts[["n_rows"]] == 2L) &&
    base::all(data_pair_counts[["n_strategies"]] == 2L) &&
    base::setequal(
      data_benchmark_runs[["spatial_mev_strategy"]],
      base::c("exact", "fast")
    )

  assertthat::assert_that(
    flag_complete_pairs,
    msg = "Each repetition must contain one exact and one fast MEM run."
  )

  vec_value_columns <-
    base::setdiff(
      vec_required_columns,
      base::c("repetition_id", "spatial_mev_strategy")
    )

  data_pairs_wide <-
    data_benchmark_runs |>
    tidyr::pivot_wider(
      names_from = "spatial_mev_strategy",
      values_from = tidyselect::all_of(vec_value_columns),
      names_sep = "_"
    )

  data_pair_comparisons <-
    data_pairs_wide |>
    dplyr::mutate(
      log_loss_regression =
        .data[["mean_log_loss_fast"]] -
        .data[["mean_log_loss_exact"]],
      auc_regression =
        .data[["mean_auc_exact"]] -
        .data[["mean_auc_fast"]],
      tjur_r2_regression =
        .data[["mean_tjur_r2_exact"]] -
        .data[["mean_tjur_r2_fast"]],
      coverage_regression =
        .data[["evaluable_taxon_coverage_exact"]] -
        .data[["evaluable_taxon_coverage_fast"]],
      technical_status_match =
        .data[["technical_cv_status_exact"]] ==
        .data[["technical_cv_status_fast"]],
      technical_status_pass =
        .data[["technical_cv_status_exact"]] == "pass" &
        .data[["technical_cv_status_fast"]] == "pass",
      assignment_match =
        .data[["assignment_hash_exact"]] ==
        .data[["assignment_hash_fast"]],
      artifact_schema_match =
        .data[["artifact_schema_hash_exact"]] ==
        .data[["artifact_schema_hash_fast"]]
    ) |>
    dplyr::select(
      "repetition_id",
      "log_loss_regression",
      "auc_regression",
      "tjur_r2_regression",
      "coverage_regression",
      "technical_status_match",
      "technical_status_pass",
      "assignment_match",
      "artifact_schema_match"
    ) |>
    dplyr::arrange(.data[["repetition_id"]])

  data_gate_results <-
    tibble::tibble(
      criterion_id = base::c(
        "technical_status_match",
        "technical_status_pass",
        "assignment_match",
        "artifact_schema_match",
        "log_loss_regression",
        "auc_regression",
        "tjur_r2_regression",
        "coverage_regression"
      ),
      observed_value = base::c(
        base::as.numeric(
          base::all(
            data_pair_comparisons[["technical_status_match"]]
          )
        ),
        base::as.numeric(
          base::all(
            data_pair_comparisons[["technical_status_pass"]]
          )
        ),
        base::as.numeric(
          base::all(data_pair_comparisons[["assignment_match"]])
        ),
        base::as.numeric(
          base::all(
            data_pair_comparisons[["artifact_schema_match"]]
          )
        ),
        base::max(data_pair_comparisons[["log_loss_regression"]]),
        base::max(data_pair_comparisons[["auc_regression"]]),
        base::max(data_pair_comparisons[["tjur_r2_regression"]]),
        base::max(data_pair_comparisons[["coverage_regression"]])
      ),
      threshold_value = base::c(
        base::rep(1, 4L),
        purrr::chuck(list_policy, "maximum_log_loss_regression"),
        purrr::chuck(list_policy, "maximum_auc_regression"),
        purrr::chuck(list_policy, "maximum_tjur_r2_regression"),
        purrr::chuck(list_policy, "maximum_coverage_regression")
      ),
      comparison = base::c(
        base::rep("equal", 4L),
        base::rep("less_than_or_equal", 4L)
      )
    ) |>
    dplyr::mutate(
      passed = dplyr::if_else(
        .data[["comparison"]] == "equal",
        .data[["observed_value"]] == .data[["threshold_value"]],
        .data[["observed_value"]] <= .data[["threshold_value"]]
      )
    )

  vec_failed_gates <-
    data_gate_results |>
    dplyr::filter(!.data[["passed"]]) |>
    dplyr::pull("criterion_id")

  data_benchmark_decision <-
    tibble::tibble(
      policy_version = purrr::chuck(list_policy, "policy_version"),
      benchmark_status = dplyr::if_else(
        base::length(vec_failed_gates) == 0L,
        "pass",
        "fail"
      ),
      failed_gates = dplyr::if_else(
        base::length(vec_failed_gates) == 0L,
        NA_character_,
        stringr::str_c(vec_failed_gates, collapse = ";")
      )
    )

  res <-
    base::list(
      data_pair_comparisons = data_pair_comparisons,
      data_gate_results = data_gate_results,
      data_benchmark_decision = data_benchmark_decision
    )

  return(res)
}

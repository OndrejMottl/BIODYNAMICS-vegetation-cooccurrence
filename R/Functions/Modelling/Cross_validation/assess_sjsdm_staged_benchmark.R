#' @title Assess the Paired sjSDM Staged Benchmark
#' @description
#' Compares paired exhaustive and staged benchmark repetitions against the
#' frozen issue 138 runtime, resource, technical, and scientific gates.
#' @param data_benchmark_runs
#' One row per strategy and benchmark repetition containing measured resources,
#' fit counts, predictive metrics, technical hashes, and selection evidence.
#' @param list_policy
#' Named list containing the versioned issue 138 acceptance thresholds.
#' @return
#' A named list containing paired comparisons, criterion-level gate results,
#' and a one-row benchmark decision.
#' @export
assess_sjsdm_staged_benchmark <- function(
    data_benchmark_runs = NULL,
    list_policy = NULL) {
  vec_required_columns <-
    base::c(
      "repetition_id",
      "tuning_strategy",
      "wall_seconds",
      "store_bytes",
      "peak_ram_bytes",
      "peak_vram_bytes",
      "gpu_memory_failure",
      "n_fits_executed",
      "mean_log_loss",
      "mean_auc",
      "mean_tjur_r2",
      "evaluable_taxon_coverage",
      "technical_cv_status",
      "assignment_hash",
      "artifact_schema_hash",
      "selected_candidate_id"
    )
  vec_policy_fields <-
    base::c(
      "policy_version",
      "minimum_median_wall_reduction",
      "minimum_each_wall_reduction",
      "minimum_fit_reduction",
      "maximum_store_growth",
      "maximum_memory_growth",
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
    msg = "data_benchmark_runs is missing required columns."
  )
  assertthat::assert_that(
    base::is.list(list_policy),
    base::all(vec_policy_fields %in% base::names(list_policy)),
    msg = "list_policy is missing issue 138 benchmark thresholds."
  )

  vec_numeric_columns <-
    base::c(
      "repetition_id",
      "wall_seconds",
      "store_bytes",
      "peak_ram_bytes",
      "peak_vram_bytes",
      "n_fits_executed",
      "mean_log_loss",
      "mean_auc",
      "mean_tjur_r2",
      "evaluable_taxon_coverage"
    )
  flag_numeric_columns <-
    base::all(
      purrr::map_lgl(
        vec_numeric_columns,
        ~ base::is.numeric(data_benchmark_runs[[.x]])
      )
    )
  flag_finite_columns <-
    base::all(
      purrr::map_lgl(
        vec_numeric_columns,
        ~ base::all(base::is.finite(data_benchmark_runs[[.x]]))
      )
    )

  assertthat::assert_that(
    flag_numeric_columns,
    flag_finite_columns,
    base::is.logical(data_benchmark_runs[["gpu_memory_failure"]]),
    !base::anyNA(data_benchmark_runs[["gpu_memory_failure"]]),
    base::all(data_benchmark_runs[["wall_seconds"]] > 0),
    base::all(data_benchmark_runs[["store_bytes"]] > 0),
    base::all(data_benchmark_runs[["peak_ram_bytes"]] > 0),
    base::all(data_benchmark_runs[["peak_vram_bytes"]] > 0),
    base::all(data_benchmark_runs[["n_fits_executed"]] > 0),
    msg = "Benchmark measurements must be finite and positive."
  )

  vec_character_columns <-
    base::c(
      "tuning_strategy",
      "technical_cv_status",
      "assignment_hash",
      "artifact_schema_hash",
      "selected_candidate_id"
    )
  flag_character_columns <-
    base::all(
      purrr::map_lgl(
        vec_character_columns,
        ~ base::is.character(data_benchmark_runs[[.x]]) &&
          base::all(!base::is.na(data_benchmark_runs[[.x]])) &&
          base::all(base::nzchar(data_benchmark_runs[[.x]]))
      )
    )

  assertthat::assert_that(
    flag_character_columns,
    msg = "Benchmark identifiers must be non-empty strings."
  )

  vec_numeric_policy_fields <-
    base::setdiff(vec_policy_fields, "policy_version")
  vec_numeric_policy <-
    purrr::map_dbl(
      vec_numeric_policy_fields,
      ~ purrr::chuck(list_policy, .x)
    )

  assertthat::assert_that(
    base::is.character(purrr::chuck(list_policy, "policy_version")),
    base::length(purrr::chuck(list_policy, "policy_version")) == 1L,
    base::all(base::is.finite(vec_numeric_policy)),
    base::all(vec_numeric_policy >= 0),
    msg = "Benchmark policy values must be finite and non-negative."
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
          n_strategies = dplyr::n_distinct(.data[["tuning_strategy"]]),
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
      data_benchmark_runs[["tuning_strategy"]],
      base::c("exhaustive", "staged")
    )

  assertthat::assert_that(
    flag_complete_pairs,
    msg = "Each repetition must contain one exhaustive and one staged run."
  )

  vec_pair_value_columns <-
    base::setdiff(
      vec_required_columns,
      base::c("repetition_id", "tuning_strategy")
    )
  data_pairs_wide <-
    data_benchmark_runs |>
    tidyr::pivot_wider(
      names_from = "tuning_strategy",
      values_from = tidyselect::all_of(vec_pair_value_columns),
      names_sep = "_"
    )

  data_pair_comparisons <-
    data_pairs_wide |>
    dplyr::transmute(
      repetition_id = .data[["repetition_id"]],
      wall_reduction =
        (.data[["wall_seconds_exhaustive"]] -
          .data[["wall_seconds_staged"]]) /
        .data[["wall_seconds_exhaustive"]],
      store_growth =
        (.data[["store_bytes_staged"]] -
          .data[["store_bytes_exhaustive"]]) /
        .data[["store_bytes_exhaustive"]],
      ram_growth =
        (.data[["peak_ram_bytes_staged"]] -
          .data[["peak_ram_bytes_exhaustive"]]) /
        .data[["peak_ram_bytes_exhaustive"]],
      vram_growth =
        (.data[["peak_vram_bytes_staged"]] -
          .data[["peak_vram_bytes_exhaustive"]]) /
        .data[["peak_vram_bytes_exhaustive"]],
      fit_reduction =
        (.data[["n_fits_executed_exhaustive"]] -
          .data[["n_fits_executed_staged"]]) /
        .data[["n_fits_executed_exhaustive"]],
      log_loss_regression =
        .data[["mean_log_loss_staged"]] -
        .data[["mean_log_loss_exhaustive"]],
      auc_regression =
        .data[["mean_auc_exhaustive"]] -
        .data[["mean_auc_staged"]],
      tjur_r2_regression =
        .data[["mean_tjur_r2_exhaustive"]] -
        .data[["mean_tjur_r2_staged"]],
      coverage_regression =
        .data[["evaluable_taxon_coverage_exhaustive"]] -
        .data[["evaluable_taxon_coverage_staged"]],
      gpu_memory_failure =
        .data[["gpu_memory_failure_exhaustive"]] |
        .data[["gpu_memory_failure_staged"]],
      technical_status_match =
        .data[["technical_cv_status_exhaustive"]] ==
        .data[["technical_cv_status_staged"]],
      technical_status_pass =
        .data[["technical_cv_status_exhaustive"]] == "pass" &
        .data[["technical_cv_status_staged"]] == "pass",
      assignment_match =
        .data[["assignment_hash_exhaustive"]] ==
        .data[["assignment_hash_staged"]],
      artifact_schema_match =
        .data[["artifact_schema_hash_exhaustive"]] ==
        .data[["artifact_schema_hash_staged"]],
      selected_candidate_changed =
        .data[["selected_candidate_id_exhaustive"]] !=
        .data[["selected_candidate_id_staged"]]
    ) |>
    dplyr::arrange(.data[["repetition_id"]])

  data_gate_results <-
    tibble::tibble(
      criterion_id = base::c(
        "median_wall_reduction",
        "each_wall_reduction",
        "fit_reduction",
        "store_growth",
        "ram_growth",
        "vram_growth",
        "no_gpu_memory_failure",
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
        stats::median(data_pair_comparisons[["wall_reduction"]]),
        base::min(data_pair_comparisons[["wall_reduction"]]),
        base::min(data_pair_comparisons[["fit_reduction"]]),
        base::max(data_pair_comparisons[["store_growth"]]),
        base::max(data_pair_comparisons[["ram_growth"]]),
        base::max(data_pair_comparisons[["vram_growth"]]),
        base::as.numeric(
          !base::any(data_pair_comparisons[["gpu_memory_failure"]])
        ),
        base::as.numeric(
          base::all(data_pair_comparisons[["technical_status_match"]])
        ),
        base::as.numeric(
          base::all(data_pair_comparisons[["technical_status_pass"]])
        ),
        base::as.numeric(
          base::all(data_pair_comparisons[["assignment_match"]])
        ),
        base::as.numeric(
          base::all(data_pair_comparisons[["artifact_schema_match"]])
        ),
        base::max(data_pair_comparisons[["log_loss_regression"]]),
        base::max(data_pair_comparisons[["auc_regression"]]),
        base::max(data_pair_comparisons[["tjur_r2_regression"]]),
        base::max(data_pair_comparisons[["coverage_regression"]])
      ),
      threshold_value = base::c(
        purrr::chuck(list_policy, "minimum_median_wall_reduction"),
        purrr::chuck(list_policy, "minimum_each_wall_reduction"),
        purrr::chuck(list_policy, "minimum_fit_reduction"),
        purrr::chuck(list_policy, "maximum_store_growth"),
        base::rep(
          purrr::chuck(list_policy, "maximum_memory_growth"),
          2L
        ),
        base::rep(1, 5L),
        purrr::chuck(list_policy, "maximum_log_loss_regression"),
        purrr::chuck(list_policy, "maximum_auc_regression"),
        purrr::chuck(list_policy, "maximum_tjur_r2_regression"),
        purrr::chuck(list_policy, "maximum_coverage_regression")
      ),
      comparison = base::c(
        base::rep("greater_than_or_equal", 3L),
        base::rep("less_than_or_equal", 3L),
        base::rep("equal", 5L),
        base::rep("less_than_or_equal", 4L)
      )
    ) |>
    dplyr::mutate(
      passed = dplyr::case_when(
        .data[["comparison"]] == "greater_than_or_equal" ~
          .data[["observed_value"]] >= .data[["threshold_value"]],
        .data[["comparison"]] == "less_than_or_equal" ~
          .data[["observed_value"]] <= .data[["threshold_value"]],
        TRUE ~ .data[["observed_value"]] == .data[["threshold_value"]]
      )
    )

  flag_gate_pass <-
    base::all(data_gate_results[["passed"]])
  flag_scientific_review <-
    base::any(
      data_pair_comparisons[["selected_candidate_changed"]]
    )
  benchmark_status <-
    dplyr::case_when(
      !flag_gate_pass ~ "fail",
      flag_scientific_review ~ "scientific_review",
      TRUE ~ "pass"
    )
  vec_failed_gates <-
    data_gate_results |>
    dplyr::filter(!.data[["passed"]]) |>
    dplyr::pull(.data[["criterion_id"]])

  data_benchmark_decision <-
    tibble::tibble(
      policy_version = purrr::chuck(list_policy, "policy_version"),
      benchmark_status = benchmark_status,
      scientific_review_required = flag_scientific_review,
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

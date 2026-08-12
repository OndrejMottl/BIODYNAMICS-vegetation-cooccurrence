make_scientific_performance_fixture <- function() {
  data_model_repeat_metrics <-
    tidyr::crossing(
      repeat_id = 1:3,
      metric_id = base::c(
        "tjur_r2",
        "auc",
        "calibration_intercept",
        "calibration_slope"
      )
    ) |>
    dplyr::mutate(
      prediction_source = "model",
      aggregation_id = "fold_macro",
      estimate = dplyr::case_when(
        .data[["metric_id"]] == "tjur_r2" ~ 0.16,
        .data[["metric_id"]] == "auc" ~ 0.80,
        .data[["metric_id"]] == "calibration_intercept" ~ 0.20,
        TRUE ~ 2.0
      ),
      fold_taxon_coverage = 0.85,
      n_folds_total = 5L
    )

  data_paired_repeat_metrics <-
    tidyr::crossing(
      repeat_id = 1:3,
      metric_id = base::c("log_loss", "brier_score")
    ) |>
    dplyr::mutate(
      aggregation_id = "fold_macro",
      estimate = dplyr::if_else(
        .data[["metric_id"]] == "log_loss",
        0.08,
        0.03
      )
    )

  data_eligible_model_repeat_metrics <-
    data_model_repeat_metrics |>
    dplyr::mutate(
      estimate = dplyr::if_else(
        .data[["metric_id"]] == "tjur_r2",
        0.20,
        .data[["estimate"]]
      )
    )

  data_taxon_eligibility <-
    tibble::tibble(
      taxon = base::c("a", "b", "c", "d", "e"),
      mean_tjur_r2 = base::c(0.2, 0.1, 0.05, 0.01, -0.01),
      eligible = base::c(TRUE, TRUE, TRUE, TRUE, FALSE)
    )

  data_fold_diagnostics <-
    tidyr::crossing(
      repeat_id = 1:3,
      fold_id = 1:5
    ) |>
    dplyr::mutate(fit_status = "ok")

  data_predictions <-
    tidyr::crossing(
      repeat_id = 1:3,
      row_index = 1:2,
      taxon = base::c("a", "b")
    ) |>
    dplyr::mutate(
      prediction_status = dplyr::if_else(
        .data[["repeat_id"]] == 1L &
          .data[["row_index"]] == 1L &
          .data[["taxon"]] == "b",
        "constant_in_training",
        "ok"
      ),
      predicted_probability = dplyr::if_else(
        .data[["prediction_status"]] == "ok",
        0.5,
        NA_real_
      )
    )

  list_policy <-
    base::list(
      policy_version = "sjsdm_scientific_performance_v1",
      minimum_mean_tjur_r2 = 0.1,
      minimum_repeat_auc = 0.5,
      minimum_positive_taxon_fraction = 0.8,
      require_log_loss_improvement_all_repeats = TRUE,
      require_brier_improvement_all_repeats = TRUE,
      minimum_taxon_fold_evaluable_fraction = 0.8,
      calibration_role = "diagnostic"
    )

  return(
    base::list(
      data_model_repeat_metrics = data_model_repeat_metrics,
      data_paired_repeat_metrics = data_paired_repeat_metrics,
      data_eligible_model_repeat_metrics =
        data_eligible_model_repeat_metrics,
      data_taxon_eligibility = data_taxon_eligibility,
      data_fold_diagnostics = data_fold_diagnostics,
      data_predictions = data_predictions,
      list_policy = list_policy
    )
  )
}

testthat::test_that(
  "scientific performance separates prediction and calibration decisions",
  {
    list_fixture <-
      make_scientific_performance_fixture()

    res <-
      evaluate_sjsdm_scientific_performance(
        data_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_model_repeat_metrics"),
        data_paired_repeat_metrics = list_fixture |>
          purrr::chuck("data_paired_repeat_metrics"),
        data_eligible_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_eligible_model_repeat_metrics"),
        data_taxon_eligibility = list_fixture |>
          purrr::chuck("data_taxon_eligibility"),
        data_fold_diagnostics = list_fixture |>
          purrr::chuck("data_fold_diagnostics"),
        data_predictions = list_fixture |>
          purrr::chuck("data_predictions"),
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )

    data_decision <-
      res |>
      purrr::chuck("data_performance_decision")
    data_criteria <-
      res |>
      purrr::chuck("data_performance_criteria")

    testthat::expect_equal(
      data_decision[["technical_cv_status"]],
      "pass"
    )
    testthat::expect_equal(
      data_decision[["scientific_prediction_status"]],
      "pass"
    )
    testthat::expect_equal(
      data_decision[["calibration_status"]],
      "caution"
    )
    testthat::expect_equal(base::nrow(data_criteria), 9L)
    testthat::expect_true(
      base::all(
        data_criteria[["criterion_status"]] == "evaluated"
      )
    )
  }
)

testthat::test_that(
  "scientific performance rejects inconsistent proper-score skill",
  {
    list_fixture <-
      make_scientific_performance_fixture()
    data_paired_repeat_metrics <-
      list_fixture |>
      purrr::chuck("data_paired_repeat_metrics") |>
      dplyr::mutate(
        estimate = dplyr::if_else(
          .data[["metric_id"]] == "log_loss" &
            .data[["repeat_id"]] == 2L,
          -0.01,
          .data[["estimate"]]
        )
      )

    res <-
      evaluate_sjsdm_scientific_performance(
        data_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_model_repeat_metrics"),
        data_paired_repeat_metrics = data_paired_repeat_metrics,
        data_eligible_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_eligible_model_repeat_metrics"),
        data_taxon_eligibility = list_fixture |>
          purrr::chuck("data_taxon_eligibility"),
        data_fold_diagnostics = list_fixture |>
          purrr::chuck("data_fold_diagnostics"),
        data_predictions = list_fixture |>
          purrr::chuck("data_predictions"),
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )

    data_decision <-
      res |>
      purrr::chuck("data_performance_decision")

    testthat::expect_equal(
      data_decision[["scientific_prediction_status"]],
      "fail_null_skill"
    )
    testthat::expect_match(
      data_decision[["decision_reasons"]],
      "log_loss_improvement_all_repeats",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "scientific performance stops a scientific pass after technical failure",
  {
    list_fixture <-
      make_scientific_performance_fixture()
    data_fold_diagnostics <-
      list_fixture |>
      purrr::chuck("data_fold_diagnostics") |>
      dplyr::filter(
        !(
          .data[["repeat_id"]] == 1L &
            .data[["fold_id"]] == 1L
        )
      )

    res <-
      evaluate_sjsdm_scientific_performance(
        data_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_model_repeat_metrics"),
        data_paired_repeat_metrics = list_fixture |>
          purrr::chuck("data_paired_repeat_metrics"),
        data_eligible_model_repeat_metrics = list_fixture |>
          purrr::chuck("data_eligible_model_repeat_metrics"),
        data_taxon_eligibility = list_fixture |>
          purrr::chuck("data_taxon_eligibility"),
        data_fold_diagnostics = data_fold_diagnostics,
        data_predictions = list_fixture |>
          purrr::chuck("data_predictions"),
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )

    data_decision <-
      res |>
      purrr::chuck("data_performance_decision")

    testthat::expect_equal(
      data_decision[["technical_cv_status"]],
      "fail"
    )
    testthat::expect_equal(
      data_decision[["scientific_prediction_status"]],
      "insufficient_evidence"
    )
  }
)

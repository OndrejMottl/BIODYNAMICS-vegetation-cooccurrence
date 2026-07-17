testthat::test_that(
  "assess_sjsdm_candidate_guardrails() accepts stable improvement",
  {
    data_tuning <-
      tidyr::crossing(
        repeat_id = 1:3,
        candidate_id = base::c("candidate", "reference")
      ) |>
      dplyr::mutate(
        negative_log_likelihood_per_response = dplyr::if_else(
          .data[["candidate_id"]] == "candidate",
          0.29,
          0.30
        ),
        auc_macro_test = dplyr::if_else(
          .data[["candidate_id"]] == "candidate",
          0.69,
          0.70
        ),
        summary_status = "ok"
      )

    make_metrics <- function(source) {
      tidyr::crossing(
        repeat_id = 1:3,
        metric_id = base::c(
          "auc",
          "brier_score",
          "log_loss",
          "tjur_r2"
        )
      ) |>
        dplyr::mutate(
          prediction_source = "model",
          aggregation_id = "fold_macro",
          estimate = dplyr::case_when(
            .data[["metric_id"]] == "auc" & source == "candidate" ~ 0.71,
            .data[["metric_id"]] == "auc" ~ 0.70,
            .data[["metric_id"]] == "tjur_r2" &
              source == "candidate" ~ 0.12,
            .data[["metric_id"]] == "tjur_r2" ~ 0.11,
            .data[["metric_id"]] == "log_loss" &
              source == "candidate" ~ 0.29,
            .data[["metric_id"]] == "log_loss" ~ 0.30,
            .data[["metric_id"]] == "brier_score" &
              source == "candidate" ~ 0.09,
            TRUE ~ 0.10
          )
        )
    }

    res <-
      assess_sjsdm_candidate_guardrails(
        data_tuning_summary = data_tuning,
        data_candidate_repeat_metrics = make_metrics("candidate"),
        data_reference_repeat_metrics = make_metrics("reference"),
        candidate_id = "candidate",
        reference_candidate_id = "reference"
      )

    data_summary <-
      purrr::chuck(res, "data_guardrail_summary")

    testthat::expect_true(data_summary[["eligible"]])
    testthat::expect_equal(
      data_summary[["selection_guardrail_status"]],
      "eligible"
    )
    testthat::expect_equal(
      data_summary[["n_repeats_nll_improved"]],
      3L
    )
  }
)

testthat::test_that(
  "assess_sjsdm_candidate_guardrails() exposes every failed rule",
  {
    data_tuning <-
      tibble::tibble(
        repeat_id = base::rep(1:2, 2L),
        candidate_id = base::rep(
          base::c("candidate", "reference"),
          each = 2L
        ),
        negative_log_likelihood_per_response = base::c(
          0.29,
          0.31,
          0.30,
          0.30
        ),
        auc_macro_test = base::c(0.68, 0.68, 0.70, 0.70),
        summary_status = "ok"
      )

    make_metrics <- function(source) {
      tidyr::crossing(
        repeat_id = 1:2,
        metric_id = base::c(
          "auc",
          "brier_score",
          "log_loss",
          "tjur_r2"
        )
      ) |>
        dplyr::mutate(
          prediction_source = "model",
          aggregation_id = "fold_macro",
          estimate = dplyr::case_when(
            .data[["metric_id"]] == "auc" & source == "candidate" ~ 0.65,
            .data[["metric_id"]] == "auc" ~ 0.70,
            .data[["metric_id"]] == "tjur_r2" &
              source == "candidate" ~ 0.04,
            .data[["metric_id"]] == "tjur_r2" ~ 0.05,
            .data[["metric_id"]] == "log_loss" &
              source == "candidate" ~ 0.32,
            .data[["metric_id"]] == "log_loss" ~ 0.30,
            .data[["metric_id"]] == "brier_score" &
              source == "candidate" ~ 0.11,
            TRUE ~ 0.10
          )
        )
    }

    res <-
      assess_sjsdm_candidate_guardrails(
        data_tuning_summary = data_tuning,
        data_candidate_repeat_metrics = make_metrics("candidate"),
        data_reference_repeat_metrics = make_metrics("reference"),
        candidate_id = "candidate",
        reference_candidate_id = "reference"
      )

    data_summary <-
      purrr::chuck(res, "data_guardrail_summary")

    testthat::expect_false(data_summary[["eligible"]])
    testthat::expect_equal(
      data_summary[["failed_guardrails"]],
      stringr::str_c(
        base::c(
          "tuning_nll_not_improved_every_repeat",
          "tuning_auc_deterioration",
          "independent_refit_deterioration",
          "scientific_tjur_gate_failed"
        ),
        collapse = ";"
      )
    )
    testthat::expect_equal(
      purrr::chuck(res, "data_tuning_repeat_comparison") |>
        dplyr::pull("nll_improvement"),
      base::c(0.01, -0.01)
    )
  }
)

testthat::test_that(
  "assess_sjsdm_candidate_guardrails() rejects incomplete repeat metrics",
  {
    data_tuning <-
      tidyr::crossing(
        repeat_id = 1:2,
        candidate_id = base::c("candidate", "reference")
      ) |>
      dplyr::mutate(
        negative_log_likelihood_per_response = 0.3,
        auc_macro_test = 0.7,
        summary_status = "ok"
      )

    data_metrics <-
      tidyr::crossing(
        repeat_id = 1:2,
        metric_id = base::c(
          "auc",
          "brier_score",
          "log_loss",
          "tjur_r2"
        )
      ) |>
      dplyr::mutate(
        prediction_source = "model",
        aggregation_id = "fold_macro",
        estimate = 0.1
      )

    data_incomplete <-
      data_metrics |>
      dplyr::filter(
        !(
          .data[["repeat_id"]] == 2L &
            .data[["metric_id"]] == "auc"
        )
      )

    testthat::expect_error(
      assess_sjsdm_candidate_guardrails(
        data_tuning_summary = data_tuning,
        data_candidate_repeat_metrics = data_incomplete,
        data_reference_repeat_metrics = data_metrics,
        candidate_id = "candidate",
        reference_candidate_id = "reference"
      ),
      "Every repeat must contain every guardrail metric"
    )
  }
)

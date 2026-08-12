testthat::test_that(
  "prepare_sjsdm_guardrail_tuning_candidate() validates repeat evidence",
  {
    res <-
      prepare_sjsdm_guardrail_tuning_candidate(
        data_tuning_summary = tibble::tibble(
          repeat_id = 1:2,
          candidate_id = "candidate_001",
          negative_log_likelihood_per_response = base::c(0.2, 0.3),
          auc_macro_test = base::c(0.7, 0.8),
          summary_status = "ok"
        ),
        selected_candidate_id = "candidate_001",
        suffix = "_candidate"
      )

    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "negative_log_likelihood_per_response_candidate",
        "auc_macro_test_candidate"
      )
    )
    testthat::expect_equal(base::nrow(res), 2L)
  }
)

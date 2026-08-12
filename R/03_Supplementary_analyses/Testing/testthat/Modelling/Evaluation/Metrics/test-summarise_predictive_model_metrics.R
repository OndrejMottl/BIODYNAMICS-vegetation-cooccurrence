testthat::test_that(
  "summarise_predictive_model_metrics() averages successful repeats",
  {
    data_result <-
      summarise_predictive_model_metrics(
        list_pooled_cv_evaluation = base::list(
          data_community_summary = tibble::tibble(
            metric_id = base::rep(
              base::c("tjur_r2", "auc", "log_loss"),
              times = 2L
            ),
            estimate = base::c(0.2, 0.7, 0.4, 0.4, 0.9, 0.6),
            metric_status = "ok"
          )
        )
      )

    testthat::expect_equal(
      dplyr::pull(data_result, predictive_tjur_r2_mean),
      0.3
    )
    testthat::expect_equal(
      dplyr::pull(data_result, predictive_auc_mean),
      0.8
    )
    testthat::expect_equal(
      dplyr::pull(data_result, predictive_log_loss_mean),
      0.5
    )
  }
)

testthat::test_that(
  "summarise_predictive_model_metrics() keeps missing metrics explicit",
  {
    data_result <-
      summarise_predictive_model_metrics(
        list_pooled_cv_evaluation = NULL
      )

    testthat::expect_true(base::all(base::is.na(data_result)))
    testthat::expect_named(
      data_result,
      base::c(
        "predictive_tjur_r2_mean",
        "predictive_auc_mean",
        "predictive_log_loss_mean"
      )
    )
  }
)

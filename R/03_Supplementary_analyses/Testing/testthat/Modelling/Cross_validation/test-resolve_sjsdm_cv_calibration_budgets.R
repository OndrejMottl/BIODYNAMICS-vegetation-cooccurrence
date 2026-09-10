testthat::test_that(
  "resolve_sjsdm_cv_calibration_budgets() propagates group maxima",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "regional",
        continent_id = "europe",
        resolution_id = "genus",
        scale_id = base::c("eu_r001", "eu_r002", "eu_r003")
      )
    data_accepted <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "regional",
        continent_id = "europe",
        resolution_id = "genus",
        scale_id = base::c("eu_r001", "eu_r002", "eu_r003"),
        selection_reason = base::c(
          "median_complexity",
          "maximum_complexity",
          "historical_outlier"
        ),
        budget_order = base::c(2L, 4L, 6L),
        n_iter_initial = base::c(1000L, 4000L, 16000L),
        n_iter_max = base::c(4000L, 16000L, 64000L),
        n_sampling = 200L,
        measured_seconds_per_fit = base::c(10, 40, 160),
        measured_seconds_per_epoch = base::c(0.01, 0.02, 0.03)
      )

    res <-
      resolve_sjsdm_cv_calibration_budgets(
        data_units = data_units,
        data_accepted = data_accepted
      )

    testthat::expect_equal(
      res[["cv_n_iter_initial"]],
      base::c(4000L, 4000L, 16000L)
    )
    testthat::expect_true(
      base::all(res[["cv_budget_status"]] == "calibrated")
    )
    testthat::expect_equal(
      res[["cv_budget_source_scale_id"]],
      base::c("eu_r002", "eu_r002", "eu_r003")
    )
    testthat::expect_equal(
      res[["cv_measured_seconds_per_fit"]],
      base::c(40, 40, 160)
    )
  }
)

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
        scale_id = "eu_r002",
        selection_reason = "maximum_complexity",
        budget_order = 4L,
        n_iter_initial = 4000L,
        n_iter_max = 16000L,
        n_sampling = 200L,
        measured_seconds_per_fit = 40,
        measured_seconds_per_epoch = 0.02
      )

    res <-
      resolve_sjsdm_cv_calibration_budgets(
        data_units = data_units,
        data_accepted = data_accepted
      )

    testthat::expect_equal(
      res[["cv_n_iter_initial"]],
      base::rep(4000L, 3L)
    )
    testthat::expect_true(
      base::all(res[["cv_budget_status"]] == "calibrated")
    )
    testthat::expect_equal(
      res[["cv_budget_source_scale_id"]],
      base::rep("eu_r002", 3L)
    )
    testthat::expect_equal(
      res[["cv_measured_seconds_per_fit"]],
      base::rep(40, 3L)
    )
    testthat::expect_equal(
      res[["cv_budget_assignment_scope"]],
      base::rep("exact_group", 3L)
    )
  }
)

testthat::test_that(
  "resolve_sjsdm_cv_calibration_budgets uses conservative tier fallback",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "regional",
        continent_id = c("europe", "asia"),
        resolution_id = "family",
        scale_id = c("eu_r001", "as_r001")
      )
    data_accepted <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "regional",
        continent_id = "europe",
        resolution_id = "family",
        scale_id = "eu_r001",
        selection_reason = "maximum_complexity",
        budget_order = 5L,
        n_iter_initial = 8000L,
        n_iter_max = 32000L,
        n_sampling = 200L
      )

    res <-
      resolve_sjsdm_cv_calibration_budgets(
        data_units = data_units,
        data_accepted = data_accepted
      )

    testthat::expect_equal(res[["cv_n_iter_initial"]], c(8000L, 8000L))
    testthat::expect_equal(
      res[["cv_budget_assignment_scope"]],
      c("exact_group", "tier_fallback")
    )
    testthat::expect_equal(
      res[["cv_budget_source_scale_id"]],
      c("eu_r001", "eu_r001")
    )
  }
)

testthat::test_that(
  "resolve_sjsdm_cv_calibration_budgets pools ineligible temporal profiles",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_temporal",
        tier_id = "continental",
        continent_id = c("europe", "asia"),
        resolution_id = "genus",
        scale_id = c("europe", "asia")
      )
    data_accepted <-
      tibble::tibble(
        analysis_id = "paleo_temporal",
        tier_id = "continental",
        continent_id = "europe",
        resolution_id = "genus",
        scale_id = "europe",
        selection_reason = "paleo_temporal_profile",
        budget_order = 4L,
        n_iter_initial = 4000L,
        n_iter_max = 16000L,
        n_sampling = 200L
      )

    res <-
      resolve_sjsdm_cv_calibration_budgets(
        data_units = data_units,
        data_accepted = data_accepted
      )

    testthat::expect_equal(
      res[["cv_budget_assignment_scope"]],
      c("own_profile", "tier_fallback")
    )
    testthat::expect_equal(res[["cv_n_iter_initial"]], c(4000L, 4000L))
  }
)

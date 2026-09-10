testthat::test_that(
  "select_sjsdm_cv_calibration_representatives is deterministic",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "regional",
        continent_id = "europe",
        resolution_id = "genus",
        scale_id = c("a", "b", "c", "outlier"),
        n_locations = c(10L, 20L, 30L, 15L),
        n_samples = c(100L, 200L, 300L, 150L),
        n_taxa = c(10L, 10L, 10L, 10L),
        n_iter = c(500L, 500L, 500L, 7000L),
        n_sampling = c(200L, 200L, 200L, 200L),
        n_early_stopping = c(20L, 20L, 20L, 20L),
        is_temporal = FALSE
      )

    res <-
      select_sjsdm_cv_calibration_representatives(data_units)

    testthat::expect_setequal(res[["scale_id"]], c("b", "c", "outlier"))
    testthat::expect_true(
      "historical_outlier" %in%
        res[res[["scale_id"]] == "outlier", "selection_reason"][[1L]]
    )
  }
)

testthat::test_that(
  "select_sjsdm_cv_calibration_representatives includes temporal profiles",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_temporal",
        tier_id = "continental",
        continent_id = c("europe", "america", "asia"),
        resolution_id = "genus",
        scale_id = c("europe", "america", "asia"),
        n_locations = 10L,
        n_samples = 100L,
        n_taxa = 10L,
        n_iter = 1000L,
        n_sampling = 150L,
        n_early_stopping = NA_integer_,
        is_temporal = TRUE
      )

    res <-
      select_sjsdm_cv_calibration_representatives(data_units)

    testthat::expect_setequal(
      res[["scale_id"]],
      c("europe", "america", "asia")
    )
    testthat::expect_true(
      base::all(stringr::str_detect(res[["selection_reason"]], "temporal"))
    )
  }
)

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
        is_temporal = FALSE,
        cv_strategy = c(
          base::rep("spatially_stratified_group_kfold", 3L),
          "none"
        ),
        effective_folds = c(5L, 5L, 5L, NA_integer_)
      )

    res <-
      select_sjsdm_cv_calibration_representatives(data_units)

    testthat::expect_identical(res[["scale_id"]], "c")
    testthat::expect_true(
      res[["selection_reason"]][[1L]] == "maximum_complexity"
    )
    testthat::expect_false(
      "outlier" %in% res[["scale_id"]]
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
        is_temporal = TRUE,
        cv_strategy = "spatially_stratified_group_kfold",
        effective_folds = 5L
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

testthat::test_that(
  "select_sjsdm_cv_calibration_representatives excludes infeasible maxima",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "modern_spatial",
        tier_id = "regional",
        continent_id = "asia",
        resolution_id = "family",
        scale_id = c("eligible", "infeasible"),
        n_locations = c(10L, 100L),
        n_samples = c(100L, 1000L),
        n_taxa = c(10L, 100L),
        n_iter = 1000L,
        n_sampling = 200L,
        n_early_stopping = 20L,
        is_temporal = FALSE,
        cv_strategy = c(
          "spatially_stratified_group_kfold",
          "none"
        ),
        effective_folds = c(5L, NA_integer_)
      )

    res <-
      select_sjsdm_cv_calibration_representatives(data_units)

    testthat::expect_identical(res[["scale_id"]], "eligible")
  }
)

testthat::test_that(
  "select_sjsdm_cv_calibration_representatives pools continents",
  {
    data_units <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "continental",
        continent_id = c("europe", "america", "asia"),
        resolution_id = "genus",
        scale_id = c("europe", "america", "asia"),
        n_locations = c(10L, 20L, 30L),
        n_samples = c(100L, 200L, 300L),
        n_taxa = c(10L, 20L, 30L),
        n_iter = 1000L,
        n_sampling = 200L,
        n_early_stopping = 20L,
        is_temporal = FALSE,
        cv_strategy = "spatially_stratified_group_kfold",
        effective_folds = 5L
      )

    res <-
      select_sjsdm_cv_calibration_representatives(data_units)

    testthat::expect_identical(res[["scale_id"]], "asia")
    testthat::expect_equal(base::nrow(res), 1L)
  }
)

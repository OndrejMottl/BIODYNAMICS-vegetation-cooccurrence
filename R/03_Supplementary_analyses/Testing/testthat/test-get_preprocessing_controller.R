testthat::test_that(
  "get_preprocessing_controller() returns NULL outside crew_mori backend",
  {
    withr::local_envvar(
      BIODYNAMICS_PREPROCESSING_BACKEND = NA,
      BIODYNAMICS_PREPROCESSING_WORKERS = NA
    )

    testthat::expect_null(get_preprocessing_controller())
  }
)

testthat::test_that(
  "get_preprocessing_controller() validates crew_mori worker count",
  {
    withr::local_envvar(
      BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
      BIODYNAMICS_PREPROCESSING_WORKERS = NA
    )

    testthat::expect_error(
      get_preprocessing_controller(),
      regexp = "BIODYNAMICS_PREPROCESSING_WORKERS"
    )

    withr::local_envvar(
      BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
      BIODYNAMICS_PREPROCESSING_WORKERS = "1.5"
    )

    testthat::expect_error(
      get_preprocessing_controller(),
      regexp = "positive integer"
    )

    withr::local_envvar(
      BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
      BIODYNAMICS_PREPROCESSING_WORKERS = "abc"
    )

    testthat::expect_error(
      get_preprocessing_controller(),
      regexp = "positive integer"
    )
  }
)

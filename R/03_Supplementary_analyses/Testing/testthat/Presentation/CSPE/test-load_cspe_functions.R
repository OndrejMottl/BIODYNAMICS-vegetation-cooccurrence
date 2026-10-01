testthat::test_that(
  "load_cspe_functions() loads the CSPE helper surface",
  {
    environment_cspe <-
      base::new.env(parent = base::globalenv())

    paths_loaded <-
      load_cspe_functions(envir = environment_cspe)

    testthat::expect_true(
      base::all(paths_loaded == base::sort(paths_loaded))
    )
    testthat::expect_true(
      base::exists(
        "load_results_snapshot",
        envir = environment_cspe,
        inherits = FALSE
      )
    )
    testthat::expect_true(
      base::exists(
        "save_prediction_animation",
        envir = environment_cspe,
        inherits = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_bes_functions() loads the BES helper surface",
  {
    environment_bes <-
      base::new.env(parent = base::globalenv())

    paths_loaded <-
      load_bes_functions(envir = environment_bes)

    testthat::expect_true(
      base::all(paths_loaded == base::sort(paths_loaded))
    )
    testthat::expect_true(
      base::exists(
        "load_results_snapshot",
        envir = environment_bes,
        inherits = FALSE
      )
    )
    testthat::expect_true(
      base::exists(
        "save_prediction_animation",
        envir = environment_bes,
        inherits = FALSE
      )
    )
  }
)

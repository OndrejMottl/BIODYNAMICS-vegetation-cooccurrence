testthat::test_that(
  "load_iavs_functions() sources the local helper surface deterministically",
  {
    environment_iavs <-
      base::new.env(parent = base::globalenv())

    paths_loaded <-
      load_iavs_functions(envir = environment_iavs)

    testthat::expect_true(
      base::all(paths_loaded == base::sort(paths_loaded))
    )
    testthat::expect_true(
      base::exists(
        "load_design_config",
        envir = environment_iavs,
        inherits = FALSE
      )
    )
    testthat::expect_true(
      base::exists(
        "save_prediction_animation",
        envir = environment_iavs,
        inherits = FALSE
      )
    )
  }
)

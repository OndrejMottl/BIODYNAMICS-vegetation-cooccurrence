testthat::test_that(
  "spatial synthesis uses explicit fitted and predictive performance fields",
  {
    path_synthesis <-
      here::here("R/02_Main_analyses/04_Synthesis/_components")

    vec_script_paths <-
      base::file.path(
        path_synthesis,
        base::c(
          "01_analyse_paleo_spatial_patterns.R",
          "02_analyse_modern_spatial_patterns.R",
          "03_compare_paleo_modern.R"
        )
      )

    vec_script_text <-
      vec_script_paths |>
      purrr::map_chr(
        ~ base::paste(base::readLines(.x, warn = FALSE), collapse = "\n")
      )

    testthat::expect_silent(
      purrr::walk(vec_script_paths, ~ base::parse(file = .x))
    )
    testthat::expect_true(
      base::all(stringr::str_detect(vec_script_text, "fitted_auc_mean"))
    )
    testthat::expect_true(
      base::all(stringr::str_detect(vec_script_text, "predictive_auc_mean"))
    )
    testthat::expect_false(
      base::any(stringr::str_detect(vec_script_text, "\\bauc_mean\\b"))
    )
    testthat::expect_match(
      vec_script_text[[3L]],
      "fitted_auc_delta_modern_minus_paleo"
    )
    testthat::expect_match(
      vec_script_text[[3L]],
      "predictive_auc_delta_modern_minus_paleo"
    )
  }
)

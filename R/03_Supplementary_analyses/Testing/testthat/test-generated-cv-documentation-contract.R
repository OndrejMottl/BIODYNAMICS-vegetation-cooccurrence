testthat::test_that(
  "generated CV documentation matches the current function inventory",
  {
    stale_paths <-
      base::c(
        here::here(
          "Documentation/Functions/run_predictive_ablation_cv.html"
        ),
        here::here(
          "Documentation/Functions/run_predictive_ablation_cv.pdf"
        ),
        here::here(
          "Documentation/Functions/run_predictive_ablation_cv.txt"
        ),
        here::here(
          paste0(
            "Documentation/Website/Documentation/Functions/",
            "run_predictive_ablation_cv.qmd"
          )
        ),
        here::here(
          paste0(
            "docs/Documentation/Website/Documentation/Functions/",
            "run_predictive_ablation_cv.html"
          )
        ),
        here::here(
          paste0(
            "docs/Documentation/Website/Documentation/Functions/",
            "apply_decomposition_scale_attributes.html"
          )
        )
      )

    testthat::expect_false(
      base::any(base::file.exists(stale_paths))
    )

    current_names <-
      base::c(
        "scale_predictors_with_training_attributes",
        "interpolate_mev_to_grid",
        "interpolate_st_mev_to_grid"
      )

    generated_paths <-
      base::c(
        base::file.path(
          here::here("Documentation/Functions"),
          base::paste0(
            base::rep(current_names, each = 3L),
            base::c(".html", ".pdf", ".txt")
          )
        ),
        base::file.path(
          here::here(
            "Documentation/Website/Documentation/Functions"
          ),
          base::paste0(current_names, ".qmd")
        ),
        base::file.path(
          here::here(
            "docs/Documentation/Website/Documentation/Functions"
          ),
          base::paste0(current_names, ".html")
        )
      )

    testthat::expect_true(
      base::all(base::file.exists(generated_paths))
    )
  }
)

testthat::test_that(
  "interpolation references document optional unscaled output",
  {
    interpolation_names <-
      base::c(
        "interpolate_mev_to_grid",
        "interpolate_st_mev_to_grid"
      )

    text_paths <-
      base::file.path(
        here::here("Documentation/Functions"),
        base::paste0(
          base::rep(interpolation_names, each = 2L),
          base::c(".html", ".txt")
        )
      )

    reference_text <-
      text_paths |>
      purrr::map_chr(
        ~ base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")
      )

    testthat::expect_true(
      base::all(
        stringr::str_detect(
          reference_text,
          "otherwise remain unscaled|unscaled interpolated values"
        )
      )
    )
  }
)

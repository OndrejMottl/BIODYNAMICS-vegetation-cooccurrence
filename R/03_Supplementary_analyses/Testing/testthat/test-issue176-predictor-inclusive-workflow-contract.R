testthat::test_that(
  "spatial synthesis publishes predictor-inclusive metrics",
  {
    vec_synthesis_files <-
      base::file.path(
        here::here(
          "R/02_Main_analyses/04_Synthesis/_components"
        ),
        base::c(
          "01_analyse_paleo_spatial_patterns.R",
          "02_analyse_modern_spatial_patterns.R"
        )
      )

    purrr::walk(
      .x = vec_synthesis_files,
      .f = ~ {
        text_script <-
          base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")

        testthat::expect_match(
          text_script,
          "R2_Nagelkerke_predictor_inclusive"
        )
        testthat::expect_match(
          text_script,
          "R2_Nagelkerke_predictor_inclusive_percentage"
        )
      }
    )
  }
)

testthat::test_that(
  "variance scripts publish overlapping figures and tables",
  {
    vec_plot_files <-
      base::file.path(
        here::here(
          "R/02_Main_analyses/05_Visualisation/_components"
        ),
        base::c(
          "03_plot_paleo_variance_partitioning.R",
          "04_plot_modern_variance_partitioning.R"
        )
      )

    purrr::walk2(
      .x = vec_plot_files,
      .y = base::c(1L, 2L),
      .f = ~ {
        text_script <-
          base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")

        testthat::expect_match(
          text_script,
          'sum_over_100_action = "ignore"'
        )
        testthat::expect_match(
          text_script,
          "plot_manuscript_predictor_inclusive_variance"
        )
        testthat::expect_match(
          text_script,
          "predictor_inclusive_unit_"
        )
        testthat::expect_match(
          text_script,
          "predictor_inclusive_summary_"
        )
        testthat::expect_equal(
          stringr::str_count(
            text_script,
            "save_manuscript_figure\\("
          ),
          .y
        )
      }
    )
  }
)

testthat::test_that(
  "temporal synthesis and plotting use predictor-inclusive variance",
  {
    file_synthesis <-
      here::here(
        paste0(
          "R/02_Main_analyses/04_Synthesis/_components/",
          "04_analyse_paleo_temporal_patterns.R"
        )
      )
    file_plot <-
      here::here(
        paste0(
          "R/02_Main_analyses/05_Visualisation/_components/",
          "07_plot_paleo_temporal_trajectories.R"
        )
      )
    text_synthesis <-
      base::readLines(file_synthesis, warn = FALSE) |>
      stringr::str_c(collapse = "\n")
    text_plot <-
      base::readLines(file_plot, warn = FALSE) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_match(
      text_synthesis,
      "data_anova_components_by_age"
    )
    testthat::expect_match(
      text_synthesis,
      "compute_predictor_inclusive_variance_components"
    )
    testthat::expect_match(
      text_synthesis,
      "R2_Nagelkerke_predictor_inclusive_percentage"
    )
    testthat::expect_match(
      text_plot,
      "predictor_inclusive_variance_component"
    )
    testthat::expect_match(
      text_plot,
      "domain percentages overlap and need not sum to 100%"
    )
    testthat::expect_match(
      text_plot,
      "paleo_temporal_trajectories_predictor_inclusive_"
    )
  }
)

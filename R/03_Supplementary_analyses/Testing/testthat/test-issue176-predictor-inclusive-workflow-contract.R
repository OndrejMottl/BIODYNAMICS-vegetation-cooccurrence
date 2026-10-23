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
      .y = base::c(2L, 2L),
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
          "plot_manuscript_spatial_variance"
        )
        testthat::expect_match(
          text_script,
          'percentage_source_column = "R2_Nagelkerke_percentage"'
        )
        testthat::expect_match(
          text_script,
          "summarise_spatial_variance_stack"
        )
        testthat::expect_match(
          text_script,
          "variance_partitioning_components_"
        )
        testthat::expect_match(
          text_script,
          "variance_partitioning_associations_"
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
  "overlapping totals do not alter the Shapley composition",
  {
    data_fractions <-
      tibble::tibble(
        age = 0,
        component = base::c(
          "Abiotic", "Associations", "Spatial", "Abiotic&Associations",
          "Abiotic&Spatial", "Associations&Spatial",
          "Abiotic&Associations&Spatial"
        ),
        R2_Nagelkerke = base::c(0.1, 0.2, 0.3, 0.04, 0.06, 0.08, 0.09)
      )
    data_shapley_before <-
      compute_shapley_variance_components(data_fractions)
    data_inclusive <-
      compute_predictor_inclusive_variance_components(data_fractions)
    data_shapley_after <-
      compute_shapley_variance_components(data_fractions)

    testthat::expect_identical(data_shapley_after, data_shapley_before)
    testthat::expect_equal(
      data_shapley_after[["R2_Nagelkerke_adjusted"]],
      base::c(0.18, 0.29, 0.4),
      tolerance = 1e-12
    )
    testthat::expect_gt(
      base::sum(data_inclusive[[
        "R2_Nagelkerke_predictor_inclusive_percentage"
      ]]),
      100
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

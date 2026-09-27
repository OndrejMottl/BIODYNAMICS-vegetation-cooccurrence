testthat::test_that(
  "stage 05 exposes seven ordered manuscript figure components",
  {
    path_root <-
      here::here("R/02_Main_analyses/05_Visualisation")
    file_master <-
      base::file.path(path_root, "01_run_visualisation.R")
    vec_expected_components <-
      base::c(
        "01_plot_paleo_spatial_association_atlas.R",
        "02_plot_paleo_spatial_association_summary.R",
        "03_plot_paleo_variance_partitioning.R",
        "04_plot_modern_variance_partitioning.R",
        "05_plot_matched_paleo_modern_comparison.R",
        "06_plot_functional_type_comparison.R",
        "07_plot_paleo_temporal_trajectories.R"
      )
    text_master <-
      base::readLines(file_master, warn = FALSE)
    text_master_collapsed <-
      stringr::str_c(text_master, collapse = "\n")
    vec_positions <-
      stringr::str_locate(
        text_master_collapsed,
        stringr::fixed(vec_expected_components)
      )[, "start"]

    testthat::expect_true(base::all(base::is.finite(vec_positions)))
    testthat::expect_true(
      base::all(base::diff(vec_positions) > 0)
    )
    testthat::expect_setequal(
      base::list.files(
        base::file.path(path_root, "_components"),
        pattern = "^[0-9]{2}_.*[.]R$"
      ),
      vec_expected_components
    )
  }
)

testthat::test_that(
  "each stage 05 component writes one canonical manuscript figure",
  {
    vec_component_files <-
      base::list.files(
        here::here(
          "R/02_Main_analyses/05_Visualisation/_components"
        ),
        pattern = "^[0-9]{2}_.*[.]R$",
        full.names = TRUE
      )

    purrr::walk(
      vec_component_files,
      ~ {
        text_component <-
          base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")
        testthat::expect_equal(
          stringr::str_count(
            text_component,
            "save_manuscript_figure\\("
          ),
          1L,
          info = .x
        )
        testthat::expect_false(
          stringr::str_detect(
            text_component,
            "targets::tar_(read|load)"
          ),
          info = .x
        )
      }
    )
  }
)

testthat::test_that(
  "stage 05 documents canonical output and plot-data contracts",
  {
    text_readme <-
      base::readLines(
        here::here(
          "R/02_Main_analyses/05_Visualisation/README.md"
        ),
        warn = FALSE
      ) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_match(text_readme, "600-dpi TIFF")
    testthat::expect_match(text_readme, "plot-ready tables")
    testthat::expect_match(text_readme, "unexpected_error")
    testthat::expect_match(text_readme, "modern minus paleo")
  }
)

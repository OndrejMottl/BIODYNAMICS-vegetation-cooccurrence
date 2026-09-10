testthat::test_that(
  "every main-analysis script documents its execution contract",
  {
    vec_scripts <-
      base::list.files(
        here::here("R/02_Main_analyses"),
        pattern = "[.]R$",
        recursive = TRUE,
        full.names = TRUE
      )
    testthat::expect_length(vec_scripts, 36L)

    list_script_lines <-
      vec_scripts |>
      rlang::set_names() |>
      purrr::map(base::readLines, warn = FALSE)

    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_script_lines,
          ~ base::any(.x == "#                 Vegetation Co-occurrence")
        )
      ),
      info = "Every script requires the project header."
    )
    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_script_lines,
          ~ base::any(.x == "# Workflow contract:")
        )
      ),
      info = "Every script requires an in-file workflow contract."
    )
    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_script_lines,
          ~ base::any(stringr::str_starts(.x, "# 0. "))
        )
      ),
      info = "Every script requires a numbered setup section."
    )
    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_script_lines,
          ~ base::all(base::nchar(.x) <= 80L)
        )
      ),
      info = "Main-analysis R source must remain within 80 columns."
    )

    text_main_readme <-
      base::readLines(
        here::here("R/02_Main_analyses/README.md"),
        warn = FALSE
      ) |>
      base::paste(collapse = "\n")
    testthat::expect_match(
      text_main_readme,
      "01_Preparation/01_run_preparation.R",
      fixed = TRUE
    )
    testthat::expect_match(
      text_main_readme,
      "05_Visualisation/01_run_visualisation.R",
      fixed = TRUE
    )
    testthat::expect_false(
      base::any(
        stringr::str_detect(
          base::unlist(list_script_lines),
          "SJSMD_PREPARE_CV_FOLDS_ONLY"
        )
      )
    )
  }
)

testthat::test_that(
  "main analyses expose exactly five ordered master stages",
  {
    path_main <- here::here("R/02_Main_analyses")
    vec_expected_stages <- base::c(
      "01_Preparation",
      "02_Model_calibration",
      "03_Model_fitting",
      "04_Synthesis",
      "05_Visualisation"
    )
    vec_actual_stages <-
      base::list.dirs(
        path = path_main,
        full.names = FALSE,
        recursive = FALSE
      ) |>
      base::sort()

    testthat::expect_identical(vec_actual_stages, vec_expected_stages)

    vec_master_files <-
      base::file.path(path_main, vec_expected_stages) |>
      purrr::map(
        ~ base::list.files(
          path = .x,
          pattern = "^01_run_.*[.]R$",
          recursive = FALSE,
          full.names = FALSE
        )
      )

    testthat::expect_true(
      base::all(purrr::map_int(vec_master_files, base::length) == 1L)
    )
    testthat::expect_identical(
      base::unlist(vec_master_files, use.names = FALSE),
      base::c(
        "01_run_preparation.R",
        "01_run_model_calibration.R",
        "01_run_model_fitting.R",
        "01_run_synthesis.R",
        "01_run_visualisation.R"
      )
    )
  }
)

testthat::test_that(
  "preparation attempts every component before reporting failures",
  {
    text_master <-
      readr::read_file(
        here::here(
          "R/02_Main_analyses/01_Preparation/",
          "01_run_preparation.R"
        )
      )

    testthat::expect_match(
      text_master,
      "continue_on_error = TRUE",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "downstream masters name the exact required prior-stage command",
  {
    vec_master_paths <- base::file.path(
      here::here("R/02_Main_analyses"),
      base::c(
        paste0(
          "02_Model_calibration/_components/",
          "01_build_sjsdm_cv_calibration_inventory.R"
        ),
        "03_Model_fitting/01_run_model_fitting.R",
        "04_Synthesis/01_run_synthesis.R",
        "05_Visualisation/01_run_visualisation.R"
      )
    )
    vec_required_scripts <- base::c(
      "01_Preparation/01_run_preparation.R",
      "02_Model_calibration/01_run_model_calibration.R",
      "03_Model_fitting/01_run_model_fitting.R",
      "04_Synthesis/01_run_synthesis.R"
    )
    purrr::walk2(
      vec_master_paths,
      vec_required_scripts,
      ~ testthat::expect_match(
        readr::read_file(.x) |>
          stringr::str_remove_all("[[:space:]\"',]"),
        .y,
        fixed = TRUE
      )
    )
  }
)

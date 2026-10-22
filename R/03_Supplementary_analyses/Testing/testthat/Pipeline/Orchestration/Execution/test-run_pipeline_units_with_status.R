testthat::test_that(
  "run_pipeline_units_with_status() retains every unit outcome",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["scale_ids"]] <-
      base::character()

    run_pipeline_function <- function(
        sel_script,
        store_suffix,
        prebuild_interpolation) {
      environment_calls[["scale_ids"]] <-
        base::c(
          environment_calls[["scale_ids"]],
          store_suffix
        )

      testthat::expect_identical(sel_script, "pipeline.R")
      testthat::expect_true(prebuild_interpolation)

      if (
        base::identical(store_suffix, "unit_b")
      ) {
        base::stop("unit b failed")
      }

      base::invisible(NULL)
    }

    res <-
      testthat::expect_message(
        run_pipeline_units_with_status(
          scale_ids = base::c("unit_a", "unit_b", "unit_c"),
          sel_script = "pipeline.R",
          run_pipeline_function = run_pipeline_function,
          progress = FALSE,
          prebuild_interpolation = TRUE
        ),
        "unit_b.*unit b failed"
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_named(
      res,
      base::c("scale_id", "pipeline_status", "error_message")
    )
    testthat::expect_identical(
      res[["scale_id"]],
      base::c("unit_a", "unit_b", "unit_c")
    )
    testthat::expect_identical(
      res[["pipeline_status"]],
      base::c("ok", "error", "ok")
    )
    testthat::expect_identical(
      res[["error_message"]],
      base::c(NA_character_, "unit b failed", NA_character_)
    )
    testthat::expect_identical(
      environment_calls[["scale_ids"]],
      base::c("unit_a", "unit_b", "unit_c")
    )
  }
)

testthat::test_that(
  "run_pipeline_units_with_status() validates orchestration inputs",
  {
    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = base::c("unit_a", "unit_a"),
        sel_script = "pipeline.R",
        run_pipeline_function = base::identity
      ),
      "scale_ids"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = base::c("a.R", "b.R"),
        run_pipeline_function = base::identity
      ),
      "sel_script"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = "not a function"
      ),
      "run_pipeline_function"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = function(...) NULL,
        progress = FALSE,
        "unnamed argument"
      ),
      "must be named"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = function(...) NULL,
        progress = FALSE,
        store_suffix = "replacement"
      ),
      "store_suffix"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = function(...) NULL,
        progress = FALSE,
        sel_script = "replacement.R"
      ),
      "sel_script"
    )

    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = function(...) NULL,
        verbose = "yes"
      ),
      "verbose"
    )
  }
)

testthat::test_that(
  "run_pipeline_units_with_status() supports quiet execution",
  {
    testthat::expect_no_message(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        run_pipeline_function = function(...) NULL,
        progress = FALSE,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "spatial fitting components use the unit failure policy",
  {
    runner_paths <-
      here::here(
        "R/02_Main_analyses/03_Model_fitting/_components",
        base::c(
          "01_fit_paleo_spatial_continental.R",
          "02_fit_paleo_spatial_regional.R",
          "03_fit_paleo_spatial_local.R",
          "04_fit_modern_spatial_continental.R",
          "05_fit_modern_spatial_regional.R",
          "06_fit_modern_spatial_local.R"
        )
      )

    runner_text <-
      runner_paths |>
      purrr::map_chr(
        .f = ~ base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")
      )

    testthat::expect_true(
      base::all(
        stringr::str_count(
          runner_text,
          "run_pipeline_units_with_status\\("
        ) == 1L
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          "data_pipeline_status <-"
        )
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          "target_names = vec_tuning_target_names"
        )
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          "SJSMD_PREPARE_CV_FOLDS_ONLY"
        )
      ) == FALSE
    )
    testthat::expect_true(
      base::all(
        stringr::str_count(
          runner_text,
          "run_sjsdm_cv_preparation_sequence\\("
        ) == 0L
      )
    )
  }
)

testthat::test_that(
  "run_pipeline_units_with_status() skips proven infeasible units",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())
    environment_calls[["scale_ids"]] <- base::character()

    run_pipeline_function <- function(sel_script, store_suffix) {
      environment_calls[["scale_ids"]] <-
        base::c(environment_calls[["scale_ids"]], store_suffix)
      base::invisible(NULL)
    }

    res <-
      run_pipeline_units_with_status(
        scale_ids = base::c("unit_a", "unit_b", "unit_c"),
        sel_script = "pipeline.R",
        expected_infeasible_scale_ids = "unit_b",
        run_pipeline_function = run_pipeline_function,
        progress = FALSE,
        verbose = FALSE
      )

    testthat::expect_identical(
      res[["pipeline_status"]],
      base::c("ok", "expected_infeasible", "ok")
    )
    testthat::expect_identical(
      environment_calls[["scale_ids"]],
      base::c("unit_a", "unit_c")
    )
    testthat::expect_true(base::is.na(res[["error_message"]][[2L]]))
    testthat::expect_error(
      run_pipeline_units_with_status(
        scale_ids = "unit_a",
        sel_script = "pipeline.R",
        expected_infeasible_scale_ids = "unknown",
        run_pipeline_function = run_pipeline_function,
        progress = FALSE
      ),
      "expected_infeasible_scale_ids"
    )
  }
)

testthat::test_that(
  "temporal preparation components cannot fit models",
  {
    runner_paths <-
      here::here(
        "R/02_Main_analyses/01_Preparation/_components",
        base::c(
          "07_prepare_paleo_temporal_europe.R",
          "08_prepare_paleo_temporal_america.R",
          "09_prepare_paleo_temporal_asia.R"
        )
      )
    runner_text <-
      runner_paths |>
      purrr::map_chr(
        .f = ~ base::readLines(.x, warn = FALSE) |>
          stringr::str_c(collapse = "\n")
      )

    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          stringr::fixed("run_sjsdm_cv_preparation_sequence(")
        )
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_count(
          runner_text,
          "run_sjsdm_tuning_sequence\\("
        ) == 0L
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          runner_text,
          "run_pipeline\\("
        )
      ) == FALSE
    )
  }
)
testthat::test_that("Unit status preserves structured data infeasibility", {
  data_result <-
    run_pipeline_units_with_status(
      scale_ids = "am_r007_l004", sel_script = "pipeline.R",
      progress = FALSE, verbose = FALSE,
      run_pipeline_function = function(...) {
        rlang::abort(message = "No supported spatial basis",
          class = "sjsdm_unit_expected_infeasible")
      }
    )
  testthat::expect_identical(data_result[["pipeline_status"]],
    "expected_infeasible")
  testthat::expect_match(data_result[["error_message"]], "No supported")
})
testthat::test_that("All spatial components block unexpected unit failures", {
  vec_scripts <-
    fs::dir_ls(path = here::here(
      "R/02_Main_analyses/03_Model_fitting/_components"
    ), regexp = "0[1-6]_fit_.*[.]R$")
  for (path_script in vec_scripts) {
    list_guards <-
      base::parse(file = path_script) |>
      base::as.list() |>
      purrr::keep(.p = ~ base::is.call(.x) &&
        base::identical(.x[[1L]], base::as.name("if")) &&
        stringr::str_detect(
          stringr::str_c(base::deparse(.x[[2L]]), collapse = ""),
          "data_pipeline_status"))
    testthat::expect_length(list_guards, 1L)
    if (base::length(list_guards) == 1L) {
      environment_status <-
        base::new.env(parent = base::globalenv())
      environment_status[["data_pipeline_status"]] <-
        tibble::tibble(pipeline_status = "error")
      environment_status[["file_status"]] <- "unit_status.csv"
      testthat::expect_error(
        base::eval(expr = list_guards[[1L]], envir = environment_status),
        regexp = "unexpected unit failures"
      )
      environment_status[["data_pipeline_status"]] <-
        tibble::tibble(pipeline_status = "expected_infeasible")
      testthat::expect_no_error(
        base::eval(expr = list_guards[[1L]], envir = environment_status)
      )
    }
  }
})
testthat::test_that("unit fitting honors resolution-aware requests", {
  list_calls <- base::list()
  res <-
    run_pipeline_units_with_status(scale_ids = base::c("a", "b"),
      sel_script = "pipeline.R", progress = FALSE, verbose = FALSE,
      unit_target_names = base::list(a = "mod_jsdm_family",
        b = base::character()),
      run_pipeline_function = function(store_suffix, target_names, ...) {
        list_calls[[store_suffix]] <<- target_names
      })
  testthat::expect_identical(list_calls, base::list(a = "mod_jsdm_family"))
  testthat::expect_identical(res[["pipeline_status"]],
    base::c("ok", "expected_infeasible"))
})

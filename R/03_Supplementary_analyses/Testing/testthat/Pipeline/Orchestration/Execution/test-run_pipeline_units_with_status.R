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

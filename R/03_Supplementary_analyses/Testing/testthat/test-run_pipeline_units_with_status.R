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
  }
)

testthat::test_that(
  "spatial runners use the explicit two-stage failure policy",
  {
    runner_paths <-
      here::here(
        base::c(
          base::rep(
            "R/02_Main_analyses/01_Spatial/01_Paleo/01_Runners",
            3L
          ),
          base::rep(
            "R/02_Main_analyses/01_Spatial/02_Modern/01_Runners",
            3L
          )
        ),
        base::c(
          "01_run_spatial_continental.R",
          "02_run_spatial_regional.R",
          "03_run_spatial_local.R",
          "01_run_modern_continental.R",
          "02_run_modern_regional.R",
          "03_run_modern_local.R"
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
          "This stage is fail-fast because tier selection requires"
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
  }
)

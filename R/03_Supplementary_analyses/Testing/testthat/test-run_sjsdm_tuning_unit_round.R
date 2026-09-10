testthat::test_that(
  "run_sjsdm_tuning_unit_round() sets the cumulative round",
  {
    captured_round <- NA_character_
    run_sjsdm_tuning_unit_round(
      round_id = 2L,
      unit_pipeline = "unit.R",
      tuning_target_names = "summary",
      run_pipeline_function = function(...) {
        captured_round <<-
          base::Sys.getenv("SJSMD_TUNING_MAX_ROUND")
      }
    )
    testthat::expect_identical(captured_round, "2")
  }
)

testthat::test_that(
  "run_sjsdm_tuning_unit_round() continues after a failed unit",
  {
    vec_calls <- base::character()
    res <-
      testthat::expect_message(
        run_sjsdm_tuning_unit_round(
          round_id = 1L,
          unit_pipeline = "unit.R",
          tuning_target_names = "summary",
          unit_store_suffixes = base::c("unit_a", "unit_b"),
          run_pipeline_function = function(store_suffix, ...) {
            vec_calls <<- base::c(vec_calls, store_suffix)
            if (
              store_suffix == "unit_a"
            ) {
              base::stop("not enough taxa")
            }
          }
        ),
        "Skipping failed tuning unit unit_a"
      )

    testthat::expect_identical(vec_calls, base::c("unit_a", "unit_b"))
    testthat::expect_identical(
      res[["pipeline_status"]],
      base::c("error", "ok")
    )
    testthat::expect_identical(
      res[["error_message"]],
      base::c("not enough taxa", NA_character_)
    )
  }
)

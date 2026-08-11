testthat::test_that(
  "run_sjsdm_tuning_unit_round() sets the cumulative round",
  {
    captured_round <- NA_character_
    run_sjsdm_tuning_unit_round(
      round_id = 2L,
      unit_pipeline = "unit.R",
      tuning_target_names = "summary",
      run_pipeline_function = function(...) {
        captured_round <<- base::Sys.getenv("SJSMD_TUNING_MAX_ROUND")
      }
    )
    testthat::expect_identical(captured_round, "2")
  }
)

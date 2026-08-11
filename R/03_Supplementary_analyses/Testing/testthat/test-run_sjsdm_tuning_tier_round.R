testthat::test_that(
  "run_sjsdm_tuning_tier_round() requests an explicit survivor target",
  {
    captured_target <- NULL
    run_sjsdm_tuning_tier_round(
      tuning_strategy = "staged",
      tier_target_name = "survivor_1",
      run_pipeline_function = function(target_names, ...) {
        captured_target <<- target_names
      }
    )
    testthat::expect_identical(captured_target, "survivor_1")
  }
)

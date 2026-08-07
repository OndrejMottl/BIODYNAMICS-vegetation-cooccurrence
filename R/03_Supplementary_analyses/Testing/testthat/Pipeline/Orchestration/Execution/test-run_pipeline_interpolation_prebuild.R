testthat::test_that(
  "run_pipeline_interpolation_prebuild() validates worker count",
  {
    testthat::expect_error(
      run_pipeline_interpolation_prebuild(
        pipeline_script = "pipeline.R",
        pipeline_store = "targets",
        workers = 0L
      ),
      "positive integer"
    )
  }
)

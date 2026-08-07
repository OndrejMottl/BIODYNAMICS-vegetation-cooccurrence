testthat::test_that(
  "build_pipeline_progress_monitor_server() returns a server function",
  {
    monitor_server <-
      build_pipeline_progress_monitor_server(
        monitor_id = "watch",
        path_monitor_config = "targets.yaml",
        flag_refresh_automatically = TRUE
      )

    testthat::expect_true(base::is.function(monitor_server))
  }
)

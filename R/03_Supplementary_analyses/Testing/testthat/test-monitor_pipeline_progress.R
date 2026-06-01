testthat::test_that(
  "monitor_pipeline_progress() resolves a non-spatial store",
  {
    list_config_call <- NULL
    list_ui_call <- NULL

    testthat::local_mocked_bindings(
      dir_exists = function(path) TRUE,
      .package = "fs"
    )

    testthat::local_mocked_bindings(
      tar_config_set = function(script, store, config, ...) {
        list_config_call <<-
          base::list(
            script = script,
            store = store,
            config = config
          )
        base::invisible(NULL)
      },
      tar_watch_ui = function(...) {
        list_ui_call <<-
          base::list(...)
        shiny::fluidPage()
      },
      tar_watch_server = function(...) base::invisible(NULL),
      .package = "targets"
    )

    testthat::local_mocked_bindings(
      shinyApp = function(ui, server, ...) base::invisible(NULL),
      .package = "shiny"
    )

    monitor_pipeline_progress(
      sel_script = "R/Pipelines/pipeline_paleo_core.R",
      sel_config = "project_cz_paleo",
      verbose = FALSE
    )

    testthat::expect_equal(
      purrr::chuck(list_config_call, "store"),
      here::here("Data/targets/cz_paleo", "pipeline_paleo_core")
    )
    testthat::expect_equal(
      purrr::chuck(list_config_call, "script"),
      here::here("R/Pipelines/pipeline_paleo_core.R")
    )
    testthat::expect_true(
      base::startsWith(
        purrr::chuck(list_config_call, "config"),
        base::tempdir()
      )
    )
    testthat::expect_true(
      purrr::chuck(list_ui_call, "targets_only")
    )
    testthat::expect_false(
      purrr::chuck(list_ui_call, "outdated")
    )
  }
)

testthat::test_that(
  "monitor_pipeline_progress() resolves a suffixed spatial store",
  {
    sel_store <- NULL

    testthat::local_mocked_bindings(
      dir_exists = function(path) TRUE,
      .package = "fs"
    )

    testthat::local_mocked_bindings(
      tar_config_set = function(script, store, config, ...) {
        sel_store <<- store
        base::invisible(NULL)
      },
      tar_watch_ui = function(...) shiny::fluidPage(),
      tar_watch_server = function(...) base::invisible(NULL),
      .package = "targets"
    )

    testthat::local_mocked_bindings(
      shinyApp = function(ui, server, ...) base::invisible(NULL),
      .package = "shiny"
    )

    monitor_pipeline_progress(
      sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
      sel_config = "project_paleo_spatial_continental",
      store_suffix = "europe",
      verbose = FALSE
    )

    testthat::expect_equal(
      sel_store,
      here::here(
        "Data/targets/paleo_spatial_continental",
        "europe",
        "pipeline_paleo_spatial_resolution"
      )
    )
  }
)

testthat::test_that(
  "monitor_pipeline_progress() validates selections and controls",
  {
    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "missing_pipeline.R",
        sel_config = "project_cz_paleo"
      ),
      regexp = "does not exist"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "missing_config"
      ),
      regexp = "does not exist in config.yml"
    )

    testthat::local_mocked_bindings(
      dir_exists = function(path) FALSE,
      .package = "fs"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo"
      ),
      regexp = "targets store does not exist"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo",
        sel_initial_display = "invalid"
      ),
      regexp = "sel_initial_display"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo",
        flag_refresh_automatically = "no"
      ),
      regexp = "flag_refresh_automatically"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo",
        verbose = "yes"
      ),
      regexp = "verbose"
    )

    testthat::expect_error(
      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo",
        seconds_refresh = Inf
      ),
      regexp = "seconds_refresh"
    )
  }
)

testthat::test_that(
  "monitor_pipeline_progress() supports silent dashboard construction",
  {
    flag_message_sent <- FALSE
    list_ui_call <- NULL

    testthat::local_mocked_bindings(
      dir_exists = function(path) TRUE,
      .package = "fs"
    )

    testthat::local_mocked_bindings(
      tar_config_set = function(...) base::invisible(NULL),
      tar_watch_ui = function(...) {
        list_ui_call <<-
          base::list(...)
        shiny::fluidPage()
      },
      tar_watch_server = function(...) base::invisible(NULL),
      .package = "targets"
    )

    testthat::local_mocked_bindings(
      cli_inform = function(...) {
        flag_message_sent <<- TRUE
        base::invisible(NULL)
      },
      .package = "cli"
    )

    testthat::local_mocked_bindings(
      shinyApp = function(ui, server, ...) base::invisible(NULL),
      .package = "shiny"
    )

    monitor_pipeline_progress(
      sel_script = "R/Pipelines/pipeline_paleo_core.R",
      sel_config = "project_cz_paleo",
      seconds_refresh = 20,
      sel_initial_display = "progress",
      verbose = FALSE
    )

    testthat::expect_false(flag_message_sent)
    testthat::expect_equal(
      purrr::chuck(list_ui_call, "seconds"),
      20
    )
    testthat::expect_equal(
      purrr::chuck(list_ui_call, "display"),
      "progress"
    )
  }
)

testthat::test_that(
  "monitor_pipeline_progress() pauses refresh at server startup",
  {
    monitor_server <- NULL
    flag_pause_sent <- FALSE

    testthat::local_mocked_bindings(
      dir_exists = function(path) TRUE,
      .package = "fs"
    )

    testthat::local_mocked_bindings(
      tar_config_set = function(...) base::invisible(NULL),
      tar_watch_ui = function(...) shiny::fluidPage(),
      tar_watch_server = function(...) base::invisible(NULL),
      .package = "targets"
    )

    testthat::local_mocked_bindings(
      updateMaterialSwitch = function(session, inputId, value, ...) {
        flag_pause_sent <<-
          base::identical(value, FALSE)
        base::invisible(NULL)
      },
      .package = "shinyWidgets"
    )

    capture_monitor_server <- function() {
      testthat::local_mocked_bindings(
        shinyApp = function(ui, server, ...) {
          monitor_server <<- server
          base::invisible(NULL)
        },
        .package = "shiny"
      )

      monitor_pipeline_progress(
        sel_script = "R/Pipelines/pipeline_paleo_core.R",
        sel_config = "project_cz_paleo",
        flag_refresh_automatically = FALSE,
        verbose = FALSE
      )
    }

    capture_monitor_server()

    base::suppressWarnings(
      shiny::testServer(
        monitor_server,
        {
          session$flushReact()
        }
      )
    )

    testthat::expect_true(flag_pause_sent)
  }
)

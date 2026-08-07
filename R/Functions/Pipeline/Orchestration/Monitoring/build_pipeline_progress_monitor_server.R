#' @title Build a Pipeline Progress Monitor Server
#' @description
#' Builds the Shiny server function used by the targets progress monitor.
#' @param monitor_id
#' Single character string identifying the targets watch module.
#' @param path_monitor_config
#' Path to the temporary targets configuration file.
#' @param flag_refresh_automatically
#' Logical indicating whether automatic refresh remains enabled at startup.
#' @return
#' A Shiny server function.
#' @export
build_pipeline_progress_monitor_server <- function(
    monitor_id,
    path_monitor_config,
    flag_refresh_automatically) {
  assertthat::assert_that(
    base::is.character(monitor_id) &&
      base::length(monitor_id) == 1L &&
      base::nzchar(monitor_id),
    msg = "`monitor_id` must be one non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(path_monitor_config) &&
      base::length(path_monitor_config) == 1L &&
      base::nzchar(path_monitor_config),
    msg = "`path_monitor_config` must be one non-empty character string."
  )

  assertthat::assert_that(
    assertthat::is.flag(flag_refresh_automatically),
    msg = "`flag_refresh_automatically` must be `TRUE` or `FALSE`."
  )

  res <-
    function(input, output, session) {
      if (
        base::isFALSE(flag_refresh_automatically)
      ) {
        session[["onFlushed"]](
          function() {
            shinyWidgets::updateMaterialSwitch(
              session = session,
              inputId = shiny::NS(monitor_id)("watch"),
              value = FALSE
            )
          },
          once = TRUE
        )
      }

      targets::tar_watch_server(
        id = monitor_id,
        config = path_monitor_config,
        project = "main"
      )
    }

  return(res)
}

#' @title Monitor Pipeline Progress
#' @description
#' Opens the official `{targets}` dashboard for a pipeline target store.
#' @param sel_script
#' Path to the pipeline script, relative to the project root or absolute.
#' @param sel_config
#' Configuration key in `config.yml` whose `target_store` contains the
#' selected pipeline output.
#' @param store_suffix
#' Optional nested target store identifier inserted between `target_store`
#' and the pipeline script name, such as `"europe"` or `"eu_r005_l014"`.
#' @param seconds_refresh
#' Positive finite refresh interval in seconds. Used only when automatic
#' refresh is enabled in the dashboard. Default is `10`.
#' @param sel_initial_display
#' Initial official `{targets}` dashboard tab. One of `"summary"`,
#' `"branches"`, `"progress"`, `"graph"`, or `"about"`.
#' @param flag_refresh_automatically
#' Logical indicating whether dashboard periodic refresh starts enabled.
#' Default is `FALSE`.
#' @param verbose
#' Logical indicating whether to display launch information. Default is
#' `TRUE`.
#' @return
#' No return value. The dashboard runs in the foreground until stopped.
#' @details
#' The target store is resolved using the same layout as [run_pipeline()]:
#' `{target_store}/{pipeline_name}/` when `store_suffix` is `NULL`, and
#' `{target_store}/{store_suffix}/{pipeline_name}/` otherwise. The app
#' always uses `targets_only = TRUE` and `outdated = FALSE` to keep
#' monitoring fast. Stop a running monitor with `Ctrl+C`.
#' @examples
#' \dontrun{
#' monitor_pipeline_progress(
#'   sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
#'   sel_config = "project_paleo_spatial_continental",
#'   store_suffix = "europe"
#' )
#'
#' monitor_pipeline_progress(
#'   sel_script = "R/Pipelines/pipeline_paleo_core.R",
#'   sel_config = "project_cz_paleo"
#' )
#' }
#' @seealso
#'   [run_pipeline()],
#'   [targets::tar_watch_ui()],
#'   [targets::tar_watch_server()]
#' @export
monitor_pipeline_progress <- function(
    sel_script,
    sel_config,
    store_suffix = NULL,
    seconds_refresh = 10,
    sel_initial_display = "branches",
    flag_refresh_automatically = FALSE,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(sel_script) &&
      base::length(sel_script) == 1L &&
      !base::is.na(sel_script) &&
      base::nzchar(sel_script),
    msg = "sel_script must be a single non-empty character string."
  )

  sel_script_path <-
    here::here(sel_script)

  assertthat::assert_that(
    base::file.exists(sel_script_path),
    msg = stringr::str_glue(
      "The specified pipeline script does not exist: {sel_script}."
    )
  )

  assertthat::assert_that(
    base::is.character(sel_config) &&
      base::length(sel_config) == 1L &&
      !base::is.na(sel_config) &&
      base::nzchar(sel_config),
    msg = "sel_config must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.null(store_suffix) ||
      (
        base::is.character(store_suffix) &&
          base::length(store_suffix) == 1L &&
          !base::is.na(store_suffix)
      ),
    msg = "store_suffix must be NULL or a single character string."
  )

  assertthat::assert_that(
    base::is.numeric(seconds_refresh) &&
      base::length(seconds_refresh) == 1L &&
      base::is.finite(seconds_refresh) &&
      seconds_refresh >= 1,
    msg = "seconds_refresh must be a single finite number of at least 1."
  )

  vec_displays <-
    base::c("summary", "branches", "progress", "graph", "about")

  assertthat::assert_that(
    base::is.character(sel_initial_display) &&
      base::length(sel_initial_display) == 1L &&
      !base::is.na(sel_initial_display) &&
      sel_initial_display %in% vec_displays,
    msg = stringr::str_glue(
      "sel_initial_display must be one of: ",
      "{stringr::str_c(vec_displays, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    assertthat::is.flag(flag_refresh_automatically),
    msg = stringr::str_c(
      "flag_refresh_automatically must be a single logical value",
      " (TRUE or FALSE)."
    )
  )

  assertthat::assert_that(
    assertthat::is.flag(verbose),
    msg = "verbose must be a single logical value (TRUE or FALSE)."
  )

  path_config <-
    here::here("config.yml")

  list_configs <-
    yaml::read_yaml(
      file = path_config,
      eval.expr = FALSE
    )

  assertthat::assert_that(
    sel_config %in% base::names(list_configs),
    msg = stringr::str_glue(
      "Configuration '{sel_config}' does not exist in config.yml."
    )
  )

  sel_target_store <-
    config::get(
      value = "target_store",
      config = sel_config,
      file = path_config,
      use_parent = FALSE
    )

  assertthat::assert_that(
    base::is.character(sel_target_store) &&
      base::length(sel_target_store) == 1L &&
      base::nzchar(sel_target_store),
    msg = stringr::str_glue(
      "Configuration '{sel_config}' does not define target_store."
    )
  )

  sel_pipeline_name <-
    stringr::str_remove(
      string = base::basename(sel_script_path),
      pattern = "\\.R$"
    )

  sel_store_path <-
    if (
      base::is.null(store_suffix)
    ) {
      here::here(
        sel_target_store,
        sel_pipeline_name
      )
    } else {
      here::here(
        sel_target_store,
        store_suffix,
        sel_pipeline_name
      )
    }

  assertthat::assert_that(
    fs::dir_exists(sel_store_path),
    msg = stringr::str_glue(
      "The selected targets store does not exist: {sel_store_path}."
    )
  )

  path_monitor_config <-
    base::tempfile(
      pattern = "targets_watch_",
      fileext = ".yaml"
    )

  base::on.exit(
    base::unlink(path_monitor_config),
    add = TRUE
  )

  targets::tar_config_set(
    script = sel_script_path,
    store = sel_store_path,
    config = path_monitor_config
  )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "i" = "Opening the {.pkg targets} pipeline monitor.",
        " " = "Script: {.path {sel_script_path}}",
        " " = "Store: {.path {sel_store_path}}",
        " " = "Configuration: {.val {sel_config}}",
        "i" = "Stop the foreground dashboard with Ctrl+C."
      )
    )
  }

  monitor_id <- "pipeline_progress_watch"

  withr::with_envvar(
    new = base::c(R_CONFIG_ACTIVE = sel_config),
    code = {
      monitor_ui <-
        targets::tar_watch_ui(
          id = monitor_id,
          seconds = seconds_refresh,
          targets_only = TRUE,
          outdated = FALSE,
          display = sel_initial_display,
          displays = vec_displays,
          title = stringr::str_glue(
            "Pipeline progress: {sel_pipeline_name}"
          ),
          spinner = TRUE
        )

      monitor_server <- function(input, output, session) {
        if (
          base::isFALSE(flag_refresh_automatically)
        ) {
          session$onFlushed(
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

      base::print(
        shiny::shinyApp(
          ui = monitor_ui,
          server = monitor_server
        )
      )
    }
  )

  base::invisible(NULL)
}

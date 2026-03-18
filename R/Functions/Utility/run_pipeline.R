#' @title Run Pipeline
#' @description
#' Executes a targets pipeline from a specified script and saves progress
#' visualization. Prevents execution if default configuration is active.
#' @param sel_script
#' Path to the pipeline script to execute (relative to project root).
#' @param store_suffix
#' Optional character string appended as a sub-directory between the
#' config-derived target store root and the pipeline name.
#' When `NULL` (default) the path is
#' `{target_store}/{pipeline_name}/` — identical to the original
#' behaviour. When set, the path becomes
#' `{target_store}/{store_suffix}/{pipeline_name}/`.
#' Useful when iterating over many spatial units that share one config
#' but each need an isolated store (e.g. `store_suffix = "eu_r01"`).
#' @param level_separation
#' Numeric value controlling the vertical separation between levels in the
#' progress visualization network graph. Default is 100.
#' @param check_default_config
#' Logical indicating whether to check if the default configuration is
#' active and stop execution if TRUE. Default is TRUE.
#' @param plot_progress
#' Logical indicating whether to save a progress visualisation after the
#' pipeline completes. Default is TRUE.
#' @return
#' No return value. Function is called for side effects: executes the
#' targets pipeline and saves progress visualization to the documentation
#' folder.
#' @details
#' The function constructs pipeline-specific target store paths based on
#' the script name and active configuration. It uses targets::tar_make()
#' to execute the pipeline and then calls save_progress_visualisation() to
#' generate a network visualization of the pipeline status.
#' @seealso save_progress_visualisation, targets::tar_make
#' @export
run_pipeline <- function(
    sel_script,
    store_suffix = NULL,
    level_separation = 100,
    check_default_config = TRUE,
    plot_progress = TRUE) {
  assertthat::assert_that(
    is.character(sel_script),
    length(sel_script) == 1,
    msg = "sel_script must be a single string specifying the path to the pipeline script."
  )
  assertthat::assert_that(
    file.exists(sel_script),
    msg = paste(
      "The specified script does not exist:", sel_script, "\n",
      "Please provide a valid path relative to the project root."
    )
  )

  assertthat::assert_that(
    is.null(store_suffix) ||
      (
        is.character(store_suffix) && length(store_suffix) == 1
      ),
    msg = "store_suffix must be NULL or a single string."
  )

  assertthat::assert_that(
    is.numeric(level_separation) &&
      length(level_separation) == 1 &&
      level_separation >= 0,
    msg = "level_separation must be a non-negative number."
  )

  assertthat::assert_that(
    assertthat::is.flag(check_default_config),
    msg = "check_default_config must be a single logical value (TRUE or FALSE)."
  )

  assertthat::assert_that(
    assertthat::is.flag(plot_progress),
    msg = "plot_progress must be a single logical value (TRUE or FALSE)."
  )

  if (
    isTRUE(check_default_config) && config::is_active("default")
  ) {
    stop(
      paste(
        "The default config is active. Please set specific config.", "\n",
        "See `config.yaml` for available options.", "\n",
        "use Sys.setenv(R_CONFIG_ACTIVE = 'XXX') to set the config."
      )
    )
  }

  sel_script_path <-
    here::here(sel_script)

  sel_pipeline_name <-
    stringr::str_replace(
      string = basename(sel_script_path),
      pattern = ".R$",
      replacement = ""
    )

  sel_store_path <-
    if (
      is.null(store_suffix)
    ) {
      paste0(
        get_active_config("target_store"), "/",
        sel_pipeline_name, "/"
      )
    } else {
      {
        paste0(
          get_active_config("target_store"), "/",
          store_suffix, "/",
          sel_pipeline_name, "/"
        )
      } |>
        here::here()
    }

  # Run the pipeline
  try(
    targets::tar_make(
      script = sel_script_path,
      store = sel_store_path,
      reporter = "verbose"
    ),
    silent = FALSE
  )

  if (
    isTRUE(plot_progress)
  ) {
    save_progress_visualisation(
      sel_script = sel_script_path,
      sel_store = sel_store_path,
      level_separation = level_separation
    )
  }
}

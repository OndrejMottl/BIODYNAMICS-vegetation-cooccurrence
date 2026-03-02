#' @title Run Pipeline
#' @description
#' Executes a targets pipeline from a specified script and saves progress
#' visualization. Prevents execution if default configuration is active.
#' @param sel_script
#' Path to the pipeline script to execute (relative to project root).
#' @param level_separation
#' Numeric value controlling the vertical separation between levels in the
#' progress visualization network graph. Default is 100.
#' @param check_default_config
#' Logical indicating whether to check if the default configuration is
#' active and stop execution if TRUE. Default is TRUE.
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
    level_separation = 100,
    check_default_config = TRUE) {
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
    paste0(
      get_active_config("target_store"), "/",
      sel_pipeline_name, "/"
    ) %>%
    here::here()

  # Run the pipeline
  try(
    targets::tar_make(
      script = sel_script_path,
      store = sel_store_path,
      reporter = "verbose"
    ),
    silent = FALSE
  )


  # Save the status of the project
  save_progress_visualisation(
    sel_script = sel_script_path,
    sel_store = sel_store_path,
    level_separation = level_separation
  )
}

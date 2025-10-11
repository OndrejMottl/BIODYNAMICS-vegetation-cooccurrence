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

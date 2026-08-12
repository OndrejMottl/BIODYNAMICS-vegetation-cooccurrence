# Run the issue 138 staged paleo continental Europe/genus validation.

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

base::suppressWarnings(
  base::source(
    here::here("R/___setup_project___.R")
  )
)

run_issue138_representative_validation(
  active_config =
    "project_issue138_paleo_spatial_continental_europe_staged",
  unit_pipeline =
    "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  tuning_target_names = "list_sjsdm_cv_tuning_artifact_genus",
  final_target_names = base::c(
    "mod_jsdm_selected_genus",
    "list_sjsdm_cv_evaluation_artifact_genus"
  ),
  store_suffix = "europe",
  prebuild_interpolation = TRUE,
  fresh_run = FALSE
)

# Run the issue 138 staged America temporal-slice validation.

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
  active_config = "project_paleo_temporal_issue138_america_staged",
  unit_pipeline = "R/Pipelines/pipeline_paleo_temporal.R",
  tuning_target_names =
    "list_sjsdm_cv_tuning_artifact_timeslice_6500",
  final_target_names = base::c(
    "mod_jsdm_selected_timeslice_6500",
    "list_sjsdm_cv_evaluation_artifact_timeslice_6500"
  ),
  prebuild_interpolation = TRUE,
  fresh_run = FALSE
)

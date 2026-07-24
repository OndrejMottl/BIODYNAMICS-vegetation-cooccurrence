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
    "data_sjsdm_tuning_summary_timeslice_19000",
  final_target_names = base::c(
    "model_jsdm_selected_timeslice_19000",
    "model_evaluation_cross_validated_timeslice_19000",
    "data_sjsdm_model_provenance_timeslice_19000",
    "model_anova_timeslice_19000"
  ),
  prebuild_interpolation = TRUE
)

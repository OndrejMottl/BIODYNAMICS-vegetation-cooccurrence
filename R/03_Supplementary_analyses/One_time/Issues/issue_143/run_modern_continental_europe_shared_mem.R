# Run the Issue 143 shared-MEM modern continental Europe validation.

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
    "project_issue143_modern_spatial_continental_europe_shared_mem",
  unit_pipeline =
    "R/Pipelines/pipeline_modern_spatial_resolution.R",
  tuning_target_names = "data_sjsdm_tuning_summary_genus",
  final_target_names = base::c(
    "mod_jsdm_selected_genus",
    "model_evaluation_cross_validated_genus",
    "data_sjsdm_model_provenance_genus"
  ),
  store_suffix = "europe"
)

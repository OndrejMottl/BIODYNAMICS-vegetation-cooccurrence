#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          CZ paleo CV component reference pipeline
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Fits controlled predictor-component models on the validated GPU reference
# assignments without modifying the upstream reference store.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  library(
    "here",
    quietly = TRUE,
    warn.conflicts = FALSE,
    verbose = FALSE
  )
)

base::suppressMessages(
  base::suppressWarnings(
    base::source(
      here::here("R/___setup_project___.R")
    )
  )
)

vec_function_files <-
  base::list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) |>
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated|_legacy")
  )

targets::tar_source(files = vec_function_files)

targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs"
)

path_gpu_reference_store <-
  here::here(
    "Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core"
  )


#----------------------------------------------------------#
# 1. Pipeline definition -----
#----------------------------------------------------------#

base::list(
  targets::tar_target(
    name = config_reference_model_fitting,
    command = targets::tar_read_raw(
      name = "config_model_fitting",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = config_reference_data_processing,
    command = targets::tar_read_raw(
      name = "config_data_processing",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_assignments,
    command = targets::tar_read_raw(
      name = "data_cross_validation_assignments",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_selected_candidate,
    command = targets::tar_read_raw(
      name = "model_regularization_for_fit",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_community_matrix,
    command = targets::tar_read_raw(
      name = "data_community_model_matrix",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_abiotic_wide,
    command = targets::tar_read_raw(
      name = "data_abiotic_wide",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_coords_projected,
    command = targets::tar_read_raw(
      name = "data_coords_projected",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_sample_ids,
    command = targets::tar_read_raw(
      name = "data_sample_ids_checked",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = reference_model_formula,
    command = targets::tar_read_raw(
      name = "model_formula",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_sjsdm_abiotic_spatial_fold_metrics,
    command = targets::tar_read_raw(
      name = "data_sjsdm_fold_local_metrics",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_sjsdm_abiotic_spatial_metric_summaries,
    command = targets::tar_read_raw(
      name = "list_sjsdm_fold_metric_summaries",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_sjsdm_abiotic_spatial_repeat_distributions,
    command = targets::tar_read_raw(
      name = "list_sjsdm_metric_repeat_distributions",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_sjsdm_intercept_only_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "intercept_only",
      data_assignments = data_reference_assignments,
      data_selected_candidate = data_reference_selected_candidate,
      data_community_matrix = data_reference_community_matrix,
      data_abiotic_wide = data_reference_abiotic_wide,
      data_coords_projected = data_reference_coords_projected,
      data_sample_ids = data_reference_sample_ids,
      config_model_fitting = config_reference_model_fitting,
      config_data_processing = config_reference_data_processing,
      model_formula = reference_model_formula,
      device = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_sjsdm_intercept_only_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions = list_sjsdm_intercept_only_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_sjsdm_intercept_only_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_sjsdm_intercept_only_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_intercept_only_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_sjsdm_intercept_only_metric_summaries
    )
  ),
  targets::tar_target(
    name = list_sjsdm_abiotic_only_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "abiotic_only",
      data_assignments = data_reference_assignments,
      data_selected_candidate = data_reference_selected_candidate,
      data_community_matrix = data_reference_community_matrix,
      data_abiotic_wide = data_reference_abiotic_wide,
      data_coords_projected = data_reference_coords_projected,
      data_sample_ids = data_reference_sample_ids,
      config_model_fitting = config_reference_model_fitting,
      config_data_processing = config_reference_data_processing,
      model_formula = reference_model_formula,
      device = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_sjsdm_abiotic_only_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions = list_sjsdm_abiotic_only_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_sjsdm_abiotic_only_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_sjsdm_abiotic_only_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_abiotic_only_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_sjsdm_abiotic_only_metric_summaries
    )
  ),
  targets::tar_target(
    name = list_sjsdm_spatial_only_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "spatial_only",
      data_assignments = data_reference_assignments,
      data_selected_candidate = data_reference_selected_candidate,
      data_community_matrix = data_reference_community_matrix,
      data_abiotic_wide = data_reference_abiotic_wide,
      data_coords_projected = data_reference_coords_projected,
      data_sample_ids = data_reference_sample_ids,
      config_model_fitting = config_reference_model_fitting,
      config_data_processing = config_reference_data_processing,
      model_formula = reference_model_formula,
      device = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_sjsdm_spatial_only_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions = list_sjsdm_spatial_only_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_sjsdm_spatial_only_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_sjsdm_spatial_only_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_spatial_only_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_sjsdm_spatial_only_metric_summaries
    )
  )
)

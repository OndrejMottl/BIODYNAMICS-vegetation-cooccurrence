#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       CZ paleo CV regularization reference pipeline
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs a controlled coordinate search on validated GPU reference assignments
# without modifying the upstream reference store.


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
  seed = load_active_config_value("seed"),
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
    command = load_sjsdm_cv_payload_field(
      store_path = path_gpu_reference_store,
      v2_target_name = "list_cross_validation_design_artifact",
      artifact_type = "cross_validation_design",
      payload_name = "data_assignments",
      v1_target_name = "data_cross_validation_assignments"
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_selected_candidate,
    command = load_sjsdm_cv_payload_field(
      store_path = path_gpu_reference_store,
      v2_target_name =
        "list_sjsdm_regularization_selection_artifact",
      artifact_type = "sjsdm_regularization_selection",
      payload_name = "data_selection_for_fit",
      v1_target_name = "model_regularization_for_fit"
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
      name = "formula_jsdm_environment",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_reference_repeat_distributions,
    command = targets::tar_read_raw(
      name = "list_sjsdm_metric_repeat_distributions",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_reference_fold_metrics,
    command = targets::tar_read_raw(
      name = "data_sjsdm_fold_local_metrics",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_reference_metric_summaries,
    command = targets::tar_read_raw(
      name = "list_sjsdm_fold_metric_summaries",
      store = path_gpu_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = list_sjsdm_structured_regularization_design,
    command = build_sjsdm_structured_regularization_candidates(
      alpha_cov = data_reference_selected_candidate[["alpha_cov"]][[1L]],
      alpha_coef =
        data_reference_selected_candidate[["alpha_coef"]][[1L]],
      alpha_spatial =
        data_reference_selected_candidate[["alpha_spatial"]][[1L]],
      lambda_cov_reference =
        data_reference_selected_candidate[["lambda_cov"]][[1L]],
      lambda_coef_reference =
        data_reference_selected_candidate[["lambda_coef"]][[1L]],
      lambda_spatial_reference =
        data_reference_selected_candidate[["lambda_spatial"]][[1L]],
      lambda_values = base::c(0, 0.01, 0.03, 0.1, 0.3, 1)
    )
  ),
  targets::tar_target(
    name = data_sjsdm_structured_regularization_candidates,
    command = list_sjsdm_structured_regularization_design |>
      purrr::chuck("data_candidates")
  ),
  targets::tar_target(
    name = data_sjsdm_structured_search_design,
    command = list_sjsdm_structured_regularization_design |>
      purrr::chuck("data_search_design")
  ),
  targets::tar_target(
    name = data_sjsdm_structured_tuning_candidates,
    command = run_sjsdm_tuning_candidates(
      data_assignments = data_reference_assignments,
      data_candidates = data_sjsdm_structured_regularization_candidates,
      prepare_fold_function = function(
          train_indices,
          test_indices,
          repeat_id,
          fold_id) {
        prepare_sjsdm_cross_validation_fold(
          data_community_matrix = data_reference_community_matrix,
          data_abiotic_wide = data_reference_abiotic_wide,
          data_coords_projected = data_reference_coords_projected,
          data_sample_ids = data_reference_sample_ids,
          train_indices = train_indices,
          test_indices = test_indices,
          config_model_fitting = config_reference_model_fitting,
          config_data_processing = config_reference_data_processing,
          repeat_id = repeat_id,
          fold_id = fold_id
        )
      },
      fit_function = function(data_train_input, candidate, seed) {
        fit_sjsdm_regularization_candidate(
          data_train_input = data_train_input,
          candidate = candidate,
          sel_abiotic_formula = reference_model_formula,
          config_model_fitting = config_reference_model_fitting,
          seed = seed,
          device = purrr::chuck(
            config_reference_model_fitting,
            "cross_validation",
            "fit_device"
          )
        )
      },
      predict_function = predict_sjsdm_probability_matrix,
      score_function = score_sjsdm_joint_tuning_predictions,
      seed = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_sjsdm_structured_tuning_summary,
    command = summarise_sjsdm_tuning_candidates(
      data_tuning = data_sjsdm_structured_tuning_candidates
    )
  ),
  targets::tar_target(
    name = data_sjsdm_structured_tuning_response_surface,
    command = dplyr::left_join(
      data_sjsdm_structured_tuning_summary,
      data_sjsdm_structured_search_design,
      by = "candidate_id",
      relationship = "many-to-one"
    )
  ),
  targets::tar_target(
    name = data_sjsdm_structured_selected_regularization,
    command = select_sjsdm_regularization(
      data_tuning_summary = data_sjsdm_structured_tuning_summary,
      selection_metric = purrr::chuck(
        config_reference_model_fitting,
        "cross_validation",
        "selection_metric"
      )
    )
  ),
  targets::tar_target(
    name = data_sjsdm_structured_selection_diagnostic,
    command = dplyr::left_join(
      data_sjsdm_structured_selected_regularization,
      data_sjsdm_structured_search_design,
      by = "candidate_id",
      relationship = "one-to-one"
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_selected_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "abiotic_spatial",
      data_assignments = data_reference_assignments,
      data_selected_candidate =
        data_sjsdm_structured_selected_regularization,
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
    name = data_sjsdm_structured_selected_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions =
        list_sjsdm_structured_selected_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_selected_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics =
        data_sjsdm_structured_selected_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_selected_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_sjsdm_structured_selected_metric_summaries
    )
  ),
  targets::tar_target(
    name = data_sjsdm_reference_taxon_eligibility,
    command = evaluate_sjsdm_taxon_eligibility(
      data_fold_metrics = data_reference_fold_metrics,
      minimum_prevalence = 0.05,
      maximum_prevalence = 0.95,
      minimum_evaluable_fraction = 0.8
    )
  ),
  targets::tar_target(
    name = vec_sjsdm_eligible_taxa,
    command = data_sjsdm_reference_taxon_eligibility |>
      dplyr::filter(.data[["eligible"]]) |>
      dplyr::pull("taxon")
  ),
  targets::tar_target(
    name = data_reference_eligible_fold_metrics,
    command = data_reference_fold_metrics |>
      dplyr::filter(.data[["taxon"]] %in% vec_sjsdm_eligible_taxa)
  ),
  targets::tar_target(
    name = data_sjsdm_structured_selected_eligible_fold_metrics,
    command = data_sjsdm_structured_selected_fold_metrics |>
      dplyr::filter(.data[["taxon"]] %in% vec_sjsdm_eligible_taxa)
  ),
  targets::tar_target(
    name = list_reference_eligible_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_reference_eligible_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_selected_eligible_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics =
        data_sjsdm_structured_selected_eligible_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_selection_guardrails,
    command = evaluate_sjsdm_candidate_guardrails(
      data_tuning_summary =
        data_sjsdm_structured_tuning_response_surface,
      data_candidate_repeat_metrics =
        list_sjsdm_structured_selected_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      data_reference_repeat_metrics =
        list_reference_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      candidate_id = data_sjsdm_structured_selection_diagnostic |>
        dplyr::pull("candidate_id"),
      reference_candidate_id = data_sjsdm_structured_search_design |>
        dplyr::filter(.data[["is_reference"]]) |>
        dplyr::pull("candidate_id")
    )
  ),
  targets::tar_target(
    name = list_sjsdm_structured_eligible_selection_guardrails,
    command = evaluate_sjsdm_candidate_guardrails(
      data_tuning_summary =
        data_sjsdm_structured_tuning_response_surface,
      data_candidate_repeat_metrics =
        list_sjsdm_structured_selected_eligible_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      data_reference_repeat_metrics =
        list_reference_eligible_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      candidate_id = data_sjsdm_structured_selection_diagnostic |>
        dplyr::pull("candidate_id"),
      reference_candidate_id = data_sjsdm_structured_search_design |>
        dplyr::filter(.data[["is_reference"]]) |>
        dplyr::pull("candidate_id")
    )
  )
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Paleo local predictive decomposition reference
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Fits reduced models on the validated scientific-reference assignments.


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

path_scientific_reference_store <-
  here::here(
    "Data/targets/paleo_local_cv_scientific_reference_gpu/",
    "pipeline_paleo_local_cv_scientific_reference"
  )

path_full_data_reference_store <-
  here::here(
    "Data/targets/paleo_spatial_local/eu_r005_l010/",
    "pipeline_paleo_spatial_resolution"
  )


#----------------------------------------------------------#
# 1. Pipeline definition -----
#----------------------------------------------------------#

base::list(
  targets::tar_target(
    name = config_decomposition_model_fitting,
    command = targets::tar_read_raw(
      name = "config_scientific_reference_model_fitting",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = config_decomposition_data_processing,
    command = targets::tar_read_raw(
      name = "config_scientific_reference_data_processing",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_assignments,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_assignments",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_candidate,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_candidate",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_community_matrix,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_community_matrix",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_abiotic_wide,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_abiotic_wide",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_coords_projected,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_coords_projected",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_decomposition_sample_ids,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_sample_ids",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = decomposition_model_formula,
    command = targets::tar_read_raw(
      name = "scientific_reference_model_formula",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_full_fold_metrics,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_fold_metrics",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_taxon_eligibility,
    command = targets::tar_read_raw(
      name = "data_scientific_reference_taxon_eligibility",
      store = path_scientific_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = model_scientific_reference_full_data_anova,
    command = targets::tar_read_raw(
      name = "list_jsdm_variance_partition_genus",
      store = path_full_data_reference_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_full_data_anova_fractions,
    command = extract_jsdm_variance_fractions(
      anova_object = model_scientific_reference_full_data_anova,
      clamp_negative = FALSE
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_no_abiotic_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "spatial_only",
      data_assignments = data_decomposition_assignments,
      data_selected_candidate = data_decomposition_candidate,
      data_community_matrix = data_decomposition_community_matrix,
      data_abiotic_wide = data_decomposition_abiotic_wide,
      data_coords_projected = data_decomposition_coords_projected,
      data_sample_ids = data_decomposition_sample_ids,
      config_model_fitting = config_decomposition_model_fitting,
      config_data_processing = config_decomposition_data_processing,
      model_formula = decomposition_model_formula,
      device = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_no_abiotic_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions =
        list_scientific_reference_no_abiotic_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_no_spatial_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "abiotic_only",
      data_assignments = data_decomposition_assignments,
      data_selected_candidate = data_decomposition_candidate,
      data_community_matrix = data_decomposition_community_matrix,
      data_abiotic_wide = data_decomposition_abiotic_wide,
      data_coords_projected = data_decomposition_coords_projected,
      data_sample_ids = data_decomposition_sample_ids,
      config_model_fitting = config_decomposition_model_fitting,
      config_data_processing = config_decomposition_data_processing,
      model_formula = decomposition_model_formula,
      device = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_no_spatial_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions =
        list_scientific_reference_no_spatial_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_no_associations_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "abiotic_spatial_no_associations",
      data_assignments = data_decomposition_assignments,
      data_selected_candidate = data_decomposition_candidate,
      data_community_matrix = data_decomposition_community_matrix,
      data_abiotic_wide = data_decomposition_abiotic_wide,
      data_coords_projected = data_decomposition_coords_projected,
      data_sample_ids = data_decomposition_sample_ids,
      config_model_fitting = config_decomposition_model_fitting,
      config_data_processing = config_decomposition_data_processing,
      model_formula = decomposition_model_formula,
      device = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_decomposition_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_no_associations_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions =
        list_scientific_reference_no_associations_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_fold_metrics,
    command = base::list(
      full = data_scientific_reference_full_fold_metrics,
      no_abiotic = data_scientific_reference_no_abiotic_fold_metrics,
      no_spatial = data_scientific_reference_no_spatial_fold_metrics,
      no_associations =
        data_scientific_reference_no_associations_fold_metrics
    ) |>
      purrr::imap(
        ~ .x |>
          dplyr::filter(
            .data[["prediction_source"]] == "model"
          ) |>
          dplyr::mutate(variant = .y, .before = 1L)
      ) |>
      purrr::list_rbind()
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_comparisons,
    command = compare_sjsdm_decomposition_fold_metrics(
      data_fold_metrics =
        data_scientific_reference_decomposition_fold_metrics,
      data_taxon_eligibility =
        data_scientific_reference_taxon_eligibility
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_decomposition_effects,
    command = summarise_sjsdm_decomposition_effects(
      data_comparisons =
        data_scientific_reference_decomposition_comparisons
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_fold_effects,
    command = list_scientific_reference_decomposition_effects |>
      purrr::chuck("data_fold_effects")
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_repeat_effects,
    command = list_scientific_reference_decomposition_effects |>
      purrr::chuck("data_repeat_effects")
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_summary,
    command = list_scientific_reference_decomposition_effects |>
      purrr::chuck("data_summary")
  ),
  targets::tar_target(
    name = list_scientific_reference_decomposition_loss_shares,
    command = compute_sjsdm_decomposition_loss_shares(
      data_repeat_effects =
        data_scientific_reference_decomposition_repeat_effects
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_repeat_loss_shares,
    command = list_scientific_reference_decomposition_loss_shares |>
      purrr::chuck("data_repeat_shares")
  ),
  targets::tar_target(
    name = data_scientific_reference_decomposition_loss_share_summary,
    command = list_scientific_reference_decomposition_loss_shares |>
      purrr::chuck("data_share_summary")
  )
)

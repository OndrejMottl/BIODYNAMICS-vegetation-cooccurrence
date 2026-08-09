#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Paleo local scientific CV reference
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Evaluates a fixed model on fresh folds for the selected eu_r005_l010 unit.


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

path_source_store <-
  here::here(
    "Data/targets/paleo_spatial_local/eu_r005_l010/",
    "pipeline_paleo_spatial_resolution"
  )


#----------------------------------------------------------#
# 1. Pipeline definition -----
#----------------------------------------------------------#

base::list(
  targets::tar_target(
    name = config_source_model_fitting,
    command = targets::tar_read_raw(
      name = "config_model_fitting_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = config_scientific_reference_data_processing,
    command = targets::tar_read_raw(
      name = "config_data_processing",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_community_matrix,
    command = targets::tar_read_raw(
      name = "data_community_model_matrix_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_community_prepared,
    command = targets::tar_read_raw(
      name = "data_community_prepared_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_abiotic_wide,
    command = targets::tar_read_raw(
      name = "data_abiotic_wide_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_coords_projected,
    command = targets::tar_read_raw(
      name = "data_coords_projected",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = data_scientific_reference_sample_ids,
    command = targets::tar_read_raw(
      name = "data_sample_ids_checked_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = scientific_reference_model_formula,
    command = targets::tar_read_raw(
      name = "formula_jsdm_environment_genus",
      store = path_source_store
    ),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    name = config_scientific_reference_model_fitting,
    command = purrr::list_modify(
      config_source_model_fitting,
      cross_validation = load_active_config_value("model_fitting") |>
        purrr::chuck("cross_validation")
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_locations,
    command = make_cross_validation_location_table(
      data_sample_ids = data_scientific_reference_sample_ids,
      data_coords_projected =
        data_scientific_reference_coords_projected
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_fold_resolution,
    command = resolve_cross_validation_fold_count(
      n_locations = base::nrow(data_scientific_reference_locations),
      min_train_locations = base::max(
        purrr::chuck(
          config_scientific_reference_data_processing,
          "min_n_cores"
        ),
        purrr::chuck(
          config_scientific_reference_model_fitting,
          "cross_validation",
          "min_mem_locations"
        )
      ),
      default_folds = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "default_folds"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_grid_candidates,
    command = make_cross_validation_grid_candidates_from_resolution(
      data_locations = data_scientific_reference_locations,
      data_fold_resolution =
        data_scientific_reference_fold_resolution,
      target_locations_per_cell = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "target_locations_per_cell"
      ),
      grid_size_multipliers = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "size_multipliers"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_grid_calibration,
    command = calibrate_cross_validation_grid_from_resolution(
      data_locations = data_scientific_reference_locations,
      data_fold_resolution =
        data_scientific_reference_fold_resolution,
      candidate_grid_cell_sizes_km = dplyr::pull(
        data_scientific_reference_grid_candidates,
        "grid_cell_size_km"
      ),
      n_repeats = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "assignment_repeats"
      ),
      occupancy_criterion = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "occupancy_criterion"
      ),
      target_locations_per_cell = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "target_locations_per_cell"
      ),
      lower_quantile_probability = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "lower_quantile_probability"
      ),
      max_fold_location_difference = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "max_fold_location_difference"
      ),
      max_fold_sample_difference = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "grid",
        "max_fold_sample_difference"
      ),
      seed = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "assignment_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_assignments_initial,
    command = make_cross_validation_assignments_from_resolution(
      data_locations = data_scientific_reference_locations,
      data_fold_resolution =
        data_scientific_reference_fold_resolution,
      data_grid_calibration =
        data_scientific_reference_grid_calibration,
      n_repeats = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "assignment_repeats"
      ),
      seed = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "assignment_seed"
      ),
      assignment_source = "scientific_reference_fresh"
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_partition_diagnostics_initial,
    command = make_cross_validation_partition_diagnostics(
      data_locations = data_scientific_reference_locations,
      data_assignments =
        data_scientific_reference_assignments_initial,
      data_community_matrix =
        data_scientific_reference_community_prepared,
      cv_strategy = dplyr::pull(
        data_scientific_reference_fold_resolution,
        "cv_strategy"
      ),
      min_taxon_locations = purrr::chuck(
        config_scientific_reference_data_processing,
        "min_n_cores"
      ),
      min_taxon_samples = purrr::chuck(
        config_scientific_reference_data_processing,
        "min_n_samples"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_assignments,
    command = adapt_cross_validation_assignments(
      data_locations = data_scientific_reference_locations,
      data_assignments =
        data_scientific_reference_assignments_initial,
      data_partition_diagnostics =
        data_scientific_reference_partition_diagnostics_initial,
      min_train_locations = purrr::chuck(
        config_scientific_reference_data_processing,
        "min_n_cores"
      ),
      min_train_samples = purrr::chuck(
        config_scientific_reference_data_processing,
        "min_n_samples"
      ),
      min_train_taxa = purrr::chuck(
        config_scientific_reference_data_processing,
        "min_n_taxa"
      ),
      min_mem_locations = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "min_mem_locations"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_candidate,
    command = make_sjsdm_regularization_candidates(
      alpha_cov = base::c(0.5),
      alpha_coef = base::c(0.5),
      alpha_spatial = base::c(0.5),
      lambda_cov = base::c(0.1),
      lambda_coef = base::c(0.1),
      lambda_spatial = base::c(0.1)
    ) |>
      dplyr::mutate(
        regularization_source = "fixed_external_reference"
      )
  ),
  targets::tar_target(
    name = list_scientific_reference_fold_predictions,
    command = run_sjsdm_predictor_structure_folds(
      predictor_structure = "abiotic_spatial",
      data_assignments = data_scientific_reference_assignments,
      data_selected_candidate = data_scientific_reference_candidate,
      data_community_matrix =
        data_scientific_reference_community_matrix,
      data_abiotic_wide = data_scientific_reference_abiotic_wide,
      data_coords_projected =
        data_scientific_reference_coords_projected,
      data_sample_ids = data_scientific_reference_sample_ids,
      config_model_fitting =
        config_scientific_reference_model_fitting,
      config_data_processing =
        config_scientific_reference_data_processing,
      model_formula = scientific_reference_model_formula,
      device = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "fit_device"
      ),
      seed = purrr::chuck(
        config_scientific_reference_model_fitting,
        "cross_validation",
        "fit_seed"
      )
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_fold_metrics,
    command = evaluate_sjsdm_fold_predictions(
      data_predictions = list_scientific_reference_fold_predictions |>
        purrr::chuck("data_predictions")
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics = data_scientific_reference_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_scientific_reference_metric_summaries
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_taxon_eligibility,
    command = assess_sjsdm_taxon_eligibility(
      data_fold_metrics = data_scientific_reference_fold_metrics,
      minimum_prevalence = 0.05,
      maximum_prevalence = 0.95,
      minimum_evaluable_fraction = 0.8
    )
  ),
  targets::tar_target(
    name = vec_scientific_reference_eligible_taxa,
    command = data_scientific_reference_taxon_eligibility |>
      dplyr::filter(.data[["eligible"]]) |>
      dplyr::pull("taxon")
  ),
  targets::tar_target(
    name = data_scientific_reference_eligible_fold_metrics,
    command = data_scientific_reference_fold_metrics |>
      dplyr::filter(
        .data[["taxon"]] %in%
          vec_scientific_reference_eligible_taxa
      )
  ),
  targets::tar_target(
    name = list_scientific_reference_eligible_metric_summaries,
    command = summarise_sjsdm_fold_metrics(
      data_fold_metrics =
        data_scientific_reference_eligible_fold_metrics
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_eligible_repeat_distributions,
    command = summarise_sjsdm_metric_repeats(
      list_fold_metric_summaries =
        list_scientific_reference_eligible_metric_summaries
    )
  ),
  targets::tar_target(
    name = list_scientific_reference_performance_policy,
    command = load_active_config_value("scientific_performance")
  ),
  targets::tar_target(
    name = list_scientific_reference_performance_assessment,
    command = assess_sjsdm_scientific_performance(
      data_model_repeat_metrics =
        list_scientific_reference_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      data_paired_repeat_metrics =
        list_scientific_reference_metric_summaries |>
        purrr::chuck("data_paired_improvements"),
      data_eligible_model_repeat_metrics =
        list_scientific_reference_eligible_metric_summaries |>
        purrr::chuck("data_source_summaries"),
      data_taxon_eligibility =
        data_scientific_reference_taxon_eligibility,
      data_fold_diagnostics =
        list_scientific_reference_fold_predictions |>
        purrr::chuck("data_diagnostics"),
      data_predictions =
        list_scientific_reference_fold_predictions |>
        purrr::chuck("data_predictions"),
      list_policy = list_scientific_reference_performance_policy
    )
  ),
  targets::tar_target(
    name = data_scientific_reference_performance_criteria,
    command = list_scientific_reference_performance_assessment |>
      purrr::chuck("data_performance_criteria")
  ),
  targets::tar_target(
    name = data_scientific_reference_performance_decision,
    command = list_scientific_reference_performance_assessment |>
      purrr::chuck("data_performance_decision")
  )
)

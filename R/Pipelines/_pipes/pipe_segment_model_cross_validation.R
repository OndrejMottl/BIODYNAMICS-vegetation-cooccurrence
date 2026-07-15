#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       {targets} pipe: Model cross-validation
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines per-ID fold assignment, tuning, selected out-of-fold predictions,
#   and cross-validated predictive evaluation targets.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

base::suppressMessages(
  base::suppressWarnings(
    base::source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_model_cross_validation <-
  base::list(
    targets::tar_target(
      description = stringr::str_c(
        "Collapse aligned samples to unique cross-validation locations"
      ),
      name = "data_cross_validation_locations",
      command = make_cross_validation_location_table(
        data_sample_ids = data_sample_ids_checked,
        data_coords_projected = data_coords_projected
      )
    ),
    targets::tar_target(
      description = "Resolve the location-level cross-validation strategy",
      name = "data_cross_validation_fold_resolution",
      command = resolve_cross_validation_fold_count(
        n_locations = base::nrow(data_cross_validation_locations),
        min_train_locations = base::max(
          purrr::chuck(config_data_processing, "min_n_cores"),
          purrr::chuck(
            config_model_fitting,
            "cross_validation",
            "min_mem_locations"
          )
        ),
        default_folds = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "default_folds"
        )
      )
    ),
    targets::tar_target(
      description = "Derive per-ID spatial-grid candidates",
      name = "data_cross_validation_grid_candidates",
      command = make_cross_validation_grid_candidates_from_resolution(
        data_locations = data_cross_validation_locations,
        data_fold_resolution = data_cross_validation_fold_resolution,
        target_locations_per_cell = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "target_locations_per_cell"
        ),
        grid_size_multipliers = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "size_multipliers"
        )
      )
    ),
    targets::tar_target(
      description = "Calibrate the per-ID spatial cross-validation grid",
      name = "data_cross_validation_grid_calibration",
      command = calibrate_cross_validation_grid_from_resolution(
        data_locations = data_cross_validation_locations,
        data_fold_resolution = data_cross_validation_fold_resolution,
        candidate_grid_cell_sizes_km = dplyr::pull(
          data_cross_validation_grid_candidates,
          "grid_cell_size_km"
        ),
        n_repeats = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "assignment_repeats"
        ),
        occupancy_criterion = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "occupancy_criterion"
        ),
        target_locations_per_cell = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "target_locations_per_cell"
        ),
        lower_quantile_probability = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "lower_quantile_probability"
        ),
        max_fold_location_difference = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "max_fold_location_difference"
        ),
        max_fold_sample_difference = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "grid",
          "max_fold_sample_difference"
        ),
        seed = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "assignment_seed"
        )
      )
    ),
    targets::tar_target(
      description = "Assign complete locations to cross-validation folds",
      name = "data_cross_validation_assignments_initial",
      command = make_cross_validation_assignments_from_resolution(
        data_locations = data_cross_validation_locations,
        data_fold_resolution = data_cross_validation_fold_resolution,
        data_grid_calibration =
          data_cross_validation_grid_calibration,
        n_repeats = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "assignment_repeats"
        ),
        seed = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "assignment_seed"
        )
      )
    ),
    targets::tar_target(
      description = "Diagnose initial complete and held-out partitions",
      name = "data_cross_validation_partition_diagnostics_initial",
      command = make_cross_validation_partition_diagnostics(
        data_locations = data_cross_validation_locations,
        data_assignments = data_cross_validation_assignments_initial,
        data_community_matrix = data_community_prepared,
        cv_strategy = dplyr::pull(
          data_cross_validation_fold_resolution,
          "cv_strategy"
        ),
        min_taxon_locations = purrr::chuck(
          config_data_processing,
          "min_n_cores"
        ),
        min_taxon_samples = purrr::chuck(
          config_data_processing,
          "min_n_samples"
        )
      )
    ),
    targets::tar_target(
      description = "Adapt grouped folds toward leave-one-location-out",
      name = "data_cross_validation_assignments",
      command = adapt_cross_validation_assignments(
        data_locations = data_cross_validation_locations,
        data_assignments = data_cross_validation_assignments_initial,
        data_partition_diagnostics =
          data_cross_validation_partition_diagnostics_initial,
        min_train_locations = purrr::chuck(
          config_data_processing,
          "min_n_cores"
        ),
        min_train_samples = purrr::chuck(
          config_data_processing,
          "min_n_samples"
        ),
        min_train_taxa = purrr::chuck(
          config_data_processing,
          "min_n_taxa"
        ),
        min_mem_locations = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "min_mem_locations"
        )
      )
    ),
    targets::tar_target(
      description = "Diagnose final complete and held-out partitions",
      name = "data_cross_validation_partition_diagnostics",
      command = make_cross_validation_partition_diagnostics(
        data_locations = data_cross_validation_locations,
        data_assignments = data_cross_validation_assignments,
        data_community_matrix = data_community_prepared,
        cv_strategy = dplyr::first(
          dplyr::pull(
            data_cross_validation_assignments,
            "cv_strategy"
          ),
          default = "none"
        ),
        min_taxon_locations = purrr::chuck(
          config_data_processing,
          "min_n_cores"
        ),
        min_taxon_samples = purrr::chuck(
          config_data_processing,
          "min_n_samples"
        )
      )
    ),
    targets::tar_target(
      description = "Classify per-ID cross-validation feasibility",
      name = "data_cross_validation_feasibility",
      command = assess_cross_validation_feasibility(
        data_partition_diagnostics =
          data_cross_validation_partition_diagnostics,
        min_train_locations = purrr::chuck(
          config_data_processing,
          "min_n_cores"
        ),
        min_train_samples = purrr::chuck(
          config_data_processing,
          "min_n_samples"
        ),
        min_train_taxa = purrr::chuck(
          config_data_processing,
          "min_n_taxa"
        ),
        min_mem_locations = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "min_mem_locations"
        )
      )
    ),
    targets::tar_target(
      description = "Build deterministic sjSDM regularization candidates",
      name = "data_sjsdm_regularization_candidates",
      command = make_sjsdm_regularization_candidates(
        alpha_cov = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "alpha_cov"
        ),
        alpha_coef = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "alpha_coef"
        ),
        alpha_spatial = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "alpha_spatial"
        ),
        lambda_cov = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "lambda_cov"
        ),
        lambda_coef = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "lambda_coef"
        ),
        lambda_spatial = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "regularization",
          "lambda_spatial"
        )
      )
    ),
    targets::tar_target(
      description = "Record model context for CV regularization provenance",
      name = "data_sjsdm_model_context",
      command = tibble::tibble(
        tier_id = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "tier_id"
        ),
        taxonomic_resolution = purrr::chuck(
          config_data_processing,
          "taxonomic_resolution"
        ),
        response_family = purrr::chuck(
          config_model_fitting,
          "error_family"
        ),
        predictor_structure = stringr::str_c(
          "spatial=",
          purrr::chuck(config_model_fitting, "use_spatial"),
          ";mode=",
          purrr::chuck(config_model_fitting, "spatial_mode"),
          ";age=",
          purrr::chuck(config_model_fitting, "use_age_in_formula"),
          ";n_mev=",
          purrr::chuck(config_model_fitting, "n_mev")
        ),
        candidate_table_hash = digest::digest(
          data_sjsdm_regularization_candidates
        )
      )
    ),
    targets::tar_target(
      description = "Fit and score every unit-CV tuning candidate",
      name = "data_sjsdm_tuning_candidates",
      command = run_sjsdm_tuning_candidates(
        data_assignments = data_cross_validation_assignments,
        data_candidates = data_sjsdm_regularization_candidates,
        prepare_fold_function = function(
            train_indices,
            test_indices,
            repeat_id,
            fold_id) {
          prepare_sjsdm_cross_validation_fold(
            data_community_matrix = data_community_model_matrix,
            data_abiotic_wide = data_abiotic_wide,
            data_coords_projected = data_coords_projected,
            data_sample_ids = data_sample_ids_checked,
            train_indices = train_indices,
            test_indices = test_indices,
            config_model_fitting = config_model_fitting,
            config_data_processing = config_data_processing,
            repeat_id = repeat_id,
            fold_id = fold_id
          )
        },
        fit_function = function(data_train_input, candidate, seed) {
          fit_sjsdm_regularization_candidate(
            data_train_input = data_train_input,
            candidate = candidate,
            sel_abiotic_formula = model_formula,
            config_model_fitting = config_model_fitting,
            seed = seed,
            device = purrr::chuck(
              config_model_fitting,
              "cross_validation",
              "fit_device"
            )
          )
        },
        predict_function = predict_sjsdm_probability_matrix,
        score_function = score_sjsdm_joint_tuning_predictions,
        seed = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "fit_seed"
        )
      )
    ),
    targets::tar_target(
      description = "Summarise fold-level sjSDM tuning candidates",
      name = "data_sjsdm_tuning_summary",
      command = summarise_sjsdm_tuning_candidates(
        data_tuning = data_sjsdm_tuning_candidates
      ) |>
        dplyr::mutate(
          source_id = {
            scale_id <- get_scale_id_from_store()

            if (
              base::is.null(scale_id)
            ) {
              "unit"
            } else {
              scale_id
            }
          },
          tier_id = data_sjsdm_model_context[["tier_id"]][[1L]],
          taxonomic_resolution =
            data_sjsdm_model_context[["taxonomic_resolution"]][[1L]],
          response_family =
            data_sjsdm_model_context[["response_family"]][[1L]],
          predictor_structure =
            data_sjsdm_model_context[["predictor_structure"]][[1L]],
          candidate_table_hash =
            data_sjsdm_model_context[["candidate_table_hash"]][[1L]]
        )
    ),
    targets::tar_target(
      description = "Select one unit-CV regularization candidate",
      name = "data_sjsdm_selected_regularization_unit",
      command = select_sjsdm_regularization(
        data_tuning_summary = data_sjsdm_tuning_summary,
        selection_metric = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "selection_metric"
        )
      )
    ),
    targets::tar_target(
      description = "Read compatible shared tier regularization",
      name = "data_sjsdm_tier_regularization_artifact",
      command = read_sjsdm_tier_tuning_artifact(
        store_path = here::here(
          get_active_config("target_store"),
          "pipeline_sjsdm_tier_tuning"
        ),
        data_model_context = data_sjsdm_model_context
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Resolve regularization used by the final model fit",
      name = "model_regularization_for_fit",
      command = resolve_sjsdm_regularization_for_fit(
        data_feasibility = data_cross_validation_feasibility,
        data_model_context = data_sjsdm_model_context,
        data_unit_selection = data_sjsdm_selected_regularization_unit,
        data_tier_artifact =
          data_sjsdm_tier_regularization_artifact
      )
    ),
    targets::tar_target(
      description = "Rerun selected candidate and collect OOF predictions",
      name = "list_sjsdm_selected_fold_predictions",
      command = run_sjsdm_selected_candidate_folds(
        data_assignments = data_cross_validation_assignments,
        data_selected_candidate = model_regularization_for_fit,
        data_sample_ids = data_sample_ids_checked,
        taxon_names = base::colnames(data_community_model_matrix),
        prepare_fold_function = function(
            train_indices,
            test_indices,
            repeat_id,
            fold_id) {
          prepare_sjsdm_cross_validation_fold(
            data_community_matrix = data_community_model_matrix,
            data_abiotic_wide = data_abiotic_wide,
            data_coords_projected = data_coords_projected,
            data_sample_ids = data_sample_ids_checked,
            train_indices = train_indices,
            test_indices = test_indices,
            config_model_fitting = config_model_fitting,
            config_data_processing = config_data_processing,
            repeat_id = repeat_id,
            fold_id = fold_id
          )
        },
        fit_function = function(data_train_input, candidate, seed) {
          fit_sjsdm_regularization_candidate(
            data_train_input = data_train_input,
            candidate = candidate,
            sel_abiotic_formula = model_formula,
            config_model_fitting = config_model_fitting,
            seed = seed,
            device = purrr::chuck(
              config_model_fitting,
              "cross_validation",
              "fit_device"
            )
          )
        },
        predict_function = predict_sjsdm_probability_matrix,
        seed = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "fit_seed"
        )
      )
    ),
    targets::tar_target(
      description = "Selected-candidate out-of-fold prediction table",
      name = "data_sjsdm_out_of_fold_predictions",
      command = list_sjsdm_selected_fold_predictions |>
        purrr::chuck("data_predictions")
    ),
    targets::tar_target(
      description = "Selected-candidate out-of-fold fold diagnostics",
      name = "data_sjsdm_out_of_fold_diagnostics",
      command = list_sjsdm_selected_fold_predictions |>
        purrr::chuck("data_diagnostics")
    ),
    targets::tar_target(
      description = "Summarise CV and regularization provenance",
      name = "data_sjsdm_model_provenance",
      command = summarise_sjsdm_model_provenance(
        data_feasibility = data_cross_validation_feasibility,
        data_regularization = model_regularization_for_fit,
        data_fold_diagnostics =
          data_sjsdm_out_of_fold_diagnostics
      )
    ),
    targets::tar_target(
      description = "Evaluate selected out-of-fold predictions",
      name = "model_evaluation_cross_validated",
      command = evaluate_sjsdm_cross_validated_predictions(
        data_predictions = data_sjsdm_out_of_fold_predictions
      )
    ),
    targets::tar_target(
      description = "Evaluate selected predictions within CV folds",
      name = "data_sjsdm_fold_local_metrics",
      command = evaluate_sjsdm_fold_predictions(
        data_predictions = data_sjsdm_out_of_fold_predictions
      )
    ),
    targets::tar_target(
      description = "Aggregate selected fold-local prediction metrics",
      name = "list_sjsdm_fold_metric_summaries",
      command = summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_sjsdm_fold_local_metrics
      )
    ),
    targets::tar_target(
      description = "Summarise selected metrics across CV repeats",
      name = "list_sjsdm_metric_repeat_distributions",
      command = summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries =
          list_sjsdm_fold_metric_summaries
      )
    )
  )

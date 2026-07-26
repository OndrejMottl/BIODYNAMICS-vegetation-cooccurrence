#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#  {targets} pipe: Branch cross-validation assignments
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reuses shared pre-resolution assignments in a mapped response branch, then
#   defines branch tuning, selected predictions, and predictive evaluation.


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

pipe_segment_model_cross_validation_from_shared <-
  base::list(
    targets::tar_target(
      description = "Build response-branch cross-validation locations",
      name = "data_cross_validation_locations",
      command = make_cross_validation_location_table(
        data_sample_ids = data_sample_ids_checked,
        data_coords_projected = data_coords_projected
      )
    ),
    targets::tar_target(
      description = "Resolve response-branch cross-validation folds",
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
      description = stringr::str_c(
        "Reuse shared folds or create a documented branch fallback"
      ),
      name = "data_cross_validation_assignments_initial",
      command = make_cross_validation_branch_assignments(
        data_locations = data_cross_validation_locations,
        data_fold_resolution = data_cross_validation_fold_resolution,
        data_shared_assignments =
          data_cross_validation_assignments_shared,
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
      description = "Diagnose initial complete and held-out branch partitions",
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
      description = "Adapt branch folds toward leave-one-location-out",
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
      description = "Diagnose final complete and held-out branch partitions",
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
      description = "Classify response-branch CV feasibility",
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
      description = "Record branch model context for CV provenance",
      name = "data_sjsdm_model_context",
      command = tibble::tibble(
        tier_id = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "tier_id"
        ),
        taxonomic_resolution = base::as.character(resolution_id),
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
      description = "Validate the branch CV tuning schedule",
      name = "data_sjsdm_tuning_schedule",
      command = build_sjsdm_tuning_schedule(
        tuning_strategy = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "tuning_strategy"
        ),
        n_candidates = base::nrow(
          data_sjsdm_regularization_candidates
        ),
        repeat_ids = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "staged_search",
          "repeat_order"
        ),
        survivor_counts = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "staged_search",
          "survivor_counts"
        )
      )
    ),
    targets::tar_target(
      description = "Prepare each branch tuning fold once",
      name = "list_sjsdm_prepared_tuning_folds",
      command = prepare_sjsdm_tuning_folds(
        data_assignments = data_cross_validation_assignments,
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
        }
      )
    ),
    targets::tar_target(
      description = "Build every deterministic branch tuning work item",
      name = "data_sjsdm_all_tuning_work_items",
      command = {
        data_work_items <-
          build_sjsdm_tuning_work_items(
            data_assignments = data_cross_validation_assignments,
            data_candidates = data_sjsdm_regularization_candidates,
            seed = purrr::chuck(
              config_model_fitting,
              "cross_validation",
              "fit_seed"
            )
          )

        validate_sjsdm_tuning_repeat_coverage(
          data_work_items = data_work_items,
          data_schedule = data_sjsdm_tuning_schedule
        )

        data_work_items
      }
    ),
    targets::tar_target(
      description = "Discover branch tier-wide tuning decisions",
      name = "list_sjsdm_available_tier_decisions",
      command = if (
        data_sjsdm_tuning_schedule[["tuning_strategy"]][[1L]] ==
          "exhaustive"
      ) {
        base::list()
      } else {
        max_round <-
          base::Sys.getenv(
            "SJSMD_TUNING_MAX_ROUND",
            unset = base::as.character(
              base::nrow(data_sjsdm_tuning_schedule)
            )
          ) |>
          base::as.integer()

        assertthat::assert_that(
          base::is.finite(max_round),
          max_round >= 1L,
          max_round <= base::nrow(data_sjsdm_tuning_schedule),
          msg = "SJSMD_TUNING_MAX_ROUND is outside the schedule."
        )

        collect_sjsdm_available_tier_decisions(
          store_path = here::here(
            get_active_config("target_store"),
            "pipeline_sjsdm_tier_tuning"
          ),
          data_model_context = data_sjsdm_model_context,
          n_non_final_rounds = base::min(
            base::nrow(data_sjsdm_tuning_schedule) - 1L,
            max_round - 1L
          )
        )
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Authorize cumulative branch tuning work items",
      name = "data_sjsdm_tuning_work_items",
      command = if (
        data_sjsdm_tuning_schedule[["tuning_strategy"]][[1L]] ==
          "exhaustive"
      ) {
        data_sjsdm_all_tuning_work_items
      } else {
        build_sjsdm_cumulative_tuning_work_items(
          data_work_items = data_sjsdm_all_tuning_work_items,
          data_schedule = data_sjsdm_tuning_schedule,
          list_prior_decisions =
            list_sjsdm_available_tier_decisions
        )
      },
      iteration = "vector"
    ),
    targets::tar_target(
      description = "Execute one restartable branch candidate-fold fit",
      name = "list_sjsdm_tuning_work_item_result",
      command = run_sjsdm_tuning_work_item(
        data_work_item = data_sjsdm_tuning_work_items,
        list_prepared_folds = list_sjsdm_prepared_tuning_folds,
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
        epsilon = 1e-6
      ),
      pattern = map(data_sjsdm_tuning_work_items),
      iteration = "list"
    ),
    targets::tar_target(
      description = "Combine granular branch tuning outputs",
      name = "list_sjsdm_tuning_execution",
      command = combine_sjsdm_tuning_work_items(
        list_work_item_results =
          list_sjsdm_tuning_work_item_result
      )
    ),
    targets::tar_target(
      description = "Publish branch fold-level tuning metrics",
      name = "data_sjsdm_tuning_candidates",
      command = list_sjsdm_tuning_execution |>
        purrr::chuck("data_tuning")
    ),
    targets::tar_target(
      description = "Publish branch tuning-time OOF probability cache",
      name = "list_sjsdm_tuning_prediction_cache",
      command = list_sjsdm_tuning_execution |>
        purrr::chuck("list_prediction_cache")
    ),
    targets::tar_target(
      description = "Record branch tuning execution provenance",
      name = "data_sjsdm_tuning_execution_provenance",
      command = summarise_sjsdm_tuning_execution(
        data_tuning = data_sjsdm_tuning_candidates,
        data_schedule = data_sjsdm_tuning_schedule,
        data_work_items = data_sjsdm_tuning_work_items
      )
    ),
    targets::tar_target(
      description = "Collect branch fold and candidate stage timings",
      name = "data_sjsdm_tuning_stage_timings",
      command = collect_sjsdm_tuning_timings(
        list_prediction_cache =
          list_sjsdm_tuning_prediction_cache
      )
    ),
    targets::tar_target(
      description = "Summarise branch fold-level sjSDM tuning candidates",
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
      description = "Select one branch unit-CV regularization candidate",
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
      description = "Resolve regularization for the branch final model",
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
      description = "Assemble branch selected OOF predictions from cache",
      name = "list_sjsdm_selected_fold_predictions",
      command = assemble_sjsdm_cached_selected_folds(
        data_assignments = data_cross_validation_assignments,
        data_selected_candidate = model_regularization_for_fit,
        data_sample_ids = data_sample_ids_checked,
        taxon_names = base::colnames(data_community_model_matrix),
        list_prediction_cache =
          list_sjsdm_tuning_prediction_cache
      )
    ),
    targets::tar_target(
      description = "Branch selected-candidate OOF prediction table",
      name = "data_sjsdm_out_of_fold_predictions",
      command = list_sjsdm_selected_fold_predictions |>
        purrr::chuck("data_predictions")
    ),
    targets::tar_target(
      description = "Branch selected-candidate OOF fold diagnostics",
      name = "data_sjsdm_out_of_fold_diagnostics",
      command = list_sjsdm_selected_fold_predictions |>
        purrr::chuck("data_diagnostics")
    ),
    targets::tar_target(
      description = "Summarise branch CV and regularization provenance",
      name = "data_sjsdm_model_provenance",
      command = summarise_sjsdm_model_provenance(
        data_feasibility = data_cross_validation_feasibility,
        data_regularization = model_regularization_for_fit,
        data_fold_diagnostics =
          data_sjsdm_out_of_fold_diagnostics,
        fit_device = purrr::chuck(
          config_model_fitting,
          "cross_validation",
          "fit_device"
        )
      )
    ),
    targets::tar_target(
      description = "Evaluate branch selected OOF predictions",
      name = "model_evaluation_cross_validated",
      command = evaluate_sjsdm_cross_validated_predictions(
        data_predictions = data_sjsdm_out_of_fold_predictions
      )
    ),
    targets::tar_target(
      description = "Evaluate branch predictions within CV folds",
      name = "data_sjsdm_fold_local_metrics",
      command = evaluate_sjsdm_fold_predictions(
        data_predictions = data_sjsdm_out_of_fold_predictions
      )
    ),
    targets::tar_target(
      description = "Aggregate branch fold-local prediction metrics",
      name = "list_sjsdm_fold_metric_summaries",
      command = summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_sjsdm_fold_local_metrics
      )
    ),
    targets::tar_target(
      description = "Summarise branch metrics across CV repeats",
      name = "list_sjsdm_metric_repeat_distributions",
      command = summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries =
          list_sjsdm_fold_metric_summaries
      )
    )
  )

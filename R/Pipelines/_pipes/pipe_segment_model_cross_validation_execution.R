#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#  {targets} pipe: Model cross-validation execution
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines the common restartable tuning, selection, prediction, and
#   evaluation graph after route-specific assignment and model context.


pipe_segment_model_cross_validation_execution <-
  base::list(
    targets::tar_target(
      description = "Validate the shared CV tuning schedule",
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
      description = "Prepare each tuning fold once",
      name = "list_sjsdm_prepared_tuning_folds",
      command = prepare_sjsdm_tuning_folds(
        data_assignments = if (
          data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
            "none"
        ) {
          data_cross_validation_assignments[0L, , drop = FALSE]
        } else {
          data_cross_validation_assignments
        },
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
      description = "Build every deterministic candidate-fold work item",
      name = "data_sjsdm_all_tuning_work_items",
      command = {
        data_tuning_assignments <-
          if (
            data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
              "none"
          ) {
            data_cross_validation_assignments[0L, , drop = FALSE]
          } else {
            data_cross_validation_assignments
          }

        data_work_items <-
          build_sjsdm_tuning_work_items(
            data_assignments = data_tuning_assignments,
            data_candidates = data_sjsdm_regularization_candidates,
            seed = purrr::chuck(
              config_model_fitting,
              "cross_validation",
              "fit_seed"
            )
          )

        if (
          data_cross_validation_feasibility[["cv_strategy"]][[1L]] !=
            "none"
        ) {
          validate_sjsdm_tuning_repeat_coverage(
            data_work_items = data_work_items,
            data_schedule = data_sjsdm_tuning_schedule
          )
        }

        data_work_items
      }
    ),
    targets::tar_target(
      description = "Discover completed tier-wide tuning decisions",
      name = "list_sjsdm_available_tier_decisions",
      command = if (
        data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
          "none"
      ) {
        base::list()
      } else if (
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

        load_sjsdm_available_tier_decisions(
          store_path = here::here(
            load_active_config_value("target_store"),
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
      description = "Authorize cumulative staged tuning work items",
      name = "data_sjsdm_tuning_work_items",
      command = if (
        data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
          "none"
      ) {
        data_sjsdm_all_tuning_work_items
      } else if (
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
      description = "Guarantee a branch without materializing a model fit",
      name = "data_sjsdm_tuning_branch_work_items",
      command = build_sjsdm_tuning_branch_work_items(
        data_work_items = data_sjsdm_tuning_work_items
      ),
      iteration = "vector"
    ),
    targets::tar_target(
      description = "Execute one restartable candidate-fold fit",
      name = "list_sjsdm_tuning_work_item_result",
      command = run_sjsdm_tuning_work_item(
        data_work_item = data_sjsdm_tuning_branch_work_items,
        list_prepared_folds = list_sjsdm_prepared_tuning_folds,
        fit_function = function(data_train_input, candidate, seed) {
          fit_sjsdm_regularization_candidate(
            data_train_input = data_train_input,
            candidate = candidate,
            sel_abiotic_formula = formula_jsdm_environment,
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
      pattern = map(data_sjsdm_tuning_branch_work_items),
      iteration = "list"
    ),
    targets::tar_target(
      description = "Combine granular tuning metrics and predictions",
      name = "list_sjsdm_tuning_execution",
      command = aggregate_sjsdm_tuning_work_items(
        list_work_item_results =
          list_sjsdm_tuning_work_item_result
      )
    ),
    targets::tar_target(
      description = "Publish fold-level sjSDM tuning metrics",
      name = "data_sjsdm_candidate_fold_metrics",
      command = list_sjsdm_tuning_execution |>
        purrr::chuck("data_tuning")
    ),
    targets::tar_target(
      description = "Publish compact tuning-time OOF probability cache",
      name = "list_sjsdm_tuning_prediction_cache",
      command = list_sjsdm_tuning_execution |>
        purrr::chuck("list_prediction_cache")
    ),
    targets::tar_target(
      description = "Record tuning fit reuse and execution provenance",
      name = "data_sjsdm_tuning_execution_provenance",
      command = summarise_sjsdm_tuning_execution(
        data_tuning = data_sjsdm_candidate_fold_metrics,
        data_schedule = data_sjsdm_tuning_schedule,
        data_work_items = data_sjsdm_tuning_work_items
      )
    ),
    targets::tar_target(
      description = "Collect fold preparation and candidate stage timings",
      name = "data_sjsdm_tuning_stage_timings",
      command = summarise_sjsdm_tuning_timings(
        list_prediction_cache =
          list_sjsdm_tuning_prediction_cache
      )
    ),
    targets::tar_target(
      description = "Summarise fold-level sjSDM tuning candidates",
      name = "data_sjsdm_candidate_repeat_summary",
      command = summarise_sjsdm_tuning_candidates(
        data_tuning = data_sjsdm_candidate_fold_metrics
      ) |>
        dplyr::mutate(
          source_id = {
            scale_id <-
              resolve_scale_id_from_store()

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
      description = "Publish the sjSDM CV tuning v2 artifact",
      name = "list_sjsdm_cv_tuning_artifact",
      command = build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_cv_tuning",
        payload = base::list(
          data_candidates = data_sjsdm_regularization_candidates,
          data_schedule = data_sjsdm_tuning_schedule,
          data_candidate_fold_metrics =
            data_sjsdm_candidate_fold_metrics,
          data_candidate_repeat_summary =
            data_sjsdm_candidate_repeat_summary,
          data_stage_timings = data_sjsdm_tuning_stage_timings,
          data_execution_provenance =
            data_sjsdm_tuning_execution_provenance,
          list_prediction_cache =
            list_sjsdm_tuning_prediction_cache
        ),
        pipeline_id = fs::path_ext_remove(
          fs::path_file(targets::tar_config_get("script"))
        ),
        configuration_profile = base::Sys.getenv("R_CONFIG_ACTIVE")
      )
    ),
    targets::tar_target(
      description = "Select one unit-CV regularization candidate",
      name = "data_sjsdm_unit_regularization_selection",
      command = if (
        data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
          "none"
      ) {
        build_sjsdm_empty_unit_regularization_selection()
      } else {
        select_sjsdm_regularization(
          data_tuning_summary = data_sjsdm_candidate_repeat_summary,
          selection_metric = purrr::chuck(
            config_model_fitting,
            "cross_validation",
            "selection_metric"
          )
        )
      }
    ),
    targets::tar_target(
      description = "Read compatible shared tier regularization",
      name = "data_sjsdm_tier_regularization_artifact",
      command = if (
        data_cross_validation_feasibility[["cv_feasibility_status"]][[1L]] ==
          "full_model_infeasible"
      ) {
        build_sjsdm_empty_tier_regularization_selection()
      } else {
        load_sjsdm_tier_tuning_artifact(
          store_path = here::here(
            load_active_config_value("target_store"),
            "pipeline_sjsdm_tier_tuning"
          ),
          data_model_context = data_sjsdm_model_context
        )
      },
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = "Resolve regularization used by the final model fit",
      name = "data_sjsdm_regularization_selection_for_fit",
      command = resolve_sjsdm_regularization_for_fit(
        data_feasibility = data_cross_validation_feasibility,
        data_model_context = data_sjsdm_model_context,
        data_unit_selection = data_sjsdm_unit_regularization_selection,
        data_tier_artifact =
          data_sjsdm_tier_regularization_artifact
      )
    ),
    targets::tar_target(
      description = "Publish the regularization-selection v2 artifact",
      name = "list_sjsdm_regularization_selection_artifact",
      command = build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_regularization_selection",
        payload = base::list(
          data_unit_selection =
            data_sjsdm_unit_regularization_selection,
          data_tier_selection =
            data_sjsdm_tier_regularization_artifact,
          data_selection_for_fit =
            data_sjsdm_regularization_selection_for_fit
        ),
        pipeline_id = fs::path_ext_remove(
          fs::path_file(targets::tar_config_get("script"))
        ),
        configuration_profile = base::Sys.getenv("R_CONFIG_ACTIVE")
      )
    ),
    targets::tar_target(
      description = "Assemble selected OOF predictions from tuning cache",
      name = "list_sjsdm_selected_fold_artifacts",
      command = if (
        data_cross_validation_feasibility[["cv_strategy"]][[1L]] ==
          "none"
      ) {
        build_sjsdm_empty_selected_fold_artifacts()
      } else {
        build_sjsdm_cached_selected_folds(
          data_assignments = data_cross_validation_assignments,
          data_selected_candidate = data_sjsdm_regularization_selection_for_fit,
          data_sample_ids = data_sample_ids_checked,
          taxon_names = base::colnames(data_community_model_matrix),
          list_prediction_cache =
            list_sjsdm_tuning_prediction_cache
        )
      }
    ),
    targets::tar_target(
      description = "Selected-candidate out-of-fold prediction table",
      name = "data_sjsdm_out_of_fold_predictions",
      command = list_sjsdm_selected_fold_artifacts |>
        purrr::chuck("data_predictions")
    ),
    targets::tar_target(
      description = "Selected-candidate out-of-fold fold diagnostics",
      name = "data_sjsdm_out_of_fold_diagnostics",
      command = list_sjsdm_selected_fold_artifacts |>
        purrr::chuck("data_diagnostics")
    ),
    targets::tar_target(
      description = "Publish the selected OOF prediction v2 artifact",
      name = "list_sjsdm_cv_prediction_artifact",
      command = build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = data_sjsdm_out_of_fold_predictions,
          data_fold_diagnostics =
            data_sjsdm_out_of_fold_diagnostics
        ),
        pipeline_id = fs::path_ext_remove(
          fs::path_file(targets::tar_config_get("script"))
        ),
        configuration_profile = base::Sys.getenv("R_CONFIG_ACTIVE")
      )
    ),
    targets::tar_target(
      description = "Summarise CV and regularization provenance",
      name = "data_sjsdm_cv_model_provenance",
      command = summarise_sjsdm_model_provenance(
        data_feasibility = data_cross_validation_feasibility,
        data_regularization = data_sjsdm_regularization_selection_for_fit,
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
      description = "Evaluate selected out-of-fold predictions",
      name = "list_sjsdm_pooled_cv_evaluation",
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
    ),
    targets::tar_target(
      description = "Publish the cross-validated evaluation v2 artifact",
      name = "list_sjsdm_cv_evaluation_artifact",
      command = build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_cv_evaluation",
        payload = base::list(
          list_pooled_evaluation = list_sjsdm_pooled_cv_evaluation,
          data_fold_metrics = data_sjsdm_fold_local_metrics,
          list_fold_summaries = list_sjsdm_fold_metric_summaries,
          list_repeat_distributions =
            list_sjsdm_metric_repeat_distributions,
          data_model_provenance = data_sjsdm_cv_model_provenance
        ),
        pipeline_id = fs::path_ext_remove(
          fs::path_file(targets::tar_config_get("script"))
        ),
        configuration_profile = base::Sys.getenv("R_CONFIG_ACTIVE")
      )
    )
  )

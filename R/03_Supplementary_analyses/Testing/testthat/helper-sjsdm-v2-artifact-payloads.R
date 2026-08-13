make_sjsdm_tier_payload_fixture <- function(
    schema_version = "2.0.0") {
  data_tuning_summary <-
    tidyr::crossing(
      source_id = base::c("id_a", "id_b"),
      repeat_id = 1:2,
      candidate_id = base::c(
        "candidate_001",
        "candidate_002"
      )
    ) |>
    dplyr::mutate(
      tier_id = "regional",
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = "abiotic_spatial",
      candidate_table_hash = "candidate_hash",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = dplyr::if_else(
        .data[["candidate_id"]] == "candidate_001",
        0.1,
        0.2
      ),
      lambda_coef = 0.1,
      lambda_spatial = 0.1,
      n_response_values = 100L,
      negative_log_likelihood_per_response =
        dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.2,
          0.5
        ),
      summary_status = "ok"
    )

  list_artifacts <-
    build_sjsdm_tier_tuning_artifacts(
      data_tuning_summary = data_tuning_summary,
      created_at = base::as.POSIXct(
        "2026-08-11 12:00:00",
        tz = "UTC"
      )
    )

  data_selection <-
    list_artifacts[["data_artifacts"]] |>
    dplyr::mutate(
      artifact_schema_version = schema_version
    )

  res <-
    base::list(
      list_round_decisions = base::list(),
      data_regularization_selection = data_selection,
      data_source_candidate_loss =
        list_artifacts[["data_source_candidate_loss"]],
      data_candidate_aggregation =
        list_artifacts[["data_candidate_aggregation"]],
      data_selection_sensitivity =
        list_artifacts[["data_selection_sensitivity"]]
    )

  return(res)
}

make_sjsdm_common_payload_fixture <- function(
    schema_version = "2.0.0") {
  data_tuning_summary <-
    tidyr::crossing(
      tier_id = base::c("continental", "regional", "local"),
      source_id = base::c("id_a", "id_b"),
      repeat_id = 1L,
      candidate_id = base::c(
        "candidate_001",
        "candidate_002"
      )
    ) |>
    dplyr::mutate(
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = dplyr::case_when(
        .data[["tier_id"]] == "continental" ~ "n_mev=5",
        .data[["tier_id"]] == "regional" ~ "n_mev=4",
        TRUE ~ "n_mev=3"
      ),
      candidate_table_hash = "candidate_hash",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = dplyr::if_else(
        .data[["candidate_id"]] == "candidate_001",
        0,
        0.1
      ),
      lambda_coef = 0,
      lambda_spatial = 0,
      n_response_values = 100L,
      negative_log_likelihood_per_response =
        dplyr::case_when(
          .data[["tier_id"]] == "continental" &
            .data[["candidate_id"]] == "candidate_001" ~ 0.1,
          .data[["tier_id"]] == "continental" ~ 0.4,
          .data[["candidate_id"]] == "candidate_001" ~ 0.9,
          TRUE ~ 0.2
        ),
      summary_status = "ok"
    )

  list_artifacts <-
    build_sjsdm_common_regularization_artifacts(
      data_tuning_summary = data_tuning_summary,
      created_at = base::as.POSIXct(
        "2026-08-11 12:00:00",
        tz = "UTC"
      )
    )

  data_selection <-
    list_artifacts[["data_artifacts"]] |>
    dplyr::mutate(
      artifact_schema_version = schema_version
    )

  data_model_index <-
    tibble::tibble(
      model_id = "regional/id_a/genus",
      tier_id = "regional",
      scale_id = "id_a",
      resolution_id = "genus",
      store_path = "Data/targets/regional"
    )

  data_provenance <-
    tibble::tibble(
      model_id = "regional/id_a/genus",
      tier_id = "regional",
      scale_id = "id_a",
      resolution_id = "genus",
      predictor_structure = "n_mev=4",
      candidate_table_hash = "candidate_hash",
      cv_strategy = "grouped_kfold",
      effective_folds = 5L,
      n_locations = 10L,
      n_samples = 100L,
      n_taxa = 20L,
      n_effective_mev = 4L,
      candidate_id = "candidate_002",
      regularization_source =
        "common_spatial_sensitivity",
      source_tier = "common_spatial",
      weighting_rule = "equal_tier_equal_id",
      fit_status = "ok",
      fit_error = NA_character_
    )

  res <-
    base::list(
      data_regularization_selection = data_selection,
      data_candidate_aggregation =
        list_artifacts[["data_candidate_aggregation"]],
      data_model_index = data_model_index,
      data_sensitivity_provenance = data_provenance
    )

  return(res)
}

make_sjsdm_prediction_payload_fixture <- function() {
  list_empty <-
    build_sjsdm_empty_selected_fold_artifacts()

  res <-
    base::list(
      data_predictions = list_empty[["data_predictions"]],
      data_fold_diagnostics = list_empty[["data_diagnostics"]]
    )

  return(res)
}

make_cross_validation_design_payload_fixture <- function() {
  data_locations <-
    tibble::tibble(
      location_id = base::character(),
      coord_x_km = base::numeric(),
      coord_y_km = base::numeric(),
      n_samples = base::integer(),
      row_indices = base::list()
    )

  data_assignments <-
    tibble::tibble(
      repeat_id = base::integer(),
      fold_id = base::integer(),
      location_id = base::character(),
      grid_cell_id = base::character(),
      n_samples = base::integer(),
      row_indices = base::list(),
      cv_strategy = base::character(),
      assignment_source = base::character()
    )

  data_diagnostics <-
    tibble::tibble(
      cv_strategy = base::character(),
      repeat_id = base::integer(),
      effective_folds = base::integer(),
      fold_id = base::integer(),
      n_train_locations = base::integer(),
      n_train_samples = base::integer(),
      n_train_taxa = base::integer(),
      n_train_mem_locations = base::integer()
    )

  res <-
    base::list(
      data_locations = data_locations,
      data_fold_resolution = tibble::tibble(
        n_locations = 0L,
        default_folds = 5L,
        effective_folds = 0L,
        min_train_locations = 2L,
        min_training_locations_actual = 0L,
        cv_strategy = "none",
        cv_feasibility_status = "full_model_infeasible"
      ),
      data_assignments_initial = data_assignments,
      data_partition_diagnostics_initial = data_diagnostics,
      data_assignments = data_assignments,
      data_partition_diagnostics = data_diagnostics,
      data_feasibility = tibble::tibble(
        n_locations = 0L,
        n_samples = 0L,
        n_taxa = 0L,
        n_mem_locations = 0L,
        full_model_feasible = FALSE,
        grouped_kfold_feasible = FALSE,
        leave_one_location_out_feasible = FALSE,
        cv_strategy = "none",
        effective_folds = 0L,
        cv_feasibility_status = "full_model_infeasible"
      ),
      data_route_provenance = tibble::tibble(
        assignment_route = "direct",
        assignment_source = "branch_no_holdout",
        assignment_seed = NA_integer_
      )
    )

  return(res)
}

make_cross_validation_shared_payload_fixture <- function() {
  res <-
    base::list(
      data_sample_ids = tibble::tibble(
        dataset_name = "site_a",
        age = 0
      ),
      data_locations = tibble::tibble(
        location_id = "site_a",
        coord_x_km = 1,
        coord_y_km = 2,
        n_samples = 1L,
        row_indices = base::list(1L)
      ),
      data_fold_resolution = tibble::tibble(
        n_locations = 1L,
        default_folds = 5L,
        effective_folds = 1L,
        min_train_locations = 1L,
        min_training_locations_actual = 1L,
        cv_strategy = "leave_one_location_out",
        cv_feasibility_status =
          "leave_one_location_out_required"
      ),
      data_grid_candidates = tibble::tibble(
        candidate_id = "grid_001",
        grid_cell_size_km = 10,
        baseline_grid_cell_size_km = 10,
        grid_size_multiplier = 1,
        n_locations = 1L,
        extent_x_km = 0,
        extent_y_km = 0,
        extent_area_km2 = 0,
        target_locations_per_cell = 1L
      ),
      data_grid_calibration = tibble::tibble(
        grid_cell_size_km = 10,
        mean_occupied_cells = 1,
        minimum_locations_per_cell = 1L,
        lower_quantile_locations_per_cell = 1,
        median_locations_per_cell = 1,
        occupancy_criterion = "minimum",
        occupancy_value = 1,
        target_locations_per_cell = 1L,
        maximum_fold_location_difference = 0L,
        maximum_fold_sample_difference = 0L,
        eligible = TRUE,
        selected = TRUE,
        selection_status = "selected"
      ),
      data_assignments = tibble::tibble(
        repeat_id = 1L,
        fold_id = 1L,
        location_id = "site_a",
        grid_cell_id = NA_character_,
        n_samples = 1L,
        row_indices = base::list(1L),
        cv_strategy = "leave_one_location_out",
        assignment_source = "shared_pre_resolution"
      ),
      data_assignment_provenance = tibble::tibble(
        assignment_source = "shared_pre_resolution",
        assignment_seed = 900723L
      )
    )

  return(res)
}

make_sjsdm_tuning_payload_fixture <- function() {
  data_candidates <-
    build_sjsdm_regularization_candidates(
      alpha_cov = 0,
      alpha_coef = 0,
      alpha_spatial = 0,
      lambda_cov = 0.1,
      lambda_coef = 0.1,
      lambda_spatial = 0.1
    )

  data_schedule <-
    build_sjsdm_tuning_schedule(
      tuning_strategy = "exhaustive",
      n_candidates = 1L,
      repeat_ids = 1L
    )

  data_metrics <-
    build_sjsdm_empty_tuning_result()[["data_tuning"]]

  data_summary <-
    summarise_sjsdm_tuning_candidates(data_metrics) |>
    dplyr::mutate(
      source_id = base::character(),
      tier_id = base::character(),
      taxonomic_resolution = base::character(),
      response_family = base::character(),
      predictor_structure = base::character(),
      candidate_table_hash = base::character()
    )

  res <-
    base::list(
      data_candidates = data_candidates,
      data_schedule = data_schedule,
      data_candidate_fold_metrics = data_metrics,
      data_candidate_repeat_summary = data_summary,
      data_stage_timings = summarise_sjsdm_tuning_timings(
        list_prediction_cache = base::list()
      ),
      data_execution_provenance = summarise_sjsdm_tuning_execution(
        data_tuning = data_metrics,
        data_schedule = data_schedule
      ),
      list_prediction_cache = base::list()
    )

  return(res)
}

make_sjsdm_tuning_artifact_fixture <- function(
    source_id = "unit",
    taxonomic_resolution = "genus",
    with_evidence = TRUE) {
  payload <-
    make_sjsdm_tuning_payload_fixture()

  if (
    with_evidence
  ) {
    payload[["data_candidate_repeat_summary"]] <-
      tibble::tibble(
        repeat_id = 1L,
        candidate_id = "candidate_001",
        alpha_cov = 0,
        alpha_coef = 0,
        alpha_spatial = 0,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        n_folds_total = 1L,
        n_folds_successful = 1L,
        n_response_values = 1L,
        negative_log_likelihood_test = 0.1,
        negative_log_likelihood_per_response = 0.1,
        auc_macro_test = 0.7,
        summary_status = "ok",
        cv_strategy = "spatially_stratified_group_kfold",
        regularization_source = "unit_cv",
        source_id = source_id,
        tier_id = "paleo",
        taxonomic_resolution = taxonomic_resolution,
        response_family = "binomial",
        predictor_structure = "full",
        candidate_table_hash = "candidate_hash"
      )
  }

  res <-
    build_sjsdm_artifact_envelope(
      artifact_type = "sjsdm_cv_tuning",
      payload = payload,
      provenance = build_sjsdm_artifact_provenance(
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test"
      )
    )

  return(res)
}

make_sjsdm_evaluation_payload_fixture <- function() {
  data_predictions <-
    build_sjsdm_empty_selected_fold_artifacts()[[
      "data_predictions"
    ]]

  list_pooled <-
    evaluate_sjsdm_cross_validated_predictions(data_predictions)

  data_fold_metrics <-
    evaluate_sjsdm_fold_predictions(data_predictions)

  list_fold_summaries <-
    summarise_sjsdm_fold_metrics(data_fold_metrics)

  list_repeat_distributions <-
    summarise_sjsdm_metric_repeats(list_fold_summaries)

  data_model_provenance <-
    summarise_sjsdm_model_provenance(
      data_feasibility = tibble::tibble(
        n_locations = 5L,
        n_samples = 20L,
        n_taxa = 4L,
        n_mem_locations = 5L,
        cv_strategy = "none",
        effective_folds = NA_integer_,
        cv_feasibility_status =
          "tier_pooled_regularization_required"
      ),
      data_regularization = tibble::tibble(
        tier_id = "paleo_spatial_local",
        taxonomic_resolution = "family",
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_001",
        regularization_source = "tier_pooled",
        source_tier = "paleo_spatial_local",
        selection_status = "selected"
      ),
      data_fold_diagnostics = tibble::tibble(),
      fit_device = "cpu"
    )

  res <-
    base::list(
      list_pooled_evaluation = list_pooled,
      data_fold_metrics = data_fold_metrics,
      list_fold_summaries = list_fold_summaries,
      list_repeat_distributions = list_repeat_distributions,
      data_model_provenance = data_model_provenance
    )

  return(res)
}

make_sjsdm_selection_payload_fixture <- function() {
  res <-
    base::list(
      data_unit_selection =
        build_sjsdm_empty_unit_regularization_selection(),
      data_tier_selection =
        build_sjsdm_empty_tier_regularization_selection(),
      data_selection_for_fit = tibble::tibble(
        tier_id = "paleo",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "full",
        candidate_table_hash = "candidate_hash",
        candidate_id = NA_character_,
        alpha_cov = NA_real_,
        alpha_coef = NA_real_,
        alpha_spatial = NA_real_,
        lambda_cov = NA_real_,
        lambda_coef = NA_real_,
        lambda_spatial = NA_real_,
        cv_feasibility_status = "full_model_infeasible",
        regularization_source = "none",
        source_tier = NA_character_,
        selection_status = "full_model_infeasible"
      )
    )

  return(res)
}

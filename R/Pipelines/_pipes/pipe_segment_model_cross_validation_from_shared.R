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
      command = build_cross_validation_location_table(
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
      command = build_cross_validation_branch_assignments(
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
      command = diagnose_cross_validation_partitions(
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
      command = resolve_cross_validation_assignments(
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
      command = diagnose_cross_validation_partitions(
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
      command = resolve_cross_validation_strategy(
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
      command = build_sjsdm_regularization_candidates(
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
      description = "Publish the shared-route CV design v2 artifact",
      name = "list_cross_validation_design_artifact",
      command = build_sjsdm_pipeline_artifact(
        artifact_type = "cross_validation_design",
        payload = base::list(
          data_locations = data_cross_validation_locations,
          data_fold_resolution = data_cross_validation_fold_resolution,
          data_assignments_initial =
            data_cross_validation_assignments_initial,
          data_partition_diagnostics_initial =
            data_cross_validation_partition_diagnostics_initial,
          data_assignments = data_cross_validation_assignments,
          data_partition_diagnostics =
            data_cross_validation_partition_diagnostics,
          data_feasibility = data_cross_validation_feasibility,
          data_route_provenance = tibble::tibble(
            assignment_route = "shared_assignment_branch",
            assignment_source = dplyr::first(
              data_cross_validation_assignments[["assignment_source"]],
              default = "unknown"
            )
          )
        ),
        pipeline_id = fs::path_ext_remove(
          fs::path_file(targets::tar_config_get("script"))
        ),
        configuration_profile = base::Sys.getenv("R_CONFIG_ACTIVE")
      )
    )
  )

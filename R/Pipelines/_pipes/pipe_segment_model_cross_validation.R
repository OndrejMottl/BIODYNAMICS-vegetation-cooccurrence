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
# Defines lightweight per-ID fold assignment and feasibility targets.


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
    )
  )

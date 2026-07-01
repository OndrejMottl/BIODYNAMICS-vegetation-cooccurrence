#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   {targets} pipe: Shared cross-validation assignments
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds one pre-resolution location assignment from Plantae observations
#   with valid abiotic predictors and coordinates.


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

pipe_segment_model_cross_validation_shared <-
  base::list(
    targets::tar_target(
      description = "Read shared cross-validation configuration",
      name = "config_cross_validation_shared",
      command = get_active_config(
        value = base::c("model_fitting", "cross_validation")
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Define predictor-valid samples before taxonomic-resolution",
        " filtering"
      ),
      name = "data_cross_validation_sample_ids_shared",
      command = align_sample_ids(
        data_community_long = data_community_plantae,
        data_abiotic_long = data_abiotic_analysis |>
          dplyr::group_by(
            dplyr::across(
              dplyr::all_of(base::c("dataset_name", "age"))
            )
          ) |>
          dplyr::filter(base::all(!base::is.na(.data[["abiotic_value"]]))) |>
          dplyr::ungroup(),
        data_coords = data_coords_analysis
      )
    ),
    targets::tar_target(
      description = "Build shared pre-resolution location table",
      name = "data_cross_validation_locations_shared",
      command = make_cross_validation_location_table(
        data_sample_ids = data_cross_validation_sample_ids_shared,
        data_coords_projected = data_coords_projected
      )
    ),
    targets::tar_target(
      description = "Resolve shared pre-resolution fold count",
      name = "data_cross_validation_fold_resolution_shared",
      command = resolve_cross_validation_fold_count(
        n_locations = base::nrow(
          data_cross_validation_locations_shared
        ),
        min_train_locations = base::max(
          purrr::chuck(config_data_processing, "min_n_cores"),
          purrr::chuck(
            config_cross_validation_shared,
            "min_mem_locations"
          )
        ),
        default_folds = purrr::chuck(
          config_cross_validation_shared,
          "default_folds"
        )
      )
    ),
    targets::tar_target(
      description = "Derive shared pre-resolution grid candidates",
      name = "data_cross_validation_grid_candidates_shared",
      command = make_cross_validation_grid_candidates_from_resolution(
        data_locations = data_cross_validation_locations_shared,
        data_fold_resolution =
          data_cross_validation_fold_resolution_shared,
        target_locations_per_cell = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "target_locations_per_cell"
        ),
        grid_size_multipliers = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "size_multipliers"
        )
      )
    ),
    targets::tar_target(
      description = "Calibrate the shared pre-resolution spatial grid",
      name = "data_cross_validation_grid_calibration_shared",
      command = calibrate_cross_validation_grid_from_resolution(
        data_locations = data_cross_validation_locations_shared,
        data_fold_resolution =
          data_cross_validation_fold_resolution_shared,
        candidate_grid_cell_sizes_km = dplyr::pull(
          data_cross_validation_grid_candidates_shared,
          "grid_cell_size_km"
        ),
        n_repeats = purrr::chuck(
          config_cross_validation_shared,
          "assignment_repeats"
        ),
        occupancy_criterion = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "occupancy_criterion"
        ),
        target_locations_per_cell = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "target_locations_per_cell"
        ),
        lower_quantile_probability = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "lower_quantile_probability"
        ),
        max_fold_location_difference = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "max_fold_location_difference"
        ),
        max_fold_sample_difference = purrr::chuck(
          config_cross_validation_shared,
          "grid",
          "max_fold_sample_difference"
        ),
        seed = purrr::chuck(
          config_cross_validation_shared,
          "assignment_seed"
        )
      )
    ),
    targets::tar_target(
      description = "Assign shared pre-resolution locations to folds",
      name = "data_cross_validation_assignments_shared",
      command = make_cross_validation_assignments_from_resolution(
        data_locations = data_cross_validation_locations_shared,
        data_fold_resolution =
          data_cross_validation_fold_resolution_shared,
        data_grid_calibration =
          data_cross_validation_grid_calibration_shared,
        n_repeats = purrr::chuck(
          config_cross_validation_shared,
          "assignment_repeats"
        ),
        seed = purrr::chuck(
          config_cross_validation_shared,
          "assignment_seed"
        ),
        assignment_source = "shared_pre_resolution"
      )
    )
  )

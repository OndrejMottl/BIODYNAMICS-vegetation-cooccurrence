#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Shared spatial predictors
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Defines spatial predictor targets that can be shared across
#   downstream target branches.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_model_spatial_shared <-
  list(
    targets::tar_target(
      description = "Shared spatial-predictor configuration",
      name = "config_spatial_predictors",
      command = base::list(
        use_spatial = load_active_config_value(
          value = c("model_fitting", "use_spatial")
        ),
        spatial_mode = load_active_config_value(
          value = c("model_fitting", "spatial_mode")
        ),
        spatial_crs = load_active_config_value(
          value = c("model_fitting", "spatial_crs")
        ),
        n_mev = load_active_config_value(
          value = c("model_fitting", "n_mev")
        ),
        spatial_mev = load_active_config_value(
          value = c("model_fitting", "spatial_mev")
        )
      ),
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Project shared coordinates to metric km using ",
        "the configured target CRS"
      ),
      name = "data_coords_projected",
      command = project_coords_to_metric(
        data_coords = data_coords_analysis,
        target_crs = config_spatial_predictors |>
          purrr::chuck("spatial_crs")
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Compute reusable shared 2-D Moran eigenvector basis from ",
        "core km locations"
      ),
      name = "list_spatial_mev_core_basis",
      command = compute_shared_spatial_mev_basis(
        data_coords_projected = data_coords_projected,
        config_spatial_predictors = config_spatial_predictors
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Expose shared 2-D Moran eigenvectors with the existing ",
        "public data-frame schema"
      ),
      name = "data_spatial_mev_core",
      command = extract_spatial_mev_basis_component(
        list_spatial_mev_basis = list_spatial_mev_core_basis,
        component_name = "data_mev"
      )
    ),
    targets::tar_target(
      description = stringr::str_c(
        "Record the shared spatial MEM strategy, basis size, ",
        "projection method, and timing"
      ),
      name = "data_spatial_mev_provenance",
      command = extract_spatial_mev_basis_component(
        list_spatial_mev_basis = list_spatial_mev_core_basis,
        component_name = "data_provenance"
      )
    )
  )

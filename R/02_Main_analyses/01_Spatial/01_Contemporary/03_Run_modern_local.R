#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Run modern spatial pipeline: local
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Iterates over all local spatial units and runs
#   pipeline_modern_spatial_resolution.R for each unit.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Set active configuration -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_local")


#----------------------------------------------------------#
# 2. Load spatial units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(
    .data$scale == "local"
  ) |>
  dplyr::pull(scale_id)


#----------------------------------------------------------#
# 3. Run resolution pipeline for each spatial unit -----
#----------------------------------------------------------#

tictoc::tic(
  "Running modern resolution pipelines for all local units"
)
purrr::walk(
  .progress = TRUE,
  .x = vec_scale_ids,
  .f = ~ {
    base::message(
      "\n\nRunning modern resolution pipeline for spatial unit: ", .x, "\n\n"
    )
    run_pipeline(
      sel_script = "R/Pipelines/pipeline_modern_spatial_resolution.R",
      store_suffix = .x
    )
  }
)
tictoc::toc()

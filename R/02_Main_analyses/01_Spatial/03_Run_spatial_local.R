#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Run spatial scale pipeline: local
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Iterates over all local spatial units defined in
#   Data/Input/spatial_grid.csv and runs pipeline_spatial_resolution.R
#   for each one in sequence (genus + family + functional_type).
# Each unit gets an isolated targets store at:
#   Data/targets/spatial_local/{scale_id}/pipeline_spatial_resolution/


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

Sys.setenv(R_CONFIG_ACTIVE = "project_spatial_local")


#----------------------------------------------------------#
# 2. Load spatial units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(scale == "local") |>
  dplyr::pull(scale_id)


#----------------------------------------------------------#
# 3. Run resolution pipeline for each spatial unit -----
#----------------------------------------------------------#

tictoc::tic(
  "Running resolution pipelines (genus + family + FT) for all local units"
)
purrr::walk(
  .x = vec_scale_ids,
  .progress = TRUE,
  .f = ~ {
    base::message(
      "\n\nRunning resolution pipeline for spatial unit: ", .x, "\n\n"
    )
    run_pipeline(
      sel_script = "R/02_Main_analyses/pipeline_spatial_resolution.R",
      store_suffix = .x
    )
  }
)
tictoc::toc()
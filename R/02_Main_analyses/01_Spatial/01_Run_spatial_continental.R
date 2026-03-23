#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Run spatial scale pipeline: continental
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Iterates over all continental spatial units defined in
#   Data/Input/spatial_grid.csv and runs pipeline_basic.R
#   for each one in sequence.
# Each unit gets an isolated targets store at:
#   Data/targets/spatial_continental/{scale_id}/pipeline_basic/


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

Sys.setenv(R_CONFIG_ACTIVE = "project_spatial_continental")


#----------------------------------------------------------#
# 2. Load spatial units -----
#----------------------------------------------------------#

vec_scale_ids <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(scale == "continental") |>
  dplyr::pull(scale_id)


#----------------------------------------------------------#
# 3. Run pipeline for each spatial unit -----
#----------------------------------------------------------#

tictoc::tic("Running spatial pipelines for all continental units")
purrr::walk(
  .progress = TRUE,
  .x = vec_scale_ids,
  .f = ~ {
    message("\n\nRunning pipeline for spatial unit: ", .x, "\n\n")
    run_pipeline(
      sel_script = "R/02_Main_analyses/pipeline_basic.R",
      store_suffix = .x
    )
  }
)
tictoc::toc()
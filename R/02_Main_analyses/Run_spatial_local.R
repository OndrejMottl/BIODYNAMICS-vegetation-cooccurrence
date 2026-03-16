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
#   Data/Input/spatial_grid.csv and runs pipeline_basic.R
#   for each one in sequence.
# Each unit gets an isolated targets store at:
#   Data/targets/spatial_local/{scale_id}/pipeline_basic/


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
# 3. Run pipeline for each spatial unit -----
#----------------------------------------------------------#

purrr::walk(
  .x = vec_scale_ids,
  .f = ~ {
    Sys.setenv(R_SPATIAL_ID = .x)
    run_pipeline(
      sel_script = "R/02_Main_analyses/pipeline_basic.R",
      store_suffix = .x,
      level_separation = 100
    )
  }
)

# Clear spatial ID after iteration
Sys.unsetenv("R_SPATIAL_ID")


#----------------------------------------------------------#
# 4.Gather information about the results -----
#----------------------------------------------------------#

data_targets_spatial_local_meta <-
  tibble::tibble(
    scale_id = vec_scale_ids,
    store_path = here::here(
      "Data/targets/spatial_local",
      vec_scale_ids,
      "pipeline_basic"
    )
  ) |>
  dplyr::mutate(
    store_exists = fs::dir_exists(store_path),
    has_errors = purrr::map2_lgl(
      .x = store_path,
      .y = store_exists,
      .f = ~ {
        if (isFALSE(.y)) {
          return(NA)
        }
        targets::tar_meta(
          fields = c("name", "error"),
          complete_only = TRUE,
          store = .x
        ) %>%
          {
            nrow(.) > 0
          }
      }
    ),
    succesfull = store_exists & !has_errors
  )

data_targets_spatial_local_successful <-
  data_targets_spatial_local_meta |>
  dplyr::filter(succesfull)

data_targets_spatial_local_successful |>
  dplyr::mutate(
    selected_ab_predictors = purrr::map(
      .x = store_path,
      .f = ~ targets::tar_read(
        "abiotic_collinearity",
        store = .x
      ) |>
        purrr::chuck("result", "selection") |>
        as.character()
    ),
    model_anova = purrr::map(
      .x = store_path,
      .f = ~ {
        targets::tar_read(
          "model_anova",
          store = .x
        )
      }
    ),
    anova_results = purrr::map(
      .x = model_anova,
      .f = ~ extract_anova_fractions(
        anova_object = .x,
        vec_anova_fractions = c("F_B", "F_AB", "F_BS", "F_ABS"),
        clamp_negative = TRUE
      )
    )
  )


anova_object <-
  targets::tar_read(
    "model_anova",
    store = data_targets_spatial_local_successful$store_path[[1]]
  )

targets::tar_read(
  "model_anova",
  store = data_targets_spatial_local_successful$store_path[[1]]
) |>
  extract_anova_fractions(
    vec_anova_fractions = c("F_B", "F_AB", "F_BS", "F_ABS"),
    clamp_negative = TRUE
  )

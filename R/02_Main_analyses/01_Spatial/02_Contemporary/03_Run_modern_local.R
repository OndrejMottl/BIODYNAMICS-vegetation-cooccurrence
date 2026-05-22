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
vec_pipeline_errors <-
  vec_scale_ids |>
  rlang::set_names() |>
  purrr::map_chr(
    .progress = TRUE,
    .f = ~ {
      base::message(
        "\n\nRunning modern resolution pipeline for spatial unit: ",
        .x,
        "\n\n"
      )
      tryCatch(
        expr = {
          run_pipeline(
            sel_script = "R/Pipelines/pipeline_modern_spatial_resolution.R",
            store_suffix = .x
          )
          NA_character_
        },
        error = function(err) {
          vec_error_message <-
            base::conditionMessage(err)

          base::message(
            "\n\nModern local pipeline failed for spatial unit: ", .x,
            "\n", vec_error_message,
            "\nContinuing with the next spatial unit.\n\n"
          )

          vec_error_message
        }
      )
    }
  )
tictoc::toc()

data_pipeline_errors <-
  tibble::tibble(
    scale_id = base::names(vec_pipeline_errors),
    error_message = base::unname(vec_pipeline_errors)
  ) |>
  dplyr::filter(
    !base::is.na(.data$error_message)
  )

if (
  base::nrow(data_pipeline_errors) > 0L
) {
  base::message(
    "\nModern local spatial pipelines completed with failures for: ",
    stringr::str_c(data_pipeline_errors[["scale_id"]], collapse = ", ")
  )
}

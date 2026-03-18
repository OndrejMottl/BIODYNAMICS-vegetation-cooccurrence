#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     {target} pipe: Network metrics summary by age
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of the target pipe, which aggregates per-slice
#   bipartite network metrics across all time slices into a
#   single long-format tibble.
# Must be sourced AFTER pipe_models_by_age is built
#   (tarchetypes::tar_combine() indexes it at source time).


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

# Load {here}
library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

# load all project settings
suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

#----------------------------------------------------------#
# 1. pipe definition -----
#----------------------------------------------------------#

pipe_segment_network_summary_age <-
  list(
    tarchetypes::tar_combine(
      description = paste0(
        "Combine per-slice network metrics into a list"
      ),
      name = "list_network_metrics_by_age",
      pipe_models_by_age[["data_network_metrics"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = paste0(
        "Long-format tibble of bipartite network metrics",
        " by age slice"
      ),
      name = "data_network_metrics_by_age",
      command = dplyr::bind_rows(
        list_network_metrics_by_age,
        .id = "age"
      )
    )
  )

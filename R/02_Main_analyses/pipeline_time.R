#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                   Main {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the target pipe:
#   - test each model against null model
#   - slice data by age
#   - run models on each slice
# Note that this script should be executed
#   by other scripts (eg, `01_Run_pipelines.R`).

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

# load all functions
targets::tar_source(
  files = here::here("R/Functions/")
)

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs",
  error = "null"
)

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

# This section is basically a very complicated target factory.

# This is done to reduce code duplication (several parts of pipe chain repeats).
#  And mainly to use the `tar_combine` function to combine the results.

# I am aware that this is not the most elegant solution, but it works.

#--------------------------------------------------#
## 1.1 load pipes parts -----
#--------------------------------------------------#

path_pipe_parts <-
  here::here("R/02_Main_analyses/_pipes/")

# sourcing all pipe parts needs to be done in specific order
c(
  "pipe_target_config.R",
  "pipe_target_vegvault_data.R",
  "pipe_target_community_data.R",
  "pipe_target_abiotic_data.R",
  "pipe_target_model_prep_by_age.R",
  "pipe_target_model_fit.R",
  "pipe_target_species_associations.R",
  "pipe_target_slice_by_age.R",
  "pipe_target_result_summary_age.R"
) %>%
  rlang::set_names() %>%
  purrr::walk(
    .f = ~ source(
      file = file.path(path_pipe_parts, .x)
    )
  )


#--------------------------------------------------#
## 1.1 combine all targets into a single pipe -----
#--------------------------------------------------#

list(
  pipe_target_config,
  pipe_target_vegvault_data,
  pipe_target_community_data,
  pipe_target_abiotic_data,
  pipe_models_by_age,
  pipe_target_result_summary_age,
  targets::tar_target(
    description = "Plot of significant associations by age",
    name = "plot_species_associations",
    command = ggplot2::ggplot() +
      ggplot2::geom_line(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::geom_point(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::coord_cartesian(
        ylim = c(0, 1),
      ) +
      ggplot2::scale_x_continuous(
        trans = "reverse"
      ) +
      ggplot2::labs(
        title = "Proportion of significant associations by age",
        subtitle = paste("project:", Sys.getenv("R_CONFIG_ACTIVE")),
        x = "Age (cal yr BP)",
        y = "Proportion of significant associations"
      )
  )
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                   basic {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the basic target pipe.
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
  format = "qs"
  # now we need NOT to set the error option to "null" because we want to
  #   see the errors in the pipeline
  # error = "null"
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
  "pipe_segment_config.R",
  "pipe_segment_vegvault_data.R",
  "pipe_segment_community_data.R",
  "pipe_segment_abiotic_data.R",
  "pipe_segment_model_prep.R",
  "pipe_segment_model_simple.R",
  "pipe_segment_model_anova.R"
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
  pipe_segment_config,
  pipe_segment_vegvault_data,
  pipe_segment_community_data,
  pipe_segment_abiotic_data,
  pipe_segment_model_simple,
  pipe_segment_model_anova
  # pipe_segment_species_associations,
  # pipe_segment_result_summary_type,
  # targets::tar_target(
  #   description = "Plot of significant associations",
  #   name = "plot_species_assocWiations",
  #   command = ggplot2::ggplot() +
  #     ggplot2::geom_point(
  #       data = data_species_associations_total,
  #       mapping = ggplot2::aes(
  #         y = n_sign_assoc,
  #         x = type
  #       )
  #     ) +
  #     ggplot2::coord_cartesian(
  #       ylim = c(0, 1),
  #     ) +
  #     ggplot2::labs(
  #       title = "Proportion of significant associations",
  #       subtitle = paste("project:", Sys.getenv("R_CONFIG_ACTIVE")),
  #       x = "Type of random factor",
  #       y = "Proportion of significant associations"
  #     )
  # )
)

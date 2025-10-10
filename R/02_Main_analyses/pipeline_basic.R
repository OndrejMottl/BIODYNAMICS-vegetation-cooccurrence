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
#   by other scripts (eg, `01_Run_pipeline_basic.R`).

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
  "pipe_target_model_prep.R",
  "pipe_target_model_fit.R",
  "pipe_target_model_simple.R",
  "pipe_target_species_associations.R"
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
  pipe_target_model_simple,
  pipe_target_species_associations
)

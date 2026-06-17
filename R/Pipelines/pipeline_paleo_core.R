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
base::suppressWarnings(
  library(
    "here",
    quietly = TRUE,
    warn.conflicts = FALSE,
    verbose = FALSE
  )
)

# load all project settings
suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

# load all functions (exclude _outdated and Legacy)
vec_fun_files <-
  list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) %>%
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated|Legacy")
  )

targets::tar_source(
  files = vec_fun_files
)

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs",
  controller = get_preprocessing_controller()
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
  here::here("R/Pipelines/_pipes/")

# sourcing all pipe parts needs to be done in specific order
c(
  "pipe_segment_config_common.R",
  "pipe_segment_config_model.R",
  "pipe_segment_vegvault_extract.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_community_prepare_paleo.R",
  "_helpers/make_community_filter_targets.R",
  "pipe_segment_community_filter.R",
  "pipe_segment_abiotic_extract.R",
  "pipe_segment_sample_alignment.R",
  "pipe_segment_model_input.R",
  "pipe_segment_model_prepare_response.R",
  "pipe_segment_model_spatial_shared.R",
  "pipe_segment_model_spatial_samples.R",
  "pipe_segment_model_assemble.R",
  "pipe_segment_model_fit.R",
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
  pipe_segment_config_common,
  pipe_segment_config_model,
  pipe_segment_vegvault_extract,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_community_prepare_paleo,
  pipe_segment_community_filter,
  pipe_segment_abiotic_extract,
  pipe_segment_sample_alignment,
  pipe_segment_model_input,
  pipe_segment_model_prepare_response,
  pipe_segment_model_spatial_shared,
  pipe_segment_model_spatial_samples,
  pipe_segment_model_assemble,
  pipe_segment_model_fit,
  pipe_segment_model_anova
)

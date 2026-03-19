#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Time-slice {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the target pipe:
#   - Fits one sjSDM model per time slice (age bin)
#   - Runs anova variance decomposition per slice
#   - Aggregates anova components (F_A, F_B, F_S, ...)
#     across all slices into a single summary table
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

# load all functions (exclude _outdated)
vec_fun_files <-
  list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) %>%
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated")
  )

targets::tar_source(
  files = vec_fun_files
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

# This section is a target factory: it creates one branch of
#   model-fitting targets per time slice using tarchetypes::tar_map,
#   then aggregates results across all slices.

#--------------------------------------------------#
## 1.1 Load pipe segments -----
#--------------------------------------------------#

path_pipe_parts <-
  here::here("R/02_Main_analyses/_pipes/")

# Segments must be sourced in dependency order.
# pipe_segment_age_filter redefines data_sample_ids per slice,
#   so it must come before pipe_segment_fit_data_prep and model_prep.
# pipe_segment_result_summary_age references pipe_models_by_age, so it
#   is sourced AFTER that object is built (see section 1.3 below).
c(
  "pipe_segment_config.R",
  "pipe_segment_vegvault_data.R",
  "pipe_segment_community_data.R",
  "pipe_segment_abiotic_data.R",
  "pipe_segment_age_filter.R",
  "pipe_segment_fit_data_prep.R",
  "pipe_segment_model_prep.R",
  "pipe_segment_model_simple.R",
  "pipe_segment_model_anova.R",
  "pipe_segment_community_network.R"
) %>%
  rlang::set_names() %>%
  purrr::walk(
    .f = ~ source(
      file = file.path(path_pipe_parts, .x)
    )
  )

#--------------------------------------------------#
## 1.2 Build per-slice target map -----
#--------------------------------------------------#

# Enumerate all age values to run the model on.
# Derived from the active configuration so it adjusts automatically
#   when switching between projects (project_cz, project_temporal_europe, …).
data_to_map_age <-
  tibble::tibble(
    age = seq(
      from = min(get_active_config(c("vegvault_data", "age_lim"))),
      to = max(get_active_config(c("vegvault_data", "age_lim"))),
      by = get_active_config(c("data_processing", "time_step"))
    ),
    age_name = paste0("timeslice_", age)
  )

# Assemble the per-slice segment list.
# Each group of targets is namespaced by tarchetypes::tar_map,
#   e.g. data_sample_ids_timeslice_0, mod_jsdm_timeslice_0, etc.
pipe_segment_per_slice <-
  list(
    pipe_segment_age_filter,
    pipe_segment_fit_data_prep,
    pipe_segment_model_prep,
    pipe_segment_model_simple,
    pipe_segment_model_anova,
    pipe_segment_community_network
  )

pipe_models_by_age <-
  tarchetypes::tar_map(
    values = data_to_map_age,
    names = "age_name",
    pipe_segment_per_slice
  )

# Source result_summary_age only after pipe_models_by_age exists,
#   because tarchetypes::tar_combine() inside that segment
#   indexes pipe_models_by_age[["model_anova"]] at source time.
# pipe_segment_network_summary_age similarly indexes
#   pipe_models_by_age[["data_network_metrics"]] at source time.
source(
  file = file.path(path_pipe_parts, "pipe_segment_result_summary_age.R")
)

source(
  file = file.path(path_pipe_parts, "pipe_segment_network_summary_age.R")
)

#--------------------------------------------------#
## 1.3 Combine all targets into the pipeline -----
#--------------------------------------------------#

list(
  pipe_segment_config,
  pipe_segment_vegvault_data,
  pipe_segment_community_data,
  pipe_segment_abiotic_data,
  pipe_models_by_age,
  pipe_segment_result_summary_age,
  pipe_segment_network_summary_age
)

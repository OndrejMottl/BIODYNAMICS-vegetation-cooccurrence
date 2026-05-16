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
  here::here("R/Pipelines/_pipes/")

# Segments must be sourced in dependency order.
# pipe_segment_sample_filter_age redefines data_sample_ids per slice,
#   so it must come before pipe_segment_model_input and model_prep.
# pipe_segment_model_summary_by_age references targets_models_by_age, so it
#   is sourced AFTER that object is built (see section 1.3 below).
c(
  "pipe_segment_config_common.R",
  "pipe_segment_config_model.R",
  "pipe_segment_vegvault_extract.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_community_prepare_paleo.R",
  "pipe_segment_abiotic_extract.R",
  "pipe_segment_sample_filter_age.R",
  "pipe_segment_model_input.R",
  "pipe_segment_model_prepare.R",
  "pipe_segment_model_fit.R",
  "pipe_segment_model_anova.R",
  "pipe_segment_network_metrics.R"
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
#   when switching between projects (project_paleo_core_cz, project_paleo_temporal_europe, …).
vec_age_lim <-
  get_active_config(c("vegvault_data", "age_lim"))

vec_time_step <-
  get_active_config(c("data_processing", "time_step"))

data_to_map_age <-
  tibble::tibble(
    age = seq(
      from = min(vec_age_lim),
      to = max(vec_age_lim),
      by = vec_time_step
    ),
    age_name = paste0("timeslice_", age)
  )

# Assemble the per-slice segment list.
# Each group of targets is namespaced by tarchetypes::tar_map,
#   e.g. data_sample_ids_timeslice_0, model_jsdm_timeslice_0, etc.
targets_per_age_slice <-
  list(
    pipe_segment_sample_filter_age,
    pipe_segment_model_input,
    pipe_segment_model_prepare,
    pipe_segment_model_fit,
    pipe_segment_model_anova,
    pipe_segment_network_metrics
  )

targets_models_by_age <-
  tarchetypes::tar_map(
    values = data_to_map_age,
    names = "age_name",
    targets_per_age_slice
  )

# Source result_summary_age only after targets_models_by_age exists,
#   because tarchetypes::tar_combine() inside that segment
#   indexes targets_models_by_age[["model_anova"]] at source time.
# pipe_segment_network_summary_by_age similarly indexes
#   targets_models_by_age[["data_network_metrics"]] at source time.
source(
  file = file.path(path_pipe_parts, "pipe_segment_model_summary_by_age.R")
)

source(
  file = file.path(path_pipe_parts, "pipe_segment_network_summary_by_age.R")
)

#--------------------------------------------------#
## 1.3 Combine all targets into the pipeline -----
#--------------------------------------------------#

list(
  pipe_segment_config_common,
  pipe_segment_config_model,
  pipe_segment_vegvault_extract,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_community_prepare_paleo,
  pipe_segment_abiotic_extract,
  targets_models_by_age,
  pipe_segment_model_summary_by_age,
  pipe_segment_network_summary_by_age
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   Modern spatial resolution {targets} pipeline
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the full modelling workflow for modern vegetation data at
#   genus, family, and modern-FT resolutions for one
#   spatial unit.
#
# This is the modern-data counterpart of
#   pipeline_paleo_spatial_resolution.R. It shares the model fitting stack
#   unchanged, but uses modern community preprocessing and tracks one
#   FT files:
#     file_ft_classification_modern
#
# Per-resolution targets are suffixed by resolution_id:
#   _genus, _family, _ft_modern.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

vec_fun_files <-
  base::list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) |>
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated")
  )

targets::tar_source(
  files = vec_fun_files
)

targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs",
  error = "continue"
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

#--------------------------------------------------#
## 1.1 Load pipe segments -----
#--------------------------------------------------#

path_pipe_parts <-
  here::here("R/Pipelines/_pipes/")

c(
  "pipe_segment_config_common.R",
  "pipe_segment_vegvault_extract.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_abiotic_extract.R",
  "pipe_segment_community_prepare_modern.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ base::source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )

c(
  "_helpers/make_community_filter_targets.R",
  "pipe_segment_config_model_by_resolution.R",
  "pipe_segment_community_by_resolution_modern.R",
  "pipe_segment_model_spatial_shared.R",
  "pipe_segment_sample_alignment.R",
  "pipe_segment_model_input.R",
  "pipe_segment_model_prepare_response.R",
  "pipe_segment_model_spatial_samples.R",
  "pipe_segment_model_assemble.R",
  "pipe_segment_model_fit.R",
  "pipe_segment_model_anova.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ base::source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )


#--------------------------------------------------#
## 1.2 Resolution branches -----
#--------------------------------------------------#

vec_modern_spatial_resolutions <-
  c("genus", "family", "ft_modern")

list_config_modern_spatial_resolutions <-
  base::list(
    targets::tar_target(
      description = paste0(
        "Modern spatial resolution branches included in this pipeline"
      ),
      name = config_modern_spatial_resolutions,
      command = vec_modern_spatial_resolutions
    )
  )


#--------------------------------------------------#
## 1.3 Shared FT file targets -----
#--------------------------------------------------#

flag_is_modern_continental_run <-
  stringr::str_detect(
    base::Sys.getenv("R_CONFIG_ACTIVE"),
    "modern.*continental"
  )

if (
  flag_is_modern_continental_run
) {
  base::source(
    file = base::file.path(
      path_pipe_parts,
      "pipe_segment_ft_classification_modern_continental.R"
    )
  )

  list_file_ft_classification_modern <-
    pipe_segment_ft_classification_modern_continental
} else {
  list_file_ft_classification_modern <-
    base::list(
      targets::tar_target(
        description = stringr::str_glue(
          "Track the most recent modern FT classification file ",
          "for the continent that owns this spatial unit"
        ),
        name = file_ft_classification_modern,
        command = get_functional_type_classification_path_from_store(
          data_source_prefix = "modern"
        ),
        format = "file"
      )
    )
}

#--------------------------------------------------#
## 1.4 Build per-resolution target map -----
#--------------------------------------------------#

targets_per_resolution <-
  base::list(
    pipe_segment_config_model_by_resolution,
    pipe_segment_community_by_resolution_modern,
    pipe_segment_sample_alignment,
    pipe_segment_model_input,
    pipe_segment_model_prepare_response,
    pipe_segment_model_spatial_samples,
    pipe_segment_model_assemble,
    pipe_segment_model_fit,
    pipe_segment_model_anova
  )

targets_models_by_resolution <-
  tarchetypes::tar_map(
    values = list(
      resolution_id = vec_modern_spatial_resolutions
    ),
    targets_per_resolution
  )


#--------------------------------------------------#
## 1.5 Combine all targets into the pipeline -----
#--------------------------------------------------#

base::list(
  pipe_segment_config_common,
  pipe_segment_vegvault_extract,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_abiotic_extract,
  pipe_segment_community_prepare_modern,
  list_config_modern_spatial_resolutions,
  list_file_ft_classification_modern,
  pipe_segment_model_spatial_shared,
  targets_models_by_resolution
)

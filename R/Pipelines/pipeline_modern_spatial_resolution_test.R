#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Modern spatial resolution-testing {targets} pipeline
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Validation / testbed pipeline for modern Czechia-scale runs.
# It mirrors pipeline_modern_spatial_resolution.R, but builds a
#   de novo modern FT classification for the test spatial unit instead
#   of requiring a pre-existing whole-Europe modern FT file.


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
    ~ stringr::str_detect(.x, "_outdated|_legacy")
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
  "pipe_segment_community_prepare_modern.R",
  "pipe_segment_ft_classification_continental.R"
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
## 1.3 Local modern FT validation targets -----
#--------------------------------------------------#

pipe_segment_ft_classification_modern_resolution_test <-
  make_pipe_segment_ft_classification_continental(
    output_target_name = "file_ft_classification_modern",
    ft_classification_id_expr = quote(
      {
        sel_scale_id <- get_scale_id_from_store()

        if (
          base::is.null(sel_scale_id)
        ) {
          sel_scale_id <-
            "cz_test"
        }

        stringr::str_glue("{sel_scale_id}_test")
      }
    ),
    data_source_prefix = "modern"
  )


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
  pipe_segment_ft_classification_modern_resolution_test,
  pipe_segment_model_spatial_shared,
  targets_models_by_resolution
)

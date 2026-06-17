#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Spatial resolution {targets} pipeline — genus, family & FT
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the full modelling workflow at three taxonomic
#   resolutions — "genus", "family", and "functional_type" — for a
#   single spatial unit (continental, regional, or local).
#
# This pipeline is the spatial counterpart of
#   pipeline_paleo_resolution_test.R, which validated the resolution
#   routing on project_cz_paleo.  Each spatial runner
#   script (01_Run_spatial_continental.R etc.) calls this
#   pipeline once per unit, isolating its store at:
#
#   Data/targets/{spatial_tier}/{scale_id}/pipeline_paleo_spatial_resolution/
#
# Pipeline structure:
#   SHARED (computed once per unit):
#     pipe_segment_config_common  — spatial window + data config
#     pipe_segment_vegvault_extract — raw VegVault fetch
#     community extract/classification/preprocess segments
#        — genus-level community assembly
#     pipe_segment_abiotic_extract — abiotic predictor assembly
#     file_ft_classification_paleo — FT file tracker (continent lookup)
#
#   PER-RESOLUTION (via tar_map over "genus", "family", "functional_type"):
#     pipe_segment_config_model_by_resolution — per-resolution fitting config
#     pipe_segment_community_by_resolution_paleo — taxonomic re-aggregation
#     pipe_segment_sample_alignment — site alignment
#     pipe_segment_model_input — model matrix preparation
#     model prepare/spatial/assemble segments — model input setup
#     pipe_segment_model_fit — jSDM fitting
#     pipe_segment_model_anova — ANOVA variation partitioning
#
# To run this pipeline:
#
#   Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_continental")
#   targets::tar_make(
#     script = here::here(
#       "R/Pipelines/pipeline_paleo_spatial_resolution.R"
#     ),
#     store = here::here(
#       "Data/targets/paleo_spatial_continental/{scale_id}/",
#       "pipeline_paleo_spatial_resolution"
#     )
#   )
#
#   In practice, the spatial runner scripts call this via
#   run_pipeline() with store_suffix = scale_id and the pipeline
#   name resolved automatically.


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

# load all functions (exclude _outdated and _legacy)
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

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs",
  controller = get_preprocessing_controller(),
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

# Shared segments: sourced once; their targets are computed once
#   and shared across both resolution branches.
c(
  "pipe_segment_config_common.R",
  "pipe_segment_vegvault_extract.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_community_prepare_paleo.R",
  "pipe_segment_abiotic_extract.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ base::source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )

# Resolution-specific segments and their downstream stages.
#   pipe_segment_config_model_by_resolution.R defines config_model_fitting
#   using resolution_id (injected by tar_map()), producing
#   config_model_fitting_family / _functional_type / _genus.
#   Note: pipe_segment_config_model.R is intentionally
#   NOT sourced here — it would create an isolated shared
#   config_model_fitting with no downstream consumers in this
#   pipeline (all model targets consume the suffixed versions).
c(
  "_helpers/make_community_filter_targets.R",
  "pipe_segment_config_model_by_resolution.R",
  "pipe_segment_community_by_resolution_paleo.R",
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
## 1.2 Shared FT path target -----
#--------------------------------------------------#

# For continental runs, FT clustering is performed here-and-now
#   using the community taxa of this spatial unit, ensuring that
#   genus- and family-level pollen taxa are covered correctly.
#   The produced .qs file is saved to Data/Processed/Traits/ so
#   regional and local pipelines for the same continent can look
#   it up via get_functional_type_classification_path_from_store().
#
# For regional and local runs, the pre-computed .qs produced by
#   the continental pipeline is looked up by continent_id and
#   tracked as a file target.  No re-clustering is done, keeping
#   FT labels consistent across all spatial scales.

flag_is_continental_run <-
  stringr::str_detect(
    base::Sys.getenv("R_CONFIG_ACTIVE"),
    "continental"
  )

if (
  flag_is_continental_run
) {
  base::source(
    file = base::file.path(
      path_pipe_parts, "pipe_segment_ft_classification_continental.R"
    )
  )

  list_file_ft_classification_paleo <-
    make_pipe_segment_ft_classification_continental()
} else {
  # Tracks the most recent FT classification .qs file for the
  #   continent that owns this spatial unit.
  #   Declared outside tar_map() so it is computed once and
  #   its hash is shared across both resolution branches.
  list_file_ft_classification_paleo <-
    base::list(
      targets::tar_target(
        description = stringr::str_glue(
          "Track the most recent FT classification file ",
          "for the continent that owns this spatial unit"
        ),
        name = file_ft_classification_paleo,
        command = get_functional_type_classification_path_from_store(),
        format = "file"
      )
    )
}


#--------------------------------------------------#
## 1.3 Build per-resolution target map -----
#--------------------------------------------------#

# Segment list replicated for each resolution.
# tar_map() appends the resolution suffix to every target name,
#   e.g. config_model_fitting_family, model_anova_family.
targets_per_resolution <-
  base::list(
    pipe_segment_config_model_by_resolution,
    pipe_segment_community_by_resolution_paleo,
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
      resolution_id = c("genus", "family", "functional_type")
    ),
    targets_per_resolution
  )


#--------------------------------------------------#
## 1.4 Combine all targets into the pipeline -----
#--------------------------------------------------#

base::list(
  pipe_segment_config_common,
  pipe_segment_vegvault_extract,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_community_prepare_paleo,
  pipe_segment_abiotic_extract,
  list_file_ft_classification_paleo,
  pipe_segment_model_spatial_shared,
  targets_models_by_resolution
)

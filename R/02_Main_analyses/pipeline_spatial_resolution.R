#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Spatial resolution {targets} pipeline — family & FT
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the full modelling workflow at two non-genus taxonomic
#   resolutions — "family" and "functional_type" — for a single
#   spatial unit (continental, regional, or local).
#
# This pipeline is the spatial counterpart of
#   pipeline_test_resolution.R, which validated the resolution
#   routing on project_cz (Phase E0/F0).  Each spatial runner
#   script (01_Run_spatial_continental.R etc.) calls this
#   pipeline once per unit, isolating its store at:
#
#   Data/targets/{spatial_tier}/{scale_id}/pipeline_spatial_resolution/
#
# Pipeline structure:
#   SHARED (computed once per unit):
#     pipe_segment_config           — spatial window + data config
#     pipe_segment_vegvault_data    — raw VegVault fetch
#     pipe_segment_community_data   — genus-level community assembly
#     pipe_segment_abiotic_data     — abiotic predictor assembly
#     path_ft_classification        — FT file tracker (continent lookup)
#
#   PER-RESOLUTION (via tar_map over "family", "functional_type"):
#     pipe_segment_config_resolution      — per-resolution fitting config
#     pipe_segment_community_resolution   — taxonomic re-aggregation
#     pipe_segment_alignment              — site alignment
#     pipe_segment_fit_data_prep          — model matrix preparation
#     pipe_segment_model_prep             — spatial/formula setup
#     pipe_segment_model_simple           — jSDM fitting
#     pipe_segment_model_anova            — ANOVA variation partitioning
#
# Note: genus-resolution targets are NOT produced here to avoid
#   recomputing already-available pipeline_basic.R results.
#   Run pipeline_basic.R for genus alongside this pipeline.
#
# To run this pipeline:
#
#   Sys.setenv(R_CONFIG_ACTIVE = "project_spatial_continental")
#   targets::tar_make(
#     script = here::here(
#       "R/02_Main_analyses/pipeline_spatial_resolution.R"
#     ),
#     store = here::here(
#       "Data/targets/spatial_continental/{scale_id}/",
#       "pipeline_spatial_resolution"
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

# load all functions (exclude _outdated)
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

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs"
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

#--------------------------------------------------#
## 1.1 Load pipe segments -----
#--------------------------------------------------#

path_pipe_parts <-
  here::here("R/02_Main_analyses/_pipes/")

# Shared segments: sourced once; their targets are computed once
#   and shared across both resolution branches.
c(
  "pipe_segment_config.R",
  "pipe_segment_vegvault_data.R",
  "pipe_segment_community_data.R",
  "pipe_segment_abiotic_data.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ base::source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )

# Resolution-specific segments and their downstream stages.
#   pipe_segment_config_resolution.R defines config.model_fitting
#   using tax_res (injected by tar_map()), which shadows the
#   shared config.model_fitting for each resolution branch.
c(
  "pipe_segment_config_resolution.R",
  "pipe_segment_community_resolution.R",
  "pipe_segment_alignment.R",
  "pipe_segment_fit_data_prep.R",
  "pipe_segment_model_prep.R",
  "pipe_segment_model_simple.R",
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

# Tracks the most recent FT classification .qs file for the
#   continent that owns this spatial unit.
#   Declared outside tar_map() so it is computed once and
#   its hash is shared across both resolution branches.
list_path_ft_classification <-
  base::list(
    targets::tar_target(
      description = stringr::str_c(
        "Track the most recent FT classification file ",
        "for the continent that owns this spatial unit"
      ),
      name = path_ft_classification,
      command = get_functional_type_classification_path_from_store(),
      format = "file"
    )
  )


#--------------------------------------------------#
## 1.3 Build per-resolution target map -----
#--------------------------------------------------#

# Segment list replicated for each resolution.
# tar_map() appends the resolution suffix to every target name,
#   e.g. config.model_fitting_family, model_anova_family.
pipe_segment_per_resolution <-
  base::list(
    pipe_segment_config_resolution,
    pipe_segment_community_resolution,
    pipe_segment_alignment,
    pipe_segment_fit_data_prep,
    pipe_segment_model_prep,
    pipe_segment_model_simple,
    pipe_segment_model_anova
  )

pipe_models_by_resolution <-
  tarchetypes::tar_map(
    values = list(
      tax_res = c("family", "functional_type")
    ),
    pipe_segment_per_resolution
  )


#--------------------------------------------------#
## 1.4 Combine all targets into the pipeline -----
#--------------------------------------------------#

base::list(
  pipe_segment_config,
  pipe_segment_vegvault_data,
  pipe_segment_community_data,
  pipe_segment_abiotic_data,
  list_path_ft_classification,
  pipe_models_by_resolution
)

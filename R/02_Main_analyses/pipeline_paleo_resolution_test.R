#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Resolution-testing {targets} pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Validation / testbed pipeline.
# Runs the full modelling workflow for three taxonomic
#   resolutions on a single project (project_paleo_core_cz) to verify
#   that pipe_segment_community_by_resolution_paleo routes correctly
#   before the technique is rolled out to the full spatial
#   scale.
#
# Resolutions tested:
#   "genus" — regression check against pipeline_paleo_core.R
#   "family" — new; uses classify_taxonomic_resolution()
#   "functional_type" — uses the same FT clustering segment as the
#       main spatial resolution pipeline, with local test-pipeline
#       checks for the non-spatial store and whole-Europe FT coverage
#
# The three resolutions are created by tarchetypes::tar_map()
#   over pipe_segment_community_by_resolution_paleo and all downstream
#   pipe segments (alignment -> model_anova), producing targets:
#     data_community_analysis_subset_genus, model_anova_genus
#     data_community_analysis_subset_family, model_anova_family
#     data_community_analysis_subset_functional_type,
#       model_anova_functional_type
#
# The upstream segments (config -> vegvault -> community extract,
#   taxonomy classification, paleo preprocess -> abiotic_data) are
#   shared across both branches and produce their targets exactly once.
#   The FT classification target is also shared and computed once.
#
# This pipeline is NOT a replacement for pipeline_paleo_core.R.
#   It is a standalone testbed used as:
#     (1) a validation gate
#     (2) a permanent end-to-end sanity check run alongside
#         pipeline_paleo_core.R in the agent instruction workflows
#
# To run this pipeline:
#
#   Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_core_cz")
#   targets::tar_make(
#     script = here::here(
#       "R/02_Main_analyses/pipeline_paleo_resolution_test.R"
#     ),
#     store  = here::here(
#       "Data/targets/paleo_core_cz/pipeline_paleo_resolution_test"
#     )
#   )


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
  here::here("R/02_Main_analyses/_pipes/")

# Shared segments: sourced once; their targets are computed once
#   and are shared across both resolution branches.
c(
  "pipe_segment_config_common.R",
  "pipe_segment_config_model.R",
  "pipe_segment_vegvault_extract.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_community_prepare_paleo.R",
  "pipe_segment_abiotic_extract.R",
  "pipe_segment_ft_classification_continental.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )

# Resolution-specific and downstream segments.
#   These are used inside tarchetypes::tar_map() and are NOT
#   added to the top-level list directly.  tar_map() appends a
#   resolution suffix to every target name they define, e.g.
#   data_community_analysis_subset_genus, model_anova_family.
c(
  "_helpers/make_community_filter_targets.R",
  "pipe_segment_community_by_resolution_paleo.R",
  "pipe_segment_sample_alignment.R",
  "pipe_segment_model_input.R",
  "pipe_segment_model_prepare.R",
  "pipe_segment_model_fit.R",
  "pipe_segment_model_anova.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )

#--------------------------------------------------#
## 1.2 Local FT validation targets -----
#--------------------------------------------------#

# The test pipeline is not a spatial store, so it cannot use
#   get_scale_id_from_store() as the FT classification id. It still
#   uses the same shared FT clustering factory as the spatial pipeline,
#   but saves the de novo classification under the active project id.
#   The optional reference check records whether the existing Europe-wide
#   FT file would have been viable for this CZ testbed.
pipe_segment_ft_classification_resolution_test <-
  make_pipe_segment_ft_classification_continental(
    ft_classification_id_expr = quote(
      base::Sys.getenv("R_CONFIG_ACTIVE") |>
        stringr::str_remove("^project_")
    ),
    include_reference_check = TRUE
  )

#--------------------------------------------------#
## 1.3 Build per-resolution target map -----
#--------------------------------------------------#

# Segment list that is replicated for each resolution.
# All target names inside these segments are suffixed by
#   tar_map() with the resolution value, e.g. _genus or _family.
#   Cross-references within the map block are updated automatically.
targets_per_resolution <-
  list(
    pipe_segment_community_by_resolution_paleo,
    pipe_segment_sample_alignment,
    pipe_segment_model_input,
    pipe_segment_model_prepare,
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

list(
  pipe_segment_config_common,
  pipe_segment_config_model,
  pipe_segment_vegvault_extract,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_community_prepare_paleo,
  pipe_segment_abiotic_extract,
  pipe_segment_ft_classification_resolution_test,
  targets_models_by_resolution
)

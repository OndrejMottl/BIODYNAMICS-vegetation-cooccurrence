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
# Validation / testbed pipeline for Phase E0.
# Runs the full modelling workflow for all three taxonomic
#   resolutions on a single project (project_cz) to verify
#   that pipe_segment_community_resolution routes correctly
#   before the technique is rolled out to the full spatial
#   scale in Phase F3.
#
# Resolutions tested:
#   "genus"          — regression check against pipeline_basic.R
#   "family"         — new; uses classify_taxonomic_resolution()
#   "functional_type"— new; uses classify_to_functional_type()
#
# The three resolutions are created by tarchetypes::tar_map()
#   over pipe_segment_community_resolution and all downstream
#   pipe segments (alignment -> model_anova), producing targets:
#     data_community_subset_genus, model_anova_genus
#     data_community_subset_family, model_anova_family
#     data_community_subset_functional_type, model_anova_functional_type
#
# The upstream segments (config -> vegvault -> community extract,
#   taxonomy classification, paleo preprocess -> abiotic_data) are
#   shared across all three branches and produce their targets exactly once.
#
# This pipeline is NOT a replacement for pipeline_basic.R.
#   It is a standalone testbed used as:
#     (1) a Phase F0 validation gate
#     (2) a permanent end-to-end sanity check run alongside
#         pipeline_basic.R in the agent instruction workflows
#
# To run this pipeline:
#
#   Sys.setenv(R_CONFIG_ACTIVE = "project_cz")
#   targets::tar_make(
#     script = here::here(
#       "R/02_Main_analyses/pipeline_test_resolution.R"
#     ),
#     store  = here::here(
#       "Data/targets/project_cz/pipeline_test_resolution"
#     )
#   )


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
#   and are shared across all three resolution branches.
c(
  "pipe_segment_config.R",
  "pipe_segment_config_model_fitting.R",
  "pipe_segment_vegvault_data.R",
  "pipe_segment_community_extract.R",
  "pipe_segment_taxa_classification.R",
  "pipe_segment_community_preprocess_paleo.R",
  "pipe_segment_abiotic_data.R"
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
#   data_community_subset_genus, model_anova_family.
c(
  "pipe_segment_community_resolution.R",
  "pipe_segment_alignment.R",
  "pipe_segment_fit_data_prep.R",
  "pipe_segment_model_prep.R",
  "pipe_segment_model_simple.R",
  "pipe_segment_model_anova.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )


#--------------------------------------------------#
## 1.2 Shared FT path target -----
#--------------------------------------------------#

# Tracks the most recent FT classification .qs file for the
#   active continent (project_cz -> "europe").
#   Used only by the "functional_type" branch in tar_map(),
#   but declared here (outside the map) so it is computed once
#   and its hash is shared across all branches.
list_path_ft_classification <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Track the most recent FT classification file ",
        "for the active continent"
      ),
      name = path_ft_classification,
      command = {
        continent_id_val <-
          get_active_config("continent_id")

        pattern_str <-
          stringr::str_glue(
            "^data_ft_classification_{continent_id_val}_",
            "[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}\\.qs$"
          )

        vec_files <-
          base::list.files(
            path = here::here("Data/Processed/Traits"),
            pattern = pattern_str,
            full.names = TRUE
          )

        assertthat::assert_that(
          base::length(vec_files) > 0L,
          msg = stringr::str_glue(
            "No FT classification file found for continent ",
            "'{continent_id_val}' in Data/Processed/Traits/. ",
            "Run pipeline_traits.R (Segment 6) first."
          )
        )

        # Sort is lexicographic on YYYY-MM-DD -> latest last
        base::sort(vec_files)[base::length(vec_files)]
      },
      format = "file"
    )
  )


#--------------------------------------------------#
## 1.3 Build per-resolution target map -----
#--------------------------------------------------#

# Segment list that is replicated for each resolution.
# All target names inside these segments are suffixed by
#   tar_map() with the resolution value, e.g. _genus, _family,
#   _functional_type.  Cross-references within the map block
#   are updated automatically.
pipe_segment_per_resolution <-
  list(
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
      tax_res = c("genus", "family", "functional_type")
    ),
    pipe_segment_per_resolution
  )


#--------------------------------------------------#
## 1.4 Combine all targets into the pipeline -----
#--------------------------------------------------#

list(
  pipe_segment_config,
  pipe_segment_config_model_fitting,
  pipe_segment_vegvault_data,
  pipe_segment_community_extract,
  pipe_segment_taxa_classification,
  pipe_segment_community_preprocess_paleo,
  pipe_segment_abiotic_data,
  list_path_ft_classification,
  pipe_models_by_resolution
)

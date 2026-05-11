#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        {targets} pipe: Community resolution routing
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that collapses community data to a target
#   taxonomic resolution.
#
# This segment sits downstream of the community extract, taxonomy
#   classification, and paleo preprocess segments. It receives:
#
#   - data_community_classified  (produced by the community
#       data segment at the config-level resolution, typically
#       "genus" for project_paleo_core_cz)
#   - data_combined_classification_table  (shared)
#   - file_ft_classification_paleo  (tar_file target; tracked path to
#       the best-guess .qs FT classification for this continent)
#   - resolution_id  (injected by tarchetypes::tar_map())
#
# Routing logic:
#   "genus" | "family"  ->  classify_taxonomic_resolution()
#   "functional_type"   ->  classify_to_functional_type()
#
# All five targets produced here are renamed by tar_map() with a
#   resolution suffix, e.g. data_community_analysis_subset_genus.
#
# NOTE: the community extract, taxonomy classification, and paleo
#   preprocess segments must be sourced BEFORE this segment so that
#   data_community_classified and data_combined_classification_table
#   are already declared.


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


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_community_by_resolution_paleo <-
  list(

    # ── 1. Resolve community taxa to the target resolution ──
    # Routes between the standard taxonomic classifier and the
    #   FT classifier depending on the `resolution_id` value injected
    #   by tar_map().  For "genus" this is effectively a no-op
    #   re-classification (genus -> genus), which is intentional:
    #   it keeps the genus branch structurally identical to the
    #   family and FT branches so all targets have consistent
    #   names after tar_map() suffixing.
    targets::tar_target(
      description = stringr::str_c(
        "Resolve community taxa to the target taxonomic ",
        "resolution (resolution_id injected by tar_map())"
      ),
      name = "data_community_by_resolution",
      command = {
        if (
          resolution_id == "functional_type"
        ) {
          classify_to_functional_type(
            data = data_community_classified,
            data_ft_classification = qs2::qs_read(
              file_ft_classification_paleo
            )
          )
        } else {
          classify_taxonomic_resolution(
            data = data_community_classified,
            data_classification_table = data_combined_classification_table,
            taxonomic_resolution = resolution_id,
            verbose = FALSE
          )
        }
      }
    ),

    # This target name (data_community_analysis_subset) is the same as the
    #   one produced by pipe_segment_community_filter.R.  When used
    #   inside tar_map() it becomes data_community_analysis_subset_genus,
    #   data_community_analysis_subset_family, etc., and the downstream
    #   segments (alignment -> model_anova) reference the correct
    #   branch-suffixed version automatically.
    make_community_filter_targets("data_community_by_resolution")
  )

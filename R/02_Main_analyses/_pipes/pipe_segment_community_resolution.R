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
#       "genus" for project_cz)
#   - data_combined_classification_table  (shared)
#   - path_ft_classification  (tar_file target; tracked path to
#       the best-guess .qs FT classification for this continent)
#   - tax_res  (injected by tarchetypes::tar_map())
#
# Routing logic:
#   "genus" | "family"  ->  classify_taxonomic_resolution()
#   "functional_type"   ->  classify_to_functional_type()
#
# All five targets produced here are renamed by tar_map() with a
#   tax_res suffix, e.g. data_community_subset_genus.
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

pipe_segment_community_resolution <-
  list(

    # ── 1. Resolve community taxa to the target resolution ──
    # Routes between the standard taxonomic classifier and the
    #   FT classifier depending on the `tax_res` value injected
    #   by tar_map().  For "genus" this is effectively a no-op
    #   re-classification (genus -> genus), which is intentional:
    #   it keeps the genus branch structurally identical to the
    #   family and FT branches so all targets have consistent
    #   names after tar_map() suffixing.
    targets::tar_target(
      description = stringr::str_c(
        "Resolve community taxa to the target taxonomic ",
        "resolution (tax_res injected by tar_map())"
      ),
      name = "data_community_resolved",
      command = {
        if (
          tax_res == "functional_type"
        ) {
          classify_to_functional_type(
            data = data_community_classified,
            data_ft_classification = qs2::qs_read(
              path_ft_classification
            )
          )
        } else {
          classify_taxonomic_resolution(
            data = data_community_classified,
            data_classification_table = data_combined_classification_table,
            taxonomic_resolution = tax_res
          )
        }
      }
    ),

    # ── 2. Filter rare taxa ─────────────────────────────────
    targets::tar_target(
      description = "Filter rare taxa from resolved community data",
      name = "data_community_rare_filtered",
      command = filter_rare_taxa(
        data = data_community_resolved,
        minimal_proportion = purrr::chuck(
          config.data_processing,
          "minimal_proportion_of_pollen"
        )
      )
    ),

    # ── 3. Filter taxa not present in enough cores ──────────
    targets::tar_target(
      description = stringr::str_c(
        "Filter taxa not present in enough cores ",
        "(resolved community)"
      ),
      name = "data_community_filtered_cores",
      command = filter_community_by_n_cores(
        data = data_community_rare_filtered,
        min_n_cores = purrr::chuck(config.data_processing, "min_n_cores")
      )
    ),

    # ── 4. Filter taxa not present in enough samples ────────
    targets::tar_target(
      description = stringr::str_c(
        "Filter taxa not present in enough samples ",
        "(resolved community)"
      ),
      name = "data_community_filtered_samples",
      command = filter_by_n_samples(
        data = data_community_filtered_cores,
        min_n_samples = purrr::chuck(config.data_processing, "min_n_samples")
      )
    ),

    # ── 5. Select number of taxa ────────────────────────────
    # This target name (data_community_subset) is the same as the
    #   one produced by pipe_segment_community_filtering.R.  When used
    #   inside tar_map() it becomes data_community_subset_genus,
    #   data_community_subset_family, etc., and the downstream
    #   segments (alignment -> model_anova) reference the correct
    #   branch-suffixed version automatically.
    targets::tar_target(
      description = "Select number of taxa to include (resolved)",
      name = "data_community_subset",
      command = select_n_taxa(
        data = data_community_filtered_samples,
        n_taxa = purrr::chuck(config.data_processing, "number_of_taxa")
      )
    )
  )

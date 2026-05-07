#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Community filtering
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that applies post-classification filtering to
#   community data: rare taxa, core count, sample count, and
#   final taxon-number selection.
#
# This segment sits downstream of the community extract, taxonomy
#   classification, and paleo preprocess segments, and expects
#   `data_community_classified` to already be defined.
#
# In pipeline_basic.R it is added to the top-level list directly
#   (shared, no branching).  In pipeline_test_resolution.R this
#   segment is NOT used in the shared section; the equivalent
#   filtering is performed inside pipe_segment_community_resolution.R
#   which starts from `data_community_resolved` instead.


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

pipe_segment_community_filtering <-
  list(

    targets::tar_target(
      description = "Filter rare taxa from community data",
      name = "data_community_rare_filtered",
      command = filter_rare_taxa(
        data = data_community_classified,
        minimal_proportion = purrr::chuck(
          config.data_processing,
          "minimal_proportion_of_pollen"
        )
      )
    ),

    targets::tar_target(
      description = "Filter taxa not present in enough cores",
      name = "data_community_filtered_cores",
      command = filter_community_by_n_cores(
        data = data_community_rare_filtered,
        min_n_cores = purrr::chuck(config.data_processing, "min_n_cores")
      )
    ),

    targets::tar_target(
      description = "Filter taxa not present in enough samples",
      name = "data_community_filtered_samples",
      command = filter_by_n_samples(
        data = data_community_filtered_cores,
        min_n_samples = purrr::chuck(config.data_processing, "min_n_samples")
      )
    ),

    targets::tar_target(
      description = "Select number of taxa to include",
      name = "data_community_subset",
      command = select_n_taxa(
        data = data_community_filtered_samples,
        n_taxa = purrr::chuck(config.data_processing, "number_of_taxa")
      )
    )
  )

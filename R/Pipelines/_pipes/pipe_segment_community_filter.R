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
# In pipeline_paleo_core.R it is added to the top-level list directly
#   (shared, no branching).  In pipeline_paleo_resolution_test.R this
#   segment is NOT used in the shared section; the equivalent
#   filtering is performed inside pipe_segment_community_by_resolution_paleo.R
#   which starts from `data_community_by_resolution` instead.


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

pipe_segment_community_filter <-
  make_community_filter_targets("data_community_classified")

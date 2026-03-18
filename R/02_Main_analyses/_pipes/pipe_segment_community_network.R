#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        {target} pipe: Community bipartite network
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Definition of the target pipe, which computes bipartite
#   community network metrics from the binary community
#   matrix for a single time slice.
# Runs inside tarchetypes::tar_map(), yielding one
#   data_network_metrics target per age slice.


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

#----------------------------------------------------------#
# 1. pipe definition -----
#----------------------------------------------------------#

pipe_segment_community_network <-
  list(
    targets::tar_target(
      description = paste0(
        "Bipartite network metrics (connectance,",
        " nestedness) for this time slice"
      ),
      name = "data_network_metrics",
      command = compute_network_metrics(
        data_to_fit = data_to_fit
      )
    )
  )

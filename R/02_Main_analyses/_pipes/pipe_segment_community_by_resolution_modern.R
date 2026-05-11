#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     {targets} pipe: Modern community resolution routing
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that collapses modern community data to a target
#   taxonomic or functional-type resolution.


#----------------------------------------------------------#
# 0. Helpers -----
#----------------------------------------------------------#

resolve_modern_community_resolution <- function(
    resolution_id,
    data_community_classified,
    data_combined_classification_table,
    file_ft_classification_modern,
    file_ft_classification_paleo) {
  if (
    resolution_id == "ft_modern"
  ) {
    res <-
      classify_to_functional_type(
        data = data_community_classified,
        data_ft_classification = qs2::qs_read(
          file_ft_classification_modern
        )
      )
  } else if (
    resolution_id == "ft_paleo"
  ) {
    res <-
      classify_to_functional_type(
        data = data_community_classified,
        data_ft_classification = qs2::qs_read(
          file_ft_classification_paleo
        )
      )
  } else {
    res <-
      classify_taxonomic_resolution(
        data = data_community_classified,
        data_classification_table = data_combined_classification_table,
        taxonomic_resolution = resolution_id
      )
  }

  return(res)
}


#----------------------------------------------------------#
# 1. Setup -----
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
# 2. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_community_by_resolution_modern <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Resolve modern community taxa to the target taxonomic ",
        "or FT resolution (resolution_id injected by tar_map())"
      ),
      name = "data_community_by_resolution",
      command = resolve_modern_community_resolution(
        resolution_id = resolution_id,
        data_community_classified = data_community_classified,
        data_combined_classification_table = data_combined_classification_table,
        file_ft_classification_modern = file_ft_classification_modern,
        file_ft_classification_paleo = file_ft_classification_paleo
      )
    ),
    make_community_filter_targets(
      input_name = "data_community_by_resolution"
    )
  )

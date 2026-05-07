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
    tax_res,
    data_community_classified,
    data_combined_classification_table,
    path_ft_classification_modern,
    path_ft_classification_paleo) {
  if (
    tax_res == "functional_type_modern"
  ) {
    res <-
      classify_to_functional_type(
        data = data_community_classified,
        data_ft_classification = qs2::qs_read(
          path_ft_classification_modern
        )
      )
  } else if (
    tax_res == "functional_type_paleo"
  ) {
    res <-
      classify_to_functional_type(
        data = data_community_classified,
        data_ft_classification = qs2::qs_read(
          path_ft_classification_paleo
        )
      )
  } else {
    res <-
      classify_taxonomic_resolution(
        data = data_community_classified,
        data_classification_table = data_combined_classification_table,
        taxonomic_resolution = tax_res
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

pipe_segment_community_resolution_modern <-
  list(
    targets::tar_target(
      description = stringr::str_c(
        "Resolve modern community taxa to the target taxonomic ",
        "resolution (tax_res injected by tar_map())"
      ),
      name = "data_community_resolved",
      command = resolve_modern_community_resolution(
        tax_res = tax_res,
        data_community_classified = data_community_classified,
        data_combined_classification_table = data_combined_classification_table,
        path_ft_classification_modern = path_ft_classification_modern,
        path_ft_classification_paleo = path_ft_classification_paleo
      )
    ),
    make_community_filter_targets(
      input_name = "data_community_resolved"
    )
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           {target} pipe: Age filter (slice pipeline)
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Definition of the age-filter pipe segment for per-time-slice
# analyses. This segment redefines the `data_sample_ids` target
# so that only samples from a single selected age are retained.
#
# Usage: include this segment INSTEAD OF `pipe_segment_sample_alignment`
# when building a pipeline that fits one model per time slice.
# All downstream targets (prepare_community_for_fit, etc.)
# consume `data_sample_ids` and therefore require no changes.
#
# The selected age is read from the active configuration via
# `config_data_processing$sel_age`. Add `sel_age` to the relevant
# project configuration block in `config.yml` before running.


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
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_sample_filter_age <-
  list(
    targets::tar_target(
      description = paste0(
        "Compute intersecting sample IDs, then filter to the",
        " single age slice provided by tarchetypes::tar_map"
      ),
      name = "data_sample_ids",
      command = align_sample_ids(
        data_community_long = data_community_analysis_subset,
        data_abiotic_long = data_abiotic_analysis |>
          dplyr::group_by(
            dplyr::across(
              dplyr::all_of(base::c("dataset_name", "age"))
            )
          ) |>
          dplyr::filter(base::all(!base::is.na(.data$abiotic_value))) |>
          dplyr::ungroup(),
        data_coords = data_coords_analysis,
        # `age` is injected as a literal value by tarchetypes::tar_map
        #   at pipeline-construction time, so it resolves correctly
        #   inside each namespaced branch.
        subset_age = age
      )
    ),
    targets::tar_target(
      description = paste0(
        "Fail early if this time slice has fewer than",
        " min_n_samples samples, before any expensive",
        " data preparation or model fitting"
      ),
      name = "data_sample_ids_checked",
      command = check_data_sample_ids_n(
        data_sample_ids = data_sample_ids,
        min_n_samples = config_data_processing$min_n_samples
      )
    )
  )

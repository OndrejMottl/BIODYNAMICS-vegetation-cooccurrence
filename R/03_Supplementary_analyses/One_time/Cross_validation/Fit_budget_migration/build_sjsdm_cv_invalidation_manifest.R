#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Build sjSDM CV invalidation manifest
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Build a dry-run manifest of stale CV/model descendants and apply it only
#   after explicit opt-in. Prepared folds and archived stores are excluded.
# Workflow contract:
#   Requires a completed continental retention audit from runner 04.
#   Default behavior writes a reviewable dry-run manifest and changes no
#   target metadata. SJSMD_APPLY_CV_INVALIDATION=true applies only listed,
#   existing targets inside allowlisted production stores.
#   Review cv_invalidation_manifest.csv before enabling application.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))

path_report <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget"
  )
file_audit <-
  fs::path(path_report, "continental_retention_audit.csv")
file_manifest <-
  fs::path(path_report, "cv_invalidation_manifest.csv")

assertthat::assert_that(
  base::file.exists(file_audit),
  msg = paste(
    "Calibration runner 05 cannot start because",
    "continental_retention_audit.csv is missing. Complete and publish",
    "calibration with runners 02-03, then run runner 04 before runner 05."
  )
)

#----------------------------------------------------------#
# 1. Build and validate the dry-run manifest -----
#----------------------------------------------------------#

data_manifest <-
  build_sjsdm_cv_invalidation_manifest(
    data_continental_audit = readr::read_csv(
      file_audit,
      show_col_types = FALSE
    ),
    regional_store_root = here::here(
      "Data",
      "targets",
      "paleo_spatial_regional"
    ),
    regional_tier_store = here::here(
      "Data",
      "targets",
      "paleo_spatial_regional",
      "pipeline_sjsdm_tier_tuning"
    )
  ) |>
  dplyr::mutate(
    store_path = fs::path_abs(.data[["store_path"]]),
    target_exists = purrr::map2_lgl(
      .data[["store_path"]],
      .data[["target_name"]],
      function(store_path, target_name) {
        base::isTRUE(
          targets::tar_exist_objects(
            names = tidyselect::any_of(target_name),
            store = store_path
          )
        )
      }
    ),
    action = dplyr::if_else(
      .data[["target_exists"]],
      "invalidate",
      "already_absent"
    )
  )

allowed_roots <-
  fs::path_abs(
    here::here(
      "Data",
      "targets",
      base::c(
        "paleo_spatial_continental",
        "modern_spatial_continental",
        "paleo_spatial_regional"
      )
    )
  )
store_is_allowed <-
  purrr::map_lgl(
    data_manifest[["store_path"]],
    function(store_path) {
      base::any(
        stringr::str_starts(
          store_path,
          stringr::str_c(allowed_roots, "/")
        ) |
          stringr::str_starts(
            store_path,
            stringr::str_c(allowed_roots, "\\")
        ) |
          store_path == allowed_roots
      )
    }
  )
assertthat::assert_that(
  base::all(store_is_allowed),
  !base::any(stringr::str_detect(data_manifest[["store_path"]], "_archive")),
  msg = "The invalidation manifest contains a non-production store."
)

readr::write_csv(data_manifest, file_manifest, na = "NA")

#----------------------------------------------------------#
# 2. Optionally apply reviewed invalidations -----
#----------------------------------------------------------#

apply_invalidation <-
  base::tolower(
    base::Sys.getenv("SJSMD_APPLY_CV_INVALIDATION", unset = "false")
  ) == "true"

if (
  !apply_invalidation
) {
  cli::cli_inform(
    base::c(
      "i" = "Wrote the dry-run invalidation manifest to {file_manifest}.",
      "i" = paste(
        "Set SJSMD_APPLY_CV_INVALIDATION=true only after reviewing it."
      )
    )
  )
} else {
  data_manifest |>
    dplyr::filter(.data[["action"]] == "invalidate") |>
    dplyr::group_by(.data[["store_path"]]) |>
    dplyr::group_walk(
      function(data_group, data_key) {
        targets::tar_invalidate(
          names = tidyselect::any_of(data_group[["target_name"]]),
          store = data_key[["store_path"]][[1L]]
        )
      }
    )
  cli::cli_inform("Applied every existing target in {file_manifest}.")
}

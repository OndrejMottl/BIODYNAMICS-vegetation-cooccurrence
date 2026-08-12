#' @title Collect sjSDM Tuning Summaries
#' @description
#' Reads compact resolution-specific tuning summaries from isolated unit
#' targets stores for a shared tier-selection stage.
#' @param store_paths
#' Non-empty character vector of unit targets-store paths.
#' @param resolution_ids
#' Non-empty character vector of mapped model-resolution identifiers.
#' @param target_prefix
#' Non-empty character scalar placed before each resolution identifier.
#' Defaults to the existing public tuning-summary target prefix. Explicit
#' round prefixes allow the tier store to collect one staged round at a time.
#' @param target_names
#' Optional character vector paired with `resolution_ids`. When supplied,
#' reads these exact public target names instead of constructing suffixed names.
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @return
#' Bound tuning-summary tibble with `source_store` and `resolution_id`
#' provenance columns. Every requested store-resolution target must be
#' readable. The function aborts with the failed store and target when
#' evidence is incomplete.
#' @examples
#' \dontrun{
#' load_sjsdm_tuning_summaries(
#'   store_paths = c("store_a", "store_b"),
#'   resolution_ids = c("genus", "family")
#' )
#' }
#' @export
load_sjsdm_tuning_summaries <- function(
    store_paths = NULL,
    resolution_ids = NULL,
    target_prefix = "list_sjsdm_cv_tuning_artifact",
    target_names = NULL,
    read_target_function = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_paths),
    base::length(store_paths) > 0L,
    base::all(base::nzchar(store_paths)),
    msg = "store_paths must contain non-empty store paths."
  )

  assertthat::assert_that(
    base::is.character(resolution_ids),
    base::length(resolution_ids) > 0L,
    base::all(base::nzchar(resolution_ids)),
    msg = "resolution_ids must contain non-empty identifiers."
  )

  assertthat::assert_that(
    base::is.character(target_prefix),
    base::length(target_prefix) == 1L,
    !base::is.na(target_prefix),
    base::nzchar(target_prefix),
    msg = "target_prefix must be one non-empty string."
  )

  assertthat::assert_that(
    base::is.null(target_names) ||
      (
        base::is.character(target_names) &&
          base::length(target_names) == base::length(resolution_ids) &&
          base::all(!base::is.na(target_names)) &&
          base::all(base::nzchar(target_names))
      ),
    msg = "target_names must be NULL or one non-empty name per resolution."
  )

  assertthat::assert_that(
    base::is.function(read_target_function),
    msg = "read_target_function must be a function."
  )

  vec_target_names <-
    if (
      base::is.null(target_names)
    ) {
      stringr::str_glue(
        "{target_prefix}_{resolution_ids}"
      ) |>
        base::as.character()
    } else {
      target_names
    }

  data_resolution_targets <-
    tibble::tibble(
      resolution_id = resolution_ids,
      target_name = vec_target_names
    ) |>
    dplyr::distinct()

  data_store_resolution <-
    tidyr::crossing(
      source_store = base::unique(store_paths),
      data_resolution_targets
    )

  list_summaries <-
    purrr::pmap(
      .l = data_store_resolution,
      .f = function(source_store, resolution_id, target_name) {
        list_or_summary <-
          tryCatch(
            expr = read_target_function(
              name = target_name,
              store = source_store
            ),
            error = function(error_condition) {
              error_condition
            }
          )

        if (
          base::inherits(list_or_summary, "error") &&
            stringr::str_starts(
              target_name,
              "list_sjsdm_cv_tuning_artifact"
            )
        ) {
          v1_target_name <-
            stringr::str_replace(
              target_name,
              "^list_sjsdm_cv_tuning_artifact",
              "data_sjsdm_tuning_summary"
            )
          list_or_summary <-
            tryCatch(
              expr = read_target_function(
                name = v1_target_name,
                store = source_store
              ),
              error = function(error_condition) {
                error_condition
              }
            )
        }

        if (
          base::inherits(list_or_summary, "error")
        ) {
          cli::cli_abort(
            c(
              "Could not read every requested tuning summary.",
              "x" = stringr::str_glue(
                "{target_name} in {source_store}: ",
                "{base::conditionMessage(list_or_summary)}"
              )
            )
          )
        }

        data_summary <-
          if (
            base::is.list(list_or_summary) &&
              base::identical(
                list_or_summary[["schema_version"]],
                "2.0.0"
              )
          ) {
            validate_sjsdm_artifact_envelope(
              list_artifact = list_or_summary,
              expected_artifact_type = "sjsdm_cv_tuning"
            )
            list_or_summary[["payload"]][[
              "data_candidate_repeat_summary"
            ]]
          } else {
            list_or_summary
          }

        if (
          !base::is.data.frame(data_summary)
        ) {
          cli::cli_abort(
            "Collected tuning summaries must be data frames."
          )
        }

        data_summary |>
          dplyr::mutate(
            source_store = .env[["source_store"]],
            resolution_id = .env[["resolution_id"]],
            source_id = dplyr::if_else(
              .data[["source_id"]] == "unit" &
                stringr::str_starts(
                  .env[["resolution_id"]],
                  "timeslice_"
                ),
              .env[["resolution_id"]],
              .data[["source_id"]]
            ),
            .before = 1L
          )
      }
    )

  res <-
    list_summaries |>
    purrr::list_rbind()

  return(res)
}

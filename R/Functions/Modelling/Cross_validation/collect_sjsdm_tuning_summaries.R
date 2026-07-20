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
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @return
#' Bound tuning-summary tibble with `source_store` and `resolution_id`
#' provenance columns. Every requested store-resolution target must be
#' readable. The function aborts with the failed store and target when
#' evidence is incomplete.
#' @examples
#' \dontrun{
#' collect_sjsdm_tuning_summaries(
#'   store_paths = c("store_a", "store_b"),
#'   resolution_ids = c("genus", "family")
#' )
#' }
#' @export
collect_sjsdm_tuning_summaries <- function(
    store_paths = NULL,
    resolution_ids = NULL,
    target_prefix = "data_sjsdm_tuning_summary",
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
    base::is.function(read_target_function),
    msg = "read_target_function must be a function."
  )

  data_store_resolution <-
    tidyr::crossing(
      source_store = base::unique(store_paths),
      resolution_id = base::unique(resolution_ids)
    )

  list_summaries <-
    purrr::map2(
      .x = data_store_resolution[["source_store"]],
      .y = data_store_resolution[["resolution_id"]],
      .f = ~ {
        target_name <-
          stringr::str_glue(
            "{target_prefix}_{.y}"
          ) |>
          base::as.character()

        data_summary <-
          tryCatch(
            expr = read_target_function(
              name = target_name,
              store = .x
            ),
            error = function(error_condition) {
              error_condition
            }
          )

        if (
          base::inherits(data_summary, "error")
        ) {
          cli::cli_abort(
            c(
              "Could not read every requested tuning summary.",
              "x" = stringr::str_glue(
                "{target_name} in {.x}: ",
                "{base::conditionMessage(data_summary)}"
              )
            )
          )
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
            source_store = .x,
            resolution_id = .y,
            source_id = dplyr::if_else(
              .data[["source_id"]] == "unit" &
                stringr::str_starts(.y, "timeslice_"),
              .y,
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

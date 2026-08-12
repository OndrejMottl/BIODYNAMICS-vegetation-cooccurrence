#' @title Load Target Fingerprints from a Targets Store
#' @description
#' Reads and validates content hashes for exact target names in an
#' external `{targets}` store. The function fails closed when metadata
#' are unavailable, incomplete, duplicated, errored, or unhashed.
#' @param store_path
#' A single non-empty character string with the targets store path.
#' @param target_names
#' A character vector of unique, non-empty target names.
#' @param meta_fn
#' Function used to read metadata. Defaults to [targets::tar_meta()].
#' @return
#' A tibble with `name` and `data_hash`, ordered by `name`.
#' @examples
#' \dontrun{
#' load_targets_target_fingerprints(
#'   store_path = "Data/targets/traits_reference/pipeline_traits_reference",
#'   target_names = c(
#'     "data_traits_classified_corrected",
#'     "data_combined_classification_table_traits"
#'   )
#' )
#' }
#' @export
load_targets_target_fingerprints <- function(
    store_path,
    target_names,
    meta_fn = targets::tar_meta) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )
  assertthat::assert_that(
    base::is.character(target_names) &&
      base::length(target_names) > 0L &&
      base::all(!base::is.na(target_names)) &&
      base::all(base::nzchar(target_names)) &&
      !base::any(base::duplicated(target_names)),
    msg = "`target_names` must contain unique non-empty strings."
  )
  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  data_metadata <-
    base::tryCatch(
      base::suppressWarnings(
        meta_fn(
          fields = base::c("name", "data", "error"),
          complete_only = FALSE,
          store = store_path
        )
      ),
      error = function(condition) {
        cli::cli_abort(
          base::c(
            "x" = "Could not read external targets-store metadata.",
            "i" = base::conditionMessage(condition)
          )
        )
      }
    )

  vec_required_columns <-
    base::c("name", "data", "error")

  if (
    !base::is.data.frame(data_metadata) ||
      !base::all(
        vec_required_columns %in% base::colnames(data_metadata)
      )
  ) {
    cli::cli_abort(
      "External targets-store metadata are malformed."
    )
  }

  data_selected <-
    data_metadata |>
    dplyr::filter(.data[["name"]] %in% target_names)

  data_counts <-
    data_selected |>
    dplyr::count(.data[["name"]], name = "metadata_row_count")

  vec_missing_targets <-
    base::setdiff(
      target_names,
      dplyr::pull(data_counts, "name")
    )

  if (
    base::length(vec_missing_targets) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "x" = "Required external targets are missing.",
        "i" = stringr::str_c(
          vec_missing_targets,
          collapse = ", "
        )
      )
    )
  }

  data_duplicate_targets <-
    data_counts |>
    dplyr::filter(.data[["metadata_row_count"]] != 1L)

  if (
    base::nrow(data_duplicate_targets) > 0L
  ) {
    cli::cli_abort(
      "Each requested target must occur exactly once in metadata."
    )
  }

  data_errored_targets <-
    data_selected |>
    dplyr::filter(
      !base::is.na(.data[["error"]]) &
        base::nzchar(.data[["error"]])
    )

  if (
    base::nrow(data_errored_targets) > 0L
  ) {
    cli::cli_abort(
      "Requested external targets include errored targets."
    )
  }

  data_missing_hashes <-
    data_selected |>
    dplyr::filter(
      base::is.na(.data[["data"]]) |
        !base::nzchar(.data[["data"]])
    )

  if (
    base::nrow(data_missing_hashes) > 0L
  ) {
    cli::cli_abort(
      "Every requested external target must have a data hash."
    )
  }

  data_fingerprints <-
    data_selected |>
    dplyr::select(dplyr::all_of(base::c("name", "data"))) |>
    dplyr::rename(data_hash = "data") |>
    dplyr::arrange(.data[["name"]])

  return(data_fingerprints)
}

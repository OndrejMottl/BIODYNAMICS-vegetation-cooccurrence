#' @title Load a Target Tracked by an External Fingerprint
#' @description
#' Loads one target from an external `{targets}` store while requiring
#' an exact, previously validated fingerprint row for that target. The
#' explicit fingerprint argument creates a local dependency on external
#' scientific content instead of depending only on the store path.
#' @param store_path
#' A single non-empty character string with the targets store path.
#' @param target_name
#' A single non-empty character string naming the target to load.
#' @param data_fingerprint
#' A one-row data frame with columns `name` and `data_hash`, as returned
#' by [load_targets_target_fingerprints()].
#' @param read_fn
#' Function used to read the target. Defaults to
#' [targets::tar_read_raw()].
#' @return
#' The target value returned by `read_fn`.
#' @examples
#' \dontrun{
#' data_fingerprint <- load_targets_target_fingerprints(
#'   store_path = "Data/targets/traits_reference/pipeline_traits_reference",
#'   target_names = "data_traits_classified_corrected"
#' )
#' load_targets_target_by_fingerprint(
#'   store_path = "Data/targets/traits_reference/pipeline_traits_reference",
#'   target_name = "data_traits_classified_corrected",
#'   data_fingerprint = data_fingerprint
#' )
#' }
#' @export
load_targets_target_by_fingerprint <- function(
    store_path,
    target_name,
    data_fingerprint,
    read_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )
  assertthat::assert_that(
    base::is.character(target_name) &&
      base::length(target_name) == 1L &&
      base::nchar(target_name) > 0L,
    msg = "`target_name` must be a single non-empty character string."
  )
  assertthat::assert_that(
    base::is.data.frame(data_fingerprint) &&
      base::identical(
        base::colnames(data_fingerprint),
        base::c("name", "data_hash")
      ) &&
      base::nrow(data_fingerprint) == 1L,
    msg = "`data_fingerprint` must be one validated fingerprint row."
  )
  assertthat::assert_that(
    base::identical(
      data_fingerprint[["name"]][[1L]],
      target_name
    ),
    msg = stringr::str_glue(
      "`data_fingerprint` does not describe target `{target_name}`."
    )
  )
  assertthat::assert_that(
    base::is.character(data_fingerprint[["data_hash"]]) &&
      base::length(data_fingerprint[["data_hash"]]) == 1L &&
      !base::is.na(data_fingerprint[["data_hash"]]) &&
      base::nzchar(data_fingerprint[["data_hash"]]),
    msg = "`data_fingerprint$data_hash` must be non-empty."
  )
  assertthat::assert_that(
    base::is.function(read_fn),
    msg = "`read_fn` must be a function."
  )

  res <-
    read_fn(
      name = target_name,
      store = store_path
    )

  return(res)
}

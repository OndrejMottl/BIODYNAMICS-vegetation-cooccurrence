#' @title Load Targets Store Metadata
#' @description
#' Reads target name and error metadata from one targets store. If the
#' metadata cannot be read, `NULL` is returned.
#' @param store_path
#' A single character string with the targets store path.
#' @param meta_fn
#' Function used to read metadata. Defaults to [targets::tar_meta()].
#' @param fields
#' Non-empty character vector of metadata fields to request.
#' @return
#' A metadata data frame, or `NULL` if metadata cannot be read.
#' @examples
#' \dontrun{
#' load_targets_store_metadata(
#'   store_path = "Data/targets/modern_spatial_continental/europe"
#' )
#' }
#' @export
load_targets_store_metadata <- function(
    store_path,
    meta_fn = targets::tar_meta,
    fields = base::c("name", "error")) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.character(fields) &&
      base::length(fields) > 0L &&
      base::all(!base::is.na(fields)) &&
      base::all(base::nzchar(fields)) &&
      !base::any(base::duplicated(fields)),
    msg = "`fields` must contain unique non-empty character strings."
  )

  res <-
    purrr::possibly(
      .f = function(path) {
        base::suppressWarnings(
          meta_fn(
            fields = fields,
            complete_only = FALSE,
            store = path
          )
        )
      },
      otherwise = NULL
    )(store_path)

  return(res)
}

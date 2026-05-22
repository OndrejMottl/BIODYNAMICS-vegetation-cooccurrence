#' @title Read Targets Store Metadata
#' @description
#' Reads target name and error metadata from one targets store. If the
#' metadata cannot be read, `NULL` is returned.
#' @param store_path
#' A single character string with the targets store path.
#' @param meta_fn
#' Function used to read metadata. Defaults to [targets::tar_meta()].
#' @return
#' A metadata data frame, or `NULL` if metadata cannot be read.
#' @examples
#' \dontrun{
#' read_targets_store_meta(
#'   store_path = "Data/targets/modern_spatial_continental/europe"
#' )
#' }
#' @export
read_targets_store_meta <- function(
    store_path,
    meta_fn = targets::tar_meta) {
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

  res <-
    purrr::possibly(
      .f = function(path) {
        meta_fn(
          fields = c("name", "error"),
          complete_only = FALSE,
          store = path
        )
      },
      otherwise = NULL
    )(store_path)

  return(res)
}

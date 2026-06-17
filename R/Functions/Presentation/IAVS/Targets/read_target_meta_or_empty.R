#' @title Read Target Metadata or Return Empty Table
#' @description
#' Reads targets metadata with name and error fields. If metadata cannot be
#' read, an empty tibble with these columns is returned.
#' @param store_path
#' Character scalar. Path to the targets store.
#' @param meta_fn
#' Function used to read metadata. Defaults to [targets::tar_meta()].
#' @return
#' Tibble with `name` and `error` columns.
#' @examples
#' \dontrun{
#' read_target_meta_or_empty(
#'   store_path = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal"
#' )
#' }
#' @export
read_target_meta_or_empty <- function(
    store_path,
    meta_fn = targets::tar_meta) {
  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::nchar(store_path) > 0L,
    msg = "'store_path' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "'meta_fn' must be a function."
  )

  res_meta <-
    purrr::possibly(
      .f = function(store) {
        meta_fn(
          fields = c("name", "error"),
          complete_only = FALSE,
          store = store
        )
      },
      otherwise = tibble::tibble(
        name = base::character(),
        error = base::character()
      )
    )(
      store_path
    )

  return(res_meta)
}

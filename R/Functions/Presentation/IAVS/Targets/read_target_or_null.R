#' @title Read a Target or Return NULL
#' @description
#' Reads one target object from a targets store and returns `NULL` when the
#' read fails.
#' @param target_name
#' Character scalar. Target name to read.
#' @param store_path
#' Character scalar. Path to the targets store.
#' @param read_fn
#' Function used to read the target. Defaults to [targets::tar_read_raw()].
#' @return
#' Target object when read succeeds; otherwise `NULL`.
#' @examples
#' \dontrun{
#' read_target_or_null(
#'   target_name = "data_community_analysis",
#'   store_path = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal"
#' )
#' }
#' @export
read_target_or_null <- function(
    target_name,
    store_path,
    read_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(target_name),
    base::length(target_name) == 1L,
    base::nchar(target_name) > 0L,
    msg = "'target_name' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::nchar(store_path) > 0L,
    msg = "'store_path' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.function(read_fn),
    msg = "'read_fn' must be a function."
  )

  res_target <-
    purrr::possibly(
      .f = function(name, store) {
        read_fn(
          name = name,
          store = store
        )
      },
      otherwise = NULL
    )(
      target_name,
      store_path
    )

  return(res_target)
}

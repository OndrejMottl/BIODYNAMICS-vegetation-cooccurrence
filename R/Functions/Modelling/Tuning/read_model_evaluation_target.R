#' @title Read a Model Evaluation Target
#' @description
#' Reads one `model_evaluation_<resolution>` target from a targets store.
#' If the target cannot be read, `NULL` is returned.
#' @param store_path
#' A single character string with the targets store path.
#' @param resolution_id
#' A single non-empty character string identifying the model resolution.
#' @param read_target_fn
#' Function used to read the target. Defaults to
#' [targets::tar_read_raw()].
#' @return
#' The model evaluation object, or `NULL` if it cannot be read.
#' @examples
#' \dontrun{
#' read_model_evaluation_target(
#'   store_path = "Data/targets/modern_spatial_continental/europe",
#'   resolution_id = "genus"
#' )
#' }
#' @export
read_model_evaluation_target <- function(
    store_path,
    resolution_id,
    read_target_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(resolution_id) &&
      base::length(resolution_id) == 1L &&
      base::nchar(resolution_id) > 0L,
    msg = "`resolution_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  target_name <-
    stringr::str_glue("model_evaluation_{resolution_id}") |>
    base::as.character()

  res <-
    purrr::possibly(
      .f = function() {
        read_target_fn(
          name = target_name,
          store = store_path
        )
      },
      otherwise = NULL
    )()

  return(res)
}

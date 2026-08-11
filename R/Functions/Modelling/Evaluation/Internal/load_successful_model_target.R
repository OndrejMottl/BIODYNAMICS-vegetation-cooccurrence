#' @title Load a Successful Model Target
#' @description
#' Loads a target only when its targets metadata records successful completion.
#' Read failures are represented by `NULL`.
#' @param data_meta
#' Targets metadata containing target names and errors.
#' @param target_name
#' Single target name to load.
#' @param store_path
#' Targets store path.
#' @param read_target_fn
#' Function used to load the target.
#' @return
#' The loaded target object, or `NULL`.
#' @keywords internal
.load_successful_model_target <- function(
    data_meta,
    target_name,
    store_path,
    read_target_fn) {
  if (
    !has_target_succeeded(data_meta, target_name)
  ) {
    return(NULL)
  }

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

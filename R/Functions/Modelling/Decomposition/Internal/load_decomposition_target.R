#' @title Load One Decomposition Target
#' @description
#' Internal adapter that forwards a target name and store to the injected
#' target-reading function.
#' @param target_name
#' Target name to load.
#' @param store_path
#' Targets store path.
#' @param tar_read_fn
#' Function used to read targets.
#' @return
#' The loaded target value.
#' @keywords internal
.load_decomposition_target <- function(
    target_name,
    store_path,
    tar_read_fn) {
  res <-
    tar_read_fn(
      name = target_name,
      store = store_path
    )

  return(res)
}

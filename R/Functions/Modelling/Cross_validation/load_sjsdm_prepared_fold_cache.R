#' @title Load the Prior Local Prepared-Fold Object
#' @description
#' Reads the prior local object without consulting target metadata during
#' target execution. Missing, unreadable or non-list objects return NULL.
#' Analytical cache eligibility remains owned by
#' [prepare_sjsdm_tuning_folds()], which reconstructs current inputs first.
#' @param file_cache
#' Local object path. The default uses the documented current-target path
#' with the running store; outside target execution it resolves to NA.
#' @param read_cache_function
#' Injectable file reader accepting a named file argument. Defaults to the
#' project's qs2 reader, compatible with its current local qs target objects.
#' @return The prior list object or NULL. No target metadata are changed.
#' @examples
#' load_sjsdm_prepared_fold_cache(file_cache = "missing-fold-cache.qs")
#' @export
load_sjsdm_prepared_fold_cache <- function(
    file_cache = targets::tar_path_target(store = targets::tar_path_store()),
    read_cache_function = qs2::qs_read) {
  assertthat::assert_that(
    base::is.character(file_cache),
    base::length(file_cache) == 1L,
    msg = "Cached prepared-fold path must be one character value."
  )
  assertthat::assert_that(
    base::is.function(read_cache_function),
    msg = "Cached prepared-fold reader must be a function."
  )
  if (
    base::is.na(file_cache) || !base::file.exists(file_cache)
  ) {
    return(NULL)
  }
  res <-
    base::tryCatch(
      expr = read_cache_function(file = file_cache),
      error = function(error_condition) NULL
    )
  if (
    !base::is.list(res)
  ) {
    return(NULL)
  }
  return(res)
}

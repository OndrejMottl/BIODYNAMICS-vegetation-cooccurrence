#' @title Resolve a Pipeline Store Path
#' @description
#' Resolves the target store for one pipeline script and optional store suffix.
#' @param pipeline_script
#' Single character string containing a pipeline script path.
#' @param target_store
#' Root targets-store path. Defaults to the active configuration value.
#' @param store_suffix
#' Optional non-empty character string nested below `target_store`.
#' @return
#' Absolute path to the pipeline-specific targets store.
#' @export
resolve_pipeline_store_path <- function(
    pipeline_script,
    target_store = load_active_config_value("target_store"),
    store_suffix = NULL) {
  assertthat::assert_that(
    base::is.character(pipeline_script) &&
      base::length(pipeline_script) == 1L &&
      !base::is.na(pipeline_script) &&
      base::nzchar(pipeline_script),
    msg = "`pipeline_script` must be one non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(target_store) &&
      base::length(target_store) == 1L &&
      !base::is.na(target_store) &&
      base::nzchar(target_store),
    msg = "`target_store` must be one non-empty character string."
  )

  assertthat::assert_that(
    base::is.null(store_suffix) ||
      (
        base::is.character(store_suffix) &&
          base::length(store_suffix) == 1L &&
          !base::is.na(store_suffix) &&
          base::nzchar(store_suffix)
      ),
    msg = "`store_suffix` must be NULL or one non-empty character string."
  )

  pipeline_name <-
    pipeline_script |>
    base::basename() |>
    tools::file_path_sans_ext()

  store_path <-
    if (
      base::is.null(store_suffix)
    ) {
      fs::path(target_store, pipeline_name)
    } else {
      fs::path(target_store, store_suffix, pipeline_name)
    }

  res <-
    fs::path_abs(
      path = store_path,
      start = here::here()
    )

  return(res)
}

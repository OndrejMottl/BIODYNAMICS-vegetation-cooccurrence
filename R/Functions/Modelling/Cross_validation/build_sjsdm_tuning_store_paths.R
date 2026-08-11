#' @title Build sjSDM Tuning Store Paths
#' @description
#' Resolves isolated unit-store paths for one unit pipeline.
#' @param unit_pipeline
#' Unit pipeline script path.
#' @param unit_store_suffixes
#' Optional nested store suffixes.
#' @param target_store
#' Root targets-store path.
#' @return
#' Character vector of deterministic unit-store paths.
#' @export
build_sjsdm_tuning_store_paths <- function(
    unit_pipeline = NULL,
    unit_store_suffixes = NULL,
    target_store = NULL) {
  assertthat::assert_that(
    base::is.character(unit_pipeline),
    base::length(unit_pipeline) == 1L,
    !base::is.na(unit_pipeline),
    base::nzchar(unit_pipeline),
    base::is.null(unit_store_suffixes) ||
      base::is.character(unit_store_suffixes),
    base::is.character(target_store),
    base::length(target_store) == 1L,
    !base::is.na(target_store),
    base::nzchar(target_store),
    msg = "Tuning store-path inputs are invalid."
  )

  sel_pipeline_name <-
    unit_pipeline |>
    base::basename() |>
    tools::file_path_sans_ext()

  res <-
    if (
      base::is.null(unit_store_suffixes)
    ) {
      base::file.path(target_store, sel_pipeline_name)
    } else {
      base::file.path(
        target_store,
        unit_store_suffixes,
        sel_pipeline_name
      )
    }

  return(res)
}

#' @title Resolve the sjSDM Tier Tuning Context
#' @description
#' Applies an optional configured resolution subset to a pipeline's default
#' tier-tuning context.
#' @param list_default_context
#' Named list describing the pipeline, resolution IDs, and store layout.
#' @param resolution_ids
#' Optional non-empty character subset of the default resolution IDs.
#' @return
#' The validated tuning context with any configured subset applied.
#' @export
resolve_sjsdm_tuning_context <- function(
    list_default_context = NULL,
    resolution_ids = NULL) {
  vec_required_fields <-
    base::c(
      "pipeline_name",
      "resolution_ids",
      "nested_unit_stores"
    )

  assertthat::assert_that(
    base::is.list(list_default_context),
    base::all(
      vec_required_fields %in% base::names(list_default_context)
    ),
    msg = "list_default_context is missing required fields."
  )

  vec_default_resolution_ids <-
    list_default_context[["resolution_ids"]]

  flag_valid_default_resolutions <-
    base::is.character(vec_default_resolution_ids) &&
    base::length(vec_default_resolution_ids) > 0L &&
    base::all(!base::is.na(vec_default_resolution_ids)) &&
    base::all(base::nzchar(vec_default_resolution_ids)) &&
    !base::any(base::duplicated(vec_default_resolution_ids))

  assertthat::assert_that(
    flag_valid_default_resolutions,
    msg = "Default resolution IDs must be unique non-empty strings."
  )

  if (
    base::is.null(resolution_ids)
  ) {
    return(list_default_context)
  }

  flag_non_empty_override <-
    base::is.character(resolution_ids) &&
    base::length(resolution_ids) > 0L &&
    base::all(!base::is.na(resolution_ids)) &&
    base::all(base::nzchar(resolution_ids))

  assertthat::assert_that(
    flag_non_empty_override,
    msg = "Configured resolution IDs must be non-empty strings."
  )
  assertthat::assert_that(
    !base::any(base::duplicated(resolution_ids)),
    msg = "Configured resolution IDs must be unique."
  )
  assertthat::assert_that(
    base::all(resolution_ids %in% vec_default_resolution_ids),
    msg = "Configured resolution IDs must be a subset of pipeline IDs."
  )

  res_context <-
    list_default_context

  res_context[["resolution_ids"]] <-
    resolution_ids

  return(res_context)
}

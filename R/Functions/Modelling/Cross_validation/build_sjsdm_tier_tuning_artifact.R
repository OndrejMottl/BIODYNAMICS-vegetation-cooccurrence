#' @title Build sjSDM Tier Tuning Artifact
#' @description
#' Runs compatible tier-level tuning aggregation and publishes an immutable
#' selected-candidate artifact with complete provenance.
#' @param data_tuning_summary
#' Source-ID tuning summaries accepted by
#' [aggregate_sjsdm_tuning_by_tier()].
#' @param created_at
#' Single POSIX date-time supplied explicitly by the orchestration layer.
#' @param include_sample_weighted
#' Logical passed to [aggregate_sjsdm_tuning_by_tier()].
#' @return
#' Named list containing artifact, source_candidate_loss,
#' candidate_aggregation, and selection_sensitivity. The artifact is a one-row
#' tibble with selected parameters, model context, source IDs, selection rule,
#' candidate-table hash, creation time, and schema version.
#' @details
#' The artifact always selects the equal-ID result. Sample-weighted selection
#' is retained only as a sensitivity report.
#' @examples
#' \dontrun{
#' build_sjsdm_tier_tuning_artifact(
#'   data_tuning_summary = data_tuning_summary,
#'   created_at = base::as.POSIXct(
#'     "2026-07-05 12:00:00",
#'     tz = "UTC"
#'   )
#' )
#' }
#' @export
build_sjsdm_tier_tuning_artifact <- function(
    data_tuning_summary = NULL,
    created_at = NULL,
    include_sample_weighted = TRUE) {
  flag_valid_created_at <-
    base::inherits(created_at, "POSIXt") &&
    base::length(created_at) == 1L &&
    !base::is.na(created_at) &&
    base::is.finite(base::as.numeric(created_at))

  assertthat::assert_that(
    flag_valid_created_at,
    msg = "created_at must be one finite POSIX date-time."
  )

  list_aggregation <-
    aggregate_sjsdm_tuning_by_tier(
      data_tuning_summary = data_tuning_summary,
      include_sample_weighted = include_sample_weighted
    )

  data_selection <-
    list_aggregation[["selection_sensitivity"]]

  data_primary_selection <-
    data_selection |>
    dplyr::filter(.data[["weighting_rule"]] == "equal_id")

  if (
    base::nrow(data_primary_selection) != 1L
  ) {
    cli::cli_abort(
      "Tier aggregation must return one equal-ID primary selection."
    )
  }

  vec_source_ids <-
    data_tuning_summary |>
    dplyr::distinct(.data[["source_id"]]) |>
    dplyr::arrange(.data[["source_id"]]) |>
    dplyr::pull("source_id")

  data_artifact <-
    data_primary_selection |>
    dplyr::mutate(
      artifact_schema_version = "2.0.0",
      regularization_source = "tier_pooled",
      source_tier = .data[["tier_id"]],
      source_ids = base::list(vec_source_ids),
      created_at = created_at,
      .before = 1L
    ) |>
    dplyr::select(
      "artifact_schema_version",
      "created_at",
      "tier_id",
      "source_tier",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash",
      "candidate_id",
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial",
      "regularization_source",
      "weighting_rule",
      "selection_metric",
      "selection_metric_value",
      "n_source_ids",
      "source_ids"
    )

  res <-
    base::list(
      artifact = data_artifact,
      source_candidate_loss =
        list_aggregation[["source_candidate_loss"]],
      candidate_aggregation =
        list_aggregation[["candidate_aggregation"]],
      selection_sensitivity =
        list_aggregation[["selection_sensitivity"]]
    )

  return(res)
}

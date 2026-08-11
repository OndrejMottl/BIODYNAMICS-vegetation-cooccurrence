#' @title Build an Empty Tier Regularization Selection
#' @description
#' Constructs the exact typed-empty tier-selection table used when a shared
#' tier artifact is unavailable or does not contain the requested context.
#' @return Typed empty tier regularization-selection tibble.
#' @export
build_sjsdm_empty_tier_regularization_selection <- function() {
  res <-
    tibble::tibble(
      artifact_schema_version = base::character(),
      created_at = base::as.POSIXct(base::character(), tz = "UTC"),
      tier_id = base::character(),
      source_tier = base::character(),
      taxonomic_resolution = base::character(),
      response_family = base::character(),
      predictor_structure = base::character(),
      candidate_table_hash = base::character(),
      candidate_id = base::character(),
      alpha_cov = base::numeric(),
      alpha_coef = base::numeric(),
      alpha_spatial = base::numeric(),
      lambda_cov = base::numeric(),
      lambda_coef = base::numeric(),
      lambda_spatial = base::numeric(),
      regularization_source = base::character(),
      weighting_rule = base::character(),
      selection_metric = base::character(),
      selection_metric_value = base::numeric(),
      n_source_ids = base::integer(),
      source_ids = base::list()
    )

  return(res)
}

#' @title Convert a v1 sjSDM Tier Regularization Selection
#' @description
#' Validates the frozen v1 tier-selection table and upgrades its embedded
#' schema marker without changing scientific content or creation provenance.
#' @param data_selection Frozen v1 tier-selection table.
#' @return Exact v2 tier-selection table.
#' @export
convert_v1_sjsdm_tier_regularization_selection <- function(
    data_selection = NULL) {
  data_empty <-
    build_sjsdm_empty_tier_regularization_selection()

  validate_sjsdm_artifact_table(
    data_value = data_selection,
    table_name = "data_tier_selection_v1",
    columns = base::colnames(data_empty),
    types = base::vapply(
      data_empty,
      base::typeof,
      base::character(1L)
    ),
    keys = base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    ),
    statuses = base::list(
      artifact_schema_version = "1.0.0",
      regularization_source = "tier_pooled"
    )
  )

  res <-
    data_selection |>
    dplyr::mutate(
      artifact_schema_version = base::rep(
        "2.0.0",
        base::nrow(data_selection)
      )
    )

  return(res)
}

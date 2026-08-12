#' @title Validate the sjsdm common regularization Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_common_regularization_payload <- function(payload = NULL) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_selection_columns <-
    base::c(
      "artifact_schema_version",
      "created_at",
      "source_tier",
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash",
      "candidate_id",
      vec_parameter_columns,
      "regularization_source",
      "weighting_rule",
      "selection_metric",
      "selection_metric_value",
      "n_source_tiers",
      "n_source_ids",
      "source_tiers",
      "predictor_structures",
      "source_ids"
    )

  vec_aggregation_columns <-
    base::c(
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash",
      "candidate_id",
      vec_parameter_columns,
      "n_source_tiers",
      "n_source_ids",
      "normalized_loss_equal_tier",
      "aggregation_status"
    )

  vec_model_index_columns <-
    base::c(
      "model_id",
      "tier_id",
      "scale_id",
      "resolution_id",
      "store_path"
    )

  vec_provenance_columns <-
    base::c(
      "model_id",
      "tier_id",
      "scale_id",
      "resolution_id",
      "predictor_structure",
      "candidate_table_hash",
      "cv_strategy",
      "effective_folds",
      "n_locations",
      "n_samples",
      "n_taxa",
      "n_effective_mev",
      "candidate_id",
      "regularization_source",
      "source_tier",
      "weighting_rule",
      "fit_status",
      "fit_error"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_common_regularization",
      payload = payload,
      list_table_contracts = base::list(
        data_regularization_selection = base::list(
          columns = vec_selection_columns,
          types = stats::setNames(
            base::c(
              "character",
              "double",
              base::rep("character", 5L),
              base::rep("double", 6L),
              base::rep("character", 3L),
              "double",
              base::rep("integer", 2L),
              base::rep("list", 3L)
            ),
            vec_selection_columns
          ),
          keys = base::c(
            "taxonomic_resolution",
            "response_family",
            "candidate_table_hash"
          ),
          statuses = base::list(
            artifact_schema_version = "2.0.0",
            source_tier = "common_spatial",
            regularization_source =
              "common_spatial_sensitivity",
            weighting_rule = "equal_tier_equal_id"
          )
        ),
        data_candidate_aggregation = base::list(
          columns = vec_aggregation_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 4L),
              base::rep("double", 6L),
              base::rep("integer", 2L),
              "double",
              "character"
            ),
            vec_aggregation_columns
          ),
          keys = base::c(
            "taxonomic_resolution",
            "response_family",
            "candidate_table_hash",
            "candidate_id"
          ),
          statuses = base::list(
            aggregation_status = base::c(
              "ok",
              "incomplete_tier_evidence"
            )
          )
        ),
        data_model_index = base::list(
          columns = vec_model_index_columns,
          types = stats::setNames(
            base::rep("character", 5L),
            vec_model_index_columns
          ),
          keys = "model_id"
        ),
        data_sensitivity_provenance = base::list(
          columns = vec_provenance_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 7L),
              base::rep("integer", 5L),
              base::rep("character", 6L)
            ),
            vec_provenance_columns
          ),
          keys = "model_id",
          statuses = base::list(
            fit_status = base::c("ok", "error")
          )
        )
      )
    )

  return(res)
}

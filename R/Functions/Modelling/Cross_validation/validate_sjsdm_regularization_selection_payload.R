#' @title Validate the sjsdm regularization selection Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_regularization_selection_payload <- function(payload = NULL) {
  data_empty_unit <-
    build_sjsdm_empty_unit_regularization_selection()

  data_empty_tier <-
    build_sjsdm_empty_tier_regularization_selection()

  vec_fit_columns <-
    base::c(
      "tier_id",
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
      "cv_feasibility_status",
      "regularization_source",
      "source_tier",
      "selection_status"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_regularization_selection",
      payload = payload,
      list_table_contracts = base::list(
        data_unit_selection = base::list(
          columns = base::colnames(data_empty_unit),
          types = base::vapply(
            data_empty_unit,
            base::typeof,
            base::character(1L)
          ),
          keys = "candidate_id"
        ),
        data_tier_selection = base::list(
          columns = base::colnames(data_empty_tier),
          types = base::vapply(
            data_empty_tier,
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
            artifact_schema_version = "2.0.0",
            regularization_source = "tier_pooled"
          )
        ),
        data_selection_for_fit = base::list(
          columns = vec_fit_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 6L),
              base::rep("double", 6L),
              base::rep("character", 4L)
            ),
            vec_fit_columns
          ),
          n_rows = 1L,
          statuses = base::list(
            cv_feasibility_status = base::c(
              "grouped_kfold_feasible",
              "leave_one_location_out_required",
              "tier_pooled_regularization_required",
              "full_model_infeasible"
            ),
            regularization_source = base::c(
              "unit_cv",
              "tier_pooled",
              "none"
            ),
            selection_status = base::c(
              "selected",
              "full_model_infeasible"
            )
          )
        )
      )
    )

  return(res)
}

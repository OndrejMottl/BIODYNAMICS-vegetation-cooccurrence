#' @title Validate the sjsdm cv predictions Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_cv_prediction_payload <- function(payload = NULL) {
  vec_prediction_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "row_index",
      "location_id",
      "dataset_name",
      "age",
      "taxon",
      "observed",
      "predicted_probability",
      "null_probability",
      "prediction_status"
    )

  vec_diagnostic_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "candidate_id",
      "fit_seed",
      "n_train_samples",
      "n_test_samples",
      "n_taxa_retained",
      "n_effective_mev",
      "fit_status",
      "error_message",
      "cv_strategy",
      "regularization_source"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_cv_predictions",
      payload = payload,
      list_table_contracts = base::list(
        data_predictions = base::list(
          columns = vec_prediction_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "integer",
              "character",
              "character",
              "double",
              "character",
              "double",
              "double",
              "double",
              "character"
            ),
            vec_prediction_columns
          ),
          keys = base::c("repeat_id", "row_index", "taxon"),
          statuses = base::list(
            prediction_status = base::c(
              "ok",
              "preparation_error",
              "fit_error",
              "prediction_error",
              "test_row_not_aligned",
              "constant_in_training"
            )
          )
        ),
        data_fold_diagnostics = base::list(
          columns = vec_diagnostic_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "character",
              "integer",
              "integer",
              "integer",
              "integer",
              "integer",
              "character",
              "character",
              "character",
              "character"
            ),
            vec_diagnostic_columns
          ),
          keys = base::c("repeat_id", "fold_id"),
          statuses = base::list(
            fit_status = base::c(
              "ok",
              "preparation_error",
              "fit_error",
              "prediction_error"
            )
          )
        )
      )
    )

  return(res)
}

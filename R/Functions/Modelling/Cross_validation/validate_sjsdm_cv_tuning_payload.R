#' @title Validate the sjsdm cv tuning Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_cv_tuning_payload <- function(payload = NULL) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  vec_schedule_columns <-
    base::c(
      "tuning_strategy",
      "strategy_version",
      "round_id",
      "repeat_id",
      "n_candidates_entering",
      "n_candidates_surviving"
    )

  vec_metric_columns <-
    base::colnames(
      build_sjsdm_empty_tuning_result()[["data_tuning"]]
    )

  vec_summary_columns <-
    base::c(
      "repeat_id",
      "candidate_id",
      vec_parameter_columns,
      "n_folds_total",
      "n_folds_successful",
      "n_response_values",
      "negative_log_likelihood_test",
      "negative_log_likelihood_per_response",
      "auc_macro_test",
      "summary_status",
      "cv_strategy",
      "regularization_source",
      "source_id",
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  vec_timing_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "candidate_id",
      "stage",
      "elapsed_seconds",
      "execution_status"
    )

  vec_provenance_columns <-
    base::c(
      "tuning_strategy",
      "tuning_strategy_version",
      "evaluation_prediction_source",
      "work_item_identity_version",
      "restart_boundary",
      "n_rounds",
      "n_work_items_materialized",
      "n_fold_preparations",
      "n_fits_executed",
      "n_successful_fits",
      "n_selected_refits_reused",
      "n_fits_exhaustive",
      "n_fits_historical",
      "fit_reduction_fraction"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_cv_tuning",
      payload = payload,
      list_table_contracts = base::list(
        data_candidates = base::list(
          columns = vec_candidate_columns,
          types = stats::setNames(
            base::c("character", base::rep("double", 6L)),
            vec_candidate_columns
          ),
          keys = "candidate_id"
        ),
        data_schedule = base::list(
          columns = vec_schedule_columns,
          types = stats::setNames(
            base::c(
              "character",
              "character",
              base::rep("integer", 4L)
            ),
            vec_schedule_columns
          ),
          keys = base::c("round_id", "repeat_id"),
          statuses = base::list(
            tuning_strategy = base::c("exhaustive", "staged")
          )
        ),
        data_candidate_fold_metrics = base::list(
          columns = vec_metric_columns,
          types = stats::setNames(
            base::vapply(
              build_sjsdm_empty_tuning_result()[["data_tuning"]],
              base::typeof,
              base::character(1L)
            ),
            vec_metric_columns
          ),
          keys = base::c("repeat_id", "fold_id", "candidate_id"),
          statuses = base::list(
            fit_status = base::c(
              "ok",
              "preparation_error",
              "fit_error",
              "prediction_error",
              "scoring_error"
            )
          )
        ),
        data_candidate_repeat_summary = base::list(
          columns = vec_summary_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "character",
              base::rep("double", 6L),
              base::rep("integer", 3L),
              base::rep("double", 3L),
              base::rep("character", 9L)
            ),
            vec_summary_columns
          ),
          keys = base::c("repeat_id", "candidate_id"),
          statuses = base::list(
            summary_status = base::c("ok", "incomplete")
          )
        ),
        data_stage_timings = base::list(
          columns = vec_timing_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "character",
              "character",
              "double",
              "character"
            ),
            vec_timing_columns
          ),
          keys = base::c(
            "repeat_id",
            "fold_id",
            "candidate_id",
            "stage"
          ),
          statuses = base::list(
            stage = base::c(
              "preparation",
              "fit",
              "prediction",
              "scoring"
            ),
            execution_status = base::c(
              "ok",
              "error",
              "preparation_error",
              "fit_error",
              "prediction_error",
              "scoring_error"
            )
          )
        ),
        data_execution_provenance = base::list(
          columns = vec_provenance_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 5L),
              base::rep("integer", 8L),
              "double"
            ),
            vec_provenance_columns
          ),
          n_rows = 1L
        )
      )
    )

  list_prediction_cache <-
    payload[["list_prediction_cache"]]

  vec_cache_names <-
    base::c(
      "list_fold_context",
      "list_prepared_fold",
      "preparation_seconds",
      "list_candidate_predictions"
    )

  flag_valid_cache <-
    purrr::every(
      list_prediction_cache,
      ~ {
        if (
          !base::is.list(.x) ||
            !base::identical(base::names(.x), vec_cache_names) ||
            !base::is.list(.x[["list_fold_context"]]) ||
            !base::is.list(.x[["list_candidate_predictions"]])
        ) {
          return(FALSE)
        }

        vec_candidate_ids <-
          purrr::map_chr(
            .x[["list_candidate_predictions"]],
            ~ .x[["candidate_id"]]
          )

        return(!base::any(base::duplicated(vec_candidate_ids)))
      }
    )

  if (
    !flag_valid_cache
  ) {
    cli::cli_abort("The tuning prediction cache is malformed.")
  }

  return(res)
}

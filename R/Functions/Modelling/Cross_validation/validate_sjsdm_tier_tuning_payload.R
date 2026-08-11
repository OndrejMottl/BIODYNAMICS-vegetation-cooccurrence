#' @title Validate the sjsdm tier tuning Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_tier_tuning_payload <- function(payload = NULL) {
  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

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
      "tier_id",
      "source_tier",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash",
      "candidate_id",
      vec_parameter_columns,
      "regularization_source",
      "weighting_rule",
      "selection_metric",
      "selection_metric_value",
      "n_source_ids",
      "source_ids"
    )

  vec_source_loss_columns <-
    base::c(
      vec_context_columns,
      "source_id",
      "candidate_id",
      vec_parameter_columns,
      "n_repeats",
      "n_response_values",
      "normalized_loss",
      "source_status"
    )

  vec_aggregation_columns <-
    base::c(
      vec_context_columns,
      "candidate_id",
      vec_parameter_columns,
      "n_source_ids",
      "n_source_ids_complete",
      "normalized_loss_equal_id",
      "normalized_loss_sample_weighted",
      "aggregation_status"
    )

  vec_sensitivity_columns <-
    base::c(
      vec_context_columns,
      "weighting_rule",
      "candidate_id",
      vec_parameter_columns,
      "selection_metric",
      "selection_metric_value",
      "n_source_ids",
      "differs_from_primary"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_tier_tuning",
      payload = payload,
      list_table_contracts = base::list(
        data_regularization_selection = base::list(
          columns = vec_selection_columns,
          types = stats::setNames(
            base::c(
              "character",
              "double",
              base::rep("character", 7L),
              base::rep("double", 6L),
              base::rep("character", 3L),
              "double",
              "integer",
              "list"
            ),
            vec_selection_columns
          ),
          keys = vec_context_columns,
          statuses = base::list(
            artifact_schema_version = "2.0.0",
            regularization_source = "tier_pooled",
            weighting_rule = "equal_id"
          )
        ),
        data_source_candidate_loss = base::list(
          columns = vec_source_loss_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 7L),
              base::rep("double", 6L),
              base::rep("integer", 2L),
              "double",
              "character"
            ),
            vec_source_loss_columns
          ),
          keys = base::c(
            vec_context_columns,
            "source_id",
            "candidate_id"
          ),
          statuses = base::list(
            source_status = base::c("ok", "incomplete")
          )
        ),
        data_candidate_aggregation = base::list(
          columns = vec_aggregation_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 6L),
              base::rep("double", 6L),
              base::rep("integer", 2L),
              base::rep("double", 2L),
              "character"
            ),
            vec_aggregation_columns
          ),
          keys = base::c(vec_context_columns, "candidate_id"),
          statuses = base::list(
            aggregation_status = base::c(
              "ok",
              "incomplete_source_evidence"
            )
          )
        ),
        data_selection_sensitivity = base::list(
          columns = vec_sensitivity_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 7L),
              base::rep("double", 6L),
              "character",
              "double",
              "integer",
              "logical"
            ),
            vec_sensitivity_columns
          ),
          keys = base::c(vec_context_columns, "weighting_rule"),
          statuses = base::list(
            weighting_rule = base::c("equal_id", "sample_weighted")
          )
        )
      )
    )

  list_round_decisions <-
    payload[["list_round_decisions"]]

  vec_round_names <-
    base::names(list_round_decisions)

  flag_valid_round_names <-
    base::length(list_round_decisions) == 0L ||
      base::identical(
        vec_round_names,
        stringr::str_c(
          "round_",
          base::seq_along(list_round_decisions)
        )
      )

  if (
    !flag_valid_round_names
  ) {
    cli::cli_abort("Tier round decisions must be consecutive and named.")
  }

  vec_round_columns <-
    base::c(
      vec_context_columns,
      "round_id",
      "strategy_version",
      "repeat_id",
      "n_candidates_entering",
      "n_candidates_surviving",
      "candidate_id",
      "candidate_rank",
      "normalized_loss_equal_id",
      "staged_decision"
    )

  vec_round_types <-
    stats::setNames(
      base::c(
        base::rep("character", 5L),
        "integer",
        "character",
        base::rep("integer", 3L),
        "character",
        "integer",
        "double",
        "character"
      ),
      vec_round_columns
    )

  for (round_index in base::seq_along(list_round_decisions)) {
    data_round <-
      list_round_decisions[[round_index]]

    validate_sjsdm_artifact_table(
      data_value = data_round,
      table_name = vec_round_names[[round_index]],
      columns = vec_round_columns,
      types = vec_round_types,
      keys = base::c(vec_context_columns, "round_id", "candidate_id"),
      statuses = base::list(
        strategy_version = "sjsdm_staged_tuning_v1",
        staged_decision = base::c("survive", "prune")
      )
    )

    if (
      base::nrow(data_round) == 0L ||
        !base::all(data_round[["round_id"]] == round_index)
    ) {
      cli::cli_abort("Tier round decisions have an invalid round ID.")
    }
  }

  return(res)
}

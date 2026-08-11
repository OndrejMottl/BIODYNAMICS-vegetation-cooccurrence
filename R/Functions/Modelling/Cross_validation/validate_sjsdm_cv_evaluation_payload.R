#' @title Validate the sjsdm cv evaluation Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_cv_evaluation_payload <- function(payload = NULL) {
  vec_metric_statuses <-
    base::c(
      "ok",
      "incomplete_predictions",
      "incomplete_null_predictions",
      "not_available_fold_infeasible",
      "undefined_no_presences",
      "undefined_no_absences",
      "undefined_fit_warning",
      "undefined_fit_failure",
      "undefined_constant_predictions",
      "undefined_separation",
      "undefined_no_evaluable_taxa"
    )

  vec_fold_metric_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "taxon",
      "prediction_source",
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  vec_model_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash",
      "candidate_id",
      "regularization_source",
      "source_tier",
      "selection_status",
      "n_locations",
      "n_samples",
      "n_taxa",
      "n_mem_locations",
      "cv_strategy",
      "effective_folds",
      "cv_feasibility_status",
      "n_repeats",
      "n_fold_fits",
      "n_successful_fold_fits",
      "n_taxa_retained_min",
      "n_effective_mev",
      "n_effective_mev_min",
      "n_effective_mev_max",
      "effective_mev_status",
      "fit_device",
      "evaluation_prediction_source",
      "evaluation_estimand",
      "evaluation_aggregation_methods",
      "evaluation_schema_version"
    )

  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_cv_evaluation",
      payload = payload,
      list_table_contracts = base::list(
        data_fold_metrics = base::list(
          columns = vec_fold_metric_columns,
          types = stats::setNames(
            base::c(
              "integer",
              "integer",
              "character",
              "character",
              "character",
              "double",
              "character",
              base::rep("integer", 3L),
              "double"
            ),
            vec_fold_metric_columns
          ),
          keys = base::c(
            "repeat_id",
            "fold_id",
            "taxon",
            "prediction_source",
            "metric_id"
          ),
          statuses = base::list(metric_status = vec_metric_statuses)
        ),
        data_model_provenance = base::list(
          columns = vec_model_columns,
          types = stats::setNames(
            base::c(
              base::rep("character", 9L),
              base::rep("integer", 4L),
              "character",
              "integer",
              "character",
              base::rep("integer", 7L),
              base::rep("character", 6L)
            ),
            vec_model_columns
          ),
          n_rows = 1L,
          statuses = base::list(
            effective_mev_status = base::c(
              "unavailable",
              "constant_across_folds",
              "varies_by_fold"
            )
          )
        )
      )
    )

  list_pooled <-
    payload[["list_pooled_evaluation"]]

  list_fold <-
    payload[["list_fold_summaries"]]

  list_repeat <-
    payload[["list_repeat_distributions"]]

  if (
    !base::identical(
      base::names(list_pooled),
      base::c("data_taxon_metrics", "data_community_summary")
    ) ||
      !base::identical(
        base::names(list_fold),
        base::c("data_source_summaries", "data_paired_improvements")
      ) ||
      !base::identical(
        base::names(list_repeat),
        base::c(
          "data_source_repeat_distributions",
          "data_paired_repeat_distributions"
        )
      )
  ) {
    cli::cli_abort("The evaluation list payloads are malformed.")
  }

  data_taxon <-
    list_pooled[["data_taxon_metrics"]]

  vec_taxon_columns <-
    base::c(
      "repeat_id",
      "taxon",
      "metric_id",
      "estimate",
      "metric_status",
      "n_observations",
      "n_presences",
      "n_absences",
      "prevalence"
    )

  validate_sjsdm_artifact_table(
    data_value = data_taxon,
    table_name = "data_taxon_metrics",
    columns = vec_taxon_columns,
    types = stats::setNames(
      base::c(
        "integer",
        base::rep("character", 2L),
        "double",
        "character",
        base::rep("integer", 3L),
        "double"
      ),
      vec_taxon_columns
    ),
    keys = base::c("repeat_id", "taxon", "metric_id"),
    statuses = base::list(metric_status = vec_metric_statuses)
  )

  data_community <-
    list_pooled[["data_community_summary"]]

  vec_community_columns <-
    base::c(
      "repeat_id",
      "metric_id",
      "summary_statistic",
      "estimate",
      "n_taxa_evaluable",
      "metric_status"
    )

  validate_sjsdm_artifact_table(
    data_value = data_community,
    table_name = "data_community_summary",
    columns = vec_community_columns,
    types = stats::setNames(
      base::c(
        "integer",
        "character",
        "character",
        "double",
        "integer",
        "character"
      ),
      vec_community_columns
    ),
    keys = base::c("repeat_id", "metric_id", "summary_statistic"),
    statuses = base::list(metric_status = vec_metric_statuses)
  )

  vec_source_columns <-
    base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate",
      "n_evaluable_fold_taxa",
      "n_total_fold_taxa",
      "fold_taxon_coverage",
      "n_folds_evaluable",
      "n_folds_total",
      "n_taxa_evaluable",
      "n_taxa_total",
      "n_observations_evaluable",
      "n_presences_evaluable",
      "n_absences_evaluable",
      "prevalence"
    )

  validate_sjsdm_artifact_table(
    data_value = list_fold[["data_source_summaries"]],
    table_name = "data_source_summaries",
    columns = vec_source_columns,
    types = stats::setNames(
      base::c(
        "integer",
        base::rep("character", 3L),
        "double",
        base::rep("integer", 2L),
        "double",
        base::rep("integer", 7L),
        "double"
      ),
      vec_source_columns
    ),
    keys = base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id"
    )
  )

  vec_paired_columns <-
    vec_source_columns

  vec_paired_columns[[2L]] <-
    "metric_id"

  vec_paired_columns[[3L]] <-
    "improvement_direction"

  validate_sjsdm_artifact_table(
    data_value = list_fold[["data_paired_improvements"]],
    table_name = "data_paired_improvements",
    columns = vec_paired_columns,
    types = stats::setNames(
      base::c(
        "integer",
        base::rep("character", 3L),
        "double",
        base::rep("integer", 2L),
        "double",
        base::rep("integer", 7L),
        "double"
      ),
      vec_paired_columns
    ),
    keys = base::c("repeat_id", "metric_id", "aggregation_id")
  )

  vec_source_repeat_columns <-
    base::c(
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate_mean",
      "estimate_median",
      "estimate_standard_deviation",
      "lwr_95",
      "upr_95",
      "n_repeats_evaluable",
      "n_repeats_total",
      "fold_taxon_coverage_mean",
      "fold_taxon_coverage_min",
      "fold_taxon_coverage_max"
    )

  validate_sjsdm_artifact_table(
    data_value = list_repeat[["data_source_repeat_distributions"]],
    table_name = "data_source_repeat_distributions",
    columns = vec_source_repeat_columns,
    types = stats::setNames(
      base::c(
        base::rep("character", 3L),
        base::rep("double", 5L),
        base::rep("integer", 2L),
        base::rep("double", 3L)
      ),
      vec_source_repeat_columns
    ),
    keys = base::c(
      "prediction_source",
      "metric_id",
      "aggregation_id"
    )
  )

  vec_paired_repeat_columns <-
    base::c(
      "metric_id",
      "improvement_direction",
      "aggregation_id",
      "estimate_mean",
      "estimate_median",
      "estimate_standard_deviation",
      "lwr_95",
      "upr_95",
      "n_repeats_evaluable",
      "n_repeats_total",
      "proportion_repeats_positive",
      "fold_taxon_coverage_mean",
      "fold_taxon_coverage_min",
      "fold_taxon_coverage_max"
    )

  validate_sjsdm_artifact_table(
    data_value = list_repeat[["data_paired_repeat_distributions"]],
    table_name = "data_paired_repeat_distributions",
    columns = vec_paired_repeat_columns,
    types = stats::setNames(
      base::c(
        base::rep("character", 3L),
        base::rep("double", 5L),
        base::rep("integer", 2L),
        base::rep("double", 4L)
      ),
      vec_paired_repeat_columns
    ),
    keys = base::c("metric_id", "aggregation_id")
  )

  return(res)
}

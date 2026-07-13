#' @title Build Common Spatial sjSDM Regularization Artifact
#' @description
#' Selects one candidate from normalized tuning losses using equal source-ID
#' weighting within each spatial tier and equal weighting across tiers.
#' @param data_tuning_summary
#' Repeat-level tuning summaries spanning compatible spatial tiers.
#' @param created_at
#' Single POSIX date-time supplied by the orchestration layer.
#' @return
#' Named list containing a one-row artifact, tier_candidate_loss, and
#' candidate_aggregation tibbles.
#' @details
#' Taxonomic resolution, response family, candidate hash, candidate IDs, and
#' candidate parameters must be compatible. Predictor structures may differ
#' across tiers and are retained explicitly in the artifact.
#' @examples
#' \dontrun{
#' build_sjsdm_common_regularization_artifact(
#'   data_tuning_summary = data_tuning_summary,
#'   created_at = base::Sys.time()
#' )
#' }
#' @export
build_sjsdm_common_regularization_artifact <- function(
    data_tuning_summary = NULL,
    created_at = NULL) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_common_context <-
    base::c(
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash"
    )

  vec_required_columns <-
    base::c(
      "tier_id",
      "predictor_structure",
      vec_common_context,
      "source_id",
      "repeat_id",
      "candidate_id",
      vec_parameter_columns,
      "n_response_values",
      "negative_log_likelihood_per_response",
      "summary_status"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    base::all(
      vec_required_columns %in% base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary must contain compatible tuning evidence."
  )

  assertthat::assert_that(
    base::inherits(created_at, "POSIXt"),
    base::length(created_at) == 1L,
    !base::is.na(created_at),
    base::is.finite(base::as.numeric(created_at)),
    msg = "created_at must be one finite POSIX date-time."
  )

  data_context_counts <-
    data_tuning_summary |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_common_context),
        ~ dplyr::n_distinct(.x, na.rm = FALSE)
      )
    )

  data_tier_context_counts <-
    data_tuning_summary |>
    dplyr::group_by(.data[["tier_id"]]) |>
    dplyr::summarise(
      n_predictor_structures = dplyr::n_distinct(
        .data[["predictor_structure"]],
        na.rm = FALSE
      ),
      .groups = "drop"
    )

  if (
    base::any(base::unlist(data_context_counts) != 1L) ||
      base::any(
        data_tier_context_counts[["n_predictor_structures"]] != 1L
      )
  ) {
    cli::cli_abort(
      "Common regularization requires compatible model contexts."
    )
  }

  list_tier_aggregation <-
    data_tuning_summary |>
    dplyr::group_split(.data[["tier_id"]]) |>
    purrr::map(aggregate_sjsdm_tuning_by_tier)

  data_tier_candidate_loss <-
    list_tier_aggregation |>
    purrr::map("candidate_aggregation") |>
    purrr::list_rbind() |>
    dplyr::select(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "n_source_ids",
      "normalized_loss_equal_id",
      "aggregation_status"
    )

  data_candidate_sets <-
    data_tier_candidate_loss |>
    dplyr::group_by(.data[["tier_id"]]) |>
    dplyr::summarise(
      candidate_ids = base::list(
        base::sort(base::unique(.data[["candidate_id"]]))
      ),
      .groups = "drop"
    )

  reference_candidate_ids <-
    data_candidate_sets[["candidate_ids"]][[1L]]

  flag_candidate_sets_match <-
    data_candidate_sets[["candidate_ids"]] |>
    purrr::map_lgl(
      ~ base::identical(.x, reference_candidate_ids)
    ) |>
    base::all()

  data_parameter_counts <-
    data_tier_candidate_loss |>
    dplyr::group_by(.data[["candidate_id"]]) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_parameter_columns),
        ~ dplyr::n_distinct(.x, na.rm = FALSE)
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(
      dplyr::if_any(
        dplyr::all_of(vec_parameter_columns),
        ~ .x != 1L
      )
    )

  if (
    !flag_candidate_sets_match ||
      base::nrow(data_parameter_counts) > 0L
  ) {
    cli::cli_abort(
      "Common regularization requires compatible candidate tables."
    )
  }

  n_source_tiers <-
    dplyr::n_distinct(data_tuning_summary[["tier_id"]])

  data_candidate_aggregation <-
    data_tier_candidate_loss |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_common_context)),
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_parameter_columns),
        dplyr::first
      ),
      n_source_tiers = dplyr::n_distinct(.data[["tier_id"]]),
      n_source_ids = base::sum(.data[["n_source_ids"]]),
      candidate_complete =
        .data[["n_source_tiers"]] == n_source_tiers &&
        base::all(.data[["aggregation_status"]] == "ok") &&
        base::all(
          base::is.finite(.data[["normalized_loss_equal_id"]])
        ),
      normalized_loss_equal_tier = dplyr::if_else(
        .data[["candidate_complete"]],
        base::mean(.data[["normalized_loss_equal_id"]]),
        NA_real_
      ),
      aggregation_status = dplyr::if_else(
        .data[["candidate_complete"]],
        "ok",
        "incomplete_tier_evidence"
      ),
      .groups = "drop"
    ) |>
    dplyr::select(-"candidate_complete") |>
    dplyr::arrange(.data[["candidate_id"]])

  data_selection <-
    data_candidate_aggregation |>
    dplyr::filter(.data[["aggregation_status"]] == "ok") |>
    dplyr::arrange(
      .data[["normalized_loss_equal_tier"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::slice_head(n = 1L)

  if (
    base::nrow(data_selection) != 1L
  ) {
    cli::cli_abort(
      "No candidate has complete common regularization evidence."
    )
  }

  source_tiers <-
    data_tuning_summary[["tier_id"]] |>
    base::unique() |>
    base::sort()

  predictor_structures <-
    data_tuning_summary[["predictor_structure"]] |>
    base::unique() |>
    base::sort()

  source_ids <-
    data_tuning_summary |>
    dplyr::distinct(.data[["tier_id"]], .data[["source_id"]]) |>
    dplyr::transmute(
      source_id = stringr::str_c(
        .data[["tier_id"]],
        .data[["source_id"]],
        sep = "/"
      )
    ) |>
    dplyr::arrange(.data[["source_id"]]) |>
    dplyr::pull("source_id")

  data_artifact <-
    data_selection |>
    dplyr::mutate(
      artifact_schema_version = "1.0.0",
      created_at = created_at,
      source_tier = "common_spatial",
      regularization_source = "common_spatial_sensitivity",
      weighting_rule = "equal_tier_equal_id",
      selection_metric =
        "negative_log_likelihood_per_response",
      selection_metric_value =
        .data[["normalized_loss_equal_tier"]],
      source_tiers = base::list(source_tiers),
      predictor_structures = base::list(predictor_structures),
      source_ids = base::list(source_ids),
      .before = 1L
    ) |>
    dplyr::select(
      "artifact_schema_version",
      "created_at",
      "source_tier",
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
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

  res <-
    base::list(
      artifact = data_artifact,
      tier_candidate_loss = data_tier_candidate_loss,
      candidate_aggregation = data_candidate_aggregation
    )

  return(res)
}

#' @title Aggregate sjSDM Tuning by Tier
#' @description
#' Aggregates normalized candidate loss within source IDs and then across a
#' compatible spatial tier using equal source-ID weighting.
#' @param data_tuning_summary
#' Repeat-level tuning summaries from
#' [summarise_sjsdm_tuning_candidates()] with source and model-context columns.
#' @param include_sample_weighted
#' Logical scalar. When true, also reports a sensitivity selection weighted by
#' the number of observed response values contributed by each source ID.
#' @return
#' Named list with source_candidate_loss, candidate_aggregation, and
#' selection_sensitivity tibbles. The primary selection always uses equal
#' source-ID weighting.
#' @details
#' Input rows must describe one tier, taxonomic resolution, response family,
#' predictor structure, and candidate-table hash. Every source ID must provide
#' the same candidate identifiers and parameter values. Candidates with an
#' incomplete result for any source ID remain visible but are not selectable.
#' @examples
#' \dontrun{
#' aggregate_sjsdm_tuning_by_tier(
#'   data_tuning_summary = data_tuning_summary
#' )
#' }
#' @export
aggregate_sjsdm_tuning_by_tier <- function(
    data_tuning_summary = NULL,
    include_sample_weighted = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    msg = "data_tuning_summary must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.logical(include_sample_weighted),
    base::length(include_sample_weighted) == 1L,
    !base::is.na(include_sample_weighted),
    msg = "include_sample_weighted must be one non-missing logical value."
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

  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  vec_required_columns <-
    base::c(
      vec_context_columns,
      "source_id",
      "repeat_id",
      "candidate_id",
      vec_parameter_columns,
      "n_response_values",
      "negative_log_likelihood_per_response",
      "summary_status"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary is missing required columns."
  )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        data_tuning_summary[
          base::c(vec_context_columns, "source_id", "candidate_id")
        ],
        base::is.character
      )
    ),
    base::is.character(data_tuning_summary[["summary_status"]]),
    msg = "Context, source, candidate, and status columns must be character."
  )

  data_context_counts <-
    data_tuning_summary |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_context_columns),
        ~ dplyr::n_distinct(.x, na.rm = FALSE)
      )
    )

  if (
    base::any(base::unlist(data_context_counts) != 1L)
  ) {
    cli::cli_abort(
      "Tier aggregation requires one compatible model context."
    )
  }

  data_duplicate_keys <-
    data_tuning_summary |>
    dplyr::count(
      .data[["source_id"]],
      .data[["repeat_id"]],
      .data[["candidate_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_keys) > 0L
  ) {
    cli::cli_abort(
      "Source, repeat, and candidate rows must be unique."
    )
  }

  data_parameter_counts <-
    data_tuning_summary |>
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

  data_candidate_sets <-
    data_tuning_summary |>
    dplyr::group_by(.data[["source_id"]]) |>
    dplyr::summarise(
      candidate_ids = base::list(
        base::sort(base::unique(.data[["candidate_id"]]))
      ),
      .groups = "drop"
    )

  vec_reference_candidates <-
    data_candidate_sets[["candidate_ids"]][[1L]]

  flag_candidate_sets_match <-
    data_candidate_sets[["candidate_ids"]] |>
    purrr::map_lgl(
      .f = ~ base::identical(.x, vec_reference_candidates)
    ) |>
    base::all()

  data_repeat_sets <-
    data_tuning_summary |>
    dplyr::group_by(
      .data[["source_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      repeat_ids = base::list(
        base::sort(base::unique(.data[["repeat_id"]]))
      ),
      .groups = "drop"
    )

  vec_reference_repeats <-
    data_repeat_sets[["repeat_ids"]][[1L]]

  flag_repeat_sets_match <-
    data_repeat_sets[["repeat_ids"]] |>
    purrr::map_lgl(
      .f = ~ base::identical(.x, vec_reference_repeats)
    ) |>
    base::all()

  if (
    base::nrow(data_parameter_counts) > 0L ||
      !flag_candidate_sets_match ||
      !flag_repeat_sets_match
  ) {
    cli::cli_abort(
      "Every source ID must use the same candidate table and repeats."
    )
  }

  source_candidate_loss <-
    data_tuning_summary |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns)),
      .data[["source_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_parameter_columns),
        dplyr::first
      ),
      n_repeats = dplyr::n_distinct(.data[["repeat_id"]]),
      source_complete =
        base::all(.data[["summary_status"]] == "ok") &&
        base::all(
          base::is.finite(
            .data[["negative_log_likelihood_per_response"]]
          )
        ) &&
        base::all(base::is.finite(.data[["n_response_values"]])) &&
        base::all(.data[["n_response_values"]] > 0L),
      n_response_values = dplyr::if_else(
        .data[["source_complete"]],
        base::sum(.data[["n_response_values"]]),
        NA_integer_
      ),
      normalized_loss = dplyr::if_else(
        .data[["source_complete"]],
        base::mean(
          .data[["negative_log_likelihood_per_response"]]
        ),
        NA_real_
      ),
      source_status = dplyr::if_else(
        .data[["source_complete"]],
        "ok",
        "incomplete"
      ),
      .groups = "drop"
    ) |>
    dplyr::select(-"source_complete") |>
    dplyr::arrange(.data[["source_id"]], .data[["candidate_id"]])

  n_source_ids_expected <-
    dplyr::n_distinct(data_tuning_summary[["source_id"]])

  candidate_aggregation <-
    source_candidate_loss |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns)),
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(vec_parameter_columns),
        dplyr::first
      ),
      n_source_ids = dplyr::n_distinct(.data[["source_id"]]),
      n_source_ids_complete =
        base::sum(.data[["source_status"]] == "ok"),
      candidate_complete =
        .data[["n_source_ids"]] == n_source_ids_expected &&
        .data[["n_source_ids_complete"]] == n_source_ids_expected,
      normalized_loss_equal_id = dplyr::if_else(
        .data[["candidate_complete"]],
        base::mean(.data[["normalized_loss"]]),
        NA_real_
      ),
      normalized_loss_sample_weighted = dplyr::if_else(
        .data[["candidate_complete"]],
        stats::weighted.mean(
          x = .data[["normalized_loss"]],
          w = .data[["n_response_values"]]
        ),
        NA_real_
      ),
      aggregation_status = dplyr::if_else(
        .data[["candidate_complete"]],
        "ok",
        "incomplete_source_evidence"
      ),
      .groups = "drop"
    ) |>
    dplyr::select(-"candidate_complete") |>
    dplyr::arrange(.data[["candidate_id"]])

  data_selectable_candidates <-
    candidate_aggregation |>
    dplyr::filter(.data[["aggregation_status"]] == "ok")

  if (
    base::nrow(data_selectable_candidates) == 0L
  ) {
    cli::cli_abort(
      "No candidate has complete tier-level source evidence."
    )
  }

  data_primary_selection <-
    data_selectable_candidates |>
    dplyr::arrange(
      .data[["normalized_loss_equal_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::mutate(
      weighting_rule = "equal_id",
      selection_metric =
        "negative_log_likelihood_per_response",
      selection_metric_value =
        .data[["normalized_loss_equal_id"]],
      differs_from_primary = FALSE
    )

  primary_candidate_id <-
    data_primary_selection[["candidate_id"]][[1L]]

  data_sample_selection <-
    data_selectable_candidates |>
    dplyr::arrange(
      .data[["normalized_loss_sample_weighted"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::mutate(
      weighting_rule = "sample_weighted",
      selection_metric =
        "negative_log_likelihood_per_response",
      selection_metric_value =
        .data[["normalized_loss_sample_weighted"]],
      differs_from_primary =
        .data[["candidate_id"]] != primary_candidate_id
    )

  selection_sensitivity <-
    if (
      include_sample_weighted
    ) {
      base::list(
        data_primary_selection,
        data_sample_selection
      ) |>
        purrr::list_rbind()
    } else {
      data_primary_selection
    }

  selection_sensitivity <-
    selection_sensitivity |>
    dplyr::select(
      dplyr::all_of(vec_context_columns),
      "weighting_rule",
      "candidate_id",
      dplyr::all_of(vec_parameter_columns),
      "selection_metric",
      "selection_metric_value",
      "n_source_ids",
      "differs_from_primary"
    )

  res <-
    base::list(
      source_candidate_loss = source_candidate_loss,
      candidate_aggregation = candidate_aggregation,
      selection_sensitivity = selection_sensitivity
    )

  return(res)
}

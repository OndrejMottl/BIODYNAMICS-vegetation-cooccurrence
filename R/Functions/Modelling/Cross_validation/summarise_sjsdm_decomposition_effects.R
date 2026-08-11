#' @title Summarize Matched-Fold sjSDM Decomposition Effects
#' @description
#' Aggregates paired component-removal effects using taxon means within folds
#' and fold means within repeats for all and eligible taxa.
#' @param data_comparisons
#' Output from [compute_sjsdm_decomposition_fold_effects()].
#' @return
#' A named list containing fold effects, repeat effects, and descriptive
#' repeat summaries with 95 percent quantile intervals.
#' @details
#' Only pairs with status `"ok"` and finite raw effects are summarized.
#' Negative component effects remain negative at every aggregation level.
#' @examples
#' \dontrun{
#' summarise_sjsdm_decomposition_effects(data_comparisons)
#' }
#' @export
summarise_sjsdm_decomposition_effects <- function(
    data_comparisons = NULL) {
  vec_required_columns <-
    base::c(
      "reduced_variant",
      "component",
      "repeat_id",
      "fold_id",
      "taxon",
      "eligible",
      "metric_id",
      "pair_status",
      "delta_full_advantage"
    )

  assertthat::assert_that(
    base::is.data.frame(data_comparisons),
    base::all(
      vec_required_columns %in% base::colnames(data_comparisons)
    ),
    base::is.logical(data_comparisons[["eligible"]]),
    msg = "data_comparisons must contain the paired-effect contract."
  )

  data_comparisons_ok <-
    data_comparisons |>
    dplyr::filter(
      .data[["pair_status"]] == "ok",
      base::is.finite(.data[["delta_full_advantage"]])
    )

  assertthat::assert_that(
    base::nrow(data_comparisons_ok) > 0L,
    msg = "At least one evaluable component effect is required."
  )

  data_scoped <-
    base::list(
      data_comparisons_ok |>
        dplyr::mutate(scope = "all_taxa"),
      data_comparisons_ok |>
        dplyr::filter(.data[["eligible"]]) |>
        dplyr::mutate(scope = "eligible_taxa")
    ) |>
    purrr::list_rbind()

  data_fold_effects <-
    data_scoped |>
    dplyr::group_by(
      .data[["scope"]],
      .data[["reduced_variant"]],
      .data[["component"]],
      .data[["metric_id"]],
      .data[["repeat_id"]],
      .data[["fold_id"]]
    ) |>
    dplyr::summarise(
      mean_delta_full_advantage =
        base::mean(.data[["delta_full_advantage"]]),
      n_taxa = dplyr::n_distinct(.data[["taxon"]]),
      .groups = "drop"
    )

  data_repeat_effects <-
    data_fold_effects |>
    dplyr::group_by(
      .data[["scope"]],
      .data[["reduced_variant"]],
      .data[["component"]],
      .data[["metric_id"]],
      .data[["repeat_id"]]
    ) |>
    dplyr::summarise(
      mean_delta_full_advantage =
        base::mean(.data[["mean_delta_full_advantage"]]),
      n_folds = dplyr::n_distinct(.data[["fold_id"]]),
      minimum_evaluable_taxa = base::min(.data[["n_taxa"]]),
      .groups = "drop"
    )

  data_summary <-
    data_repeat_effects |>
    dplyr::group_by(
      .data[["scope"]],
      .data[["reduced_variant"]],
      .data[["component"]],
      .data[["metric_id"]]
    ) |>
    dplyr::summarise(
      lwr_95 = stats::quantile(
        .data[["mean_delta_full_advantage"]],
        probs = 0.025,
        names = FALSE
      ),
      upr_95 = stats::quantile(
        .data[["mean_delta_full_advantage"]],
        probs = 0.975,
        names = FALSE
      ),
      minimum_repeat_delta =
        base::min(.data[["mean_delta_full_advantage"]]),
      maximum_repeat_delta =
        base::max(.data[["mean_delta_full_advantage"]]),
      proportion_positive_repeats =
        base::mean(.data[["mean_delta_full_advantage"]] > 0),
      n_repeats = dplyr::n(),
      mean_delta_full_advantage =
        base::mean(.data[["mean_delta_full_advantage"]]),
      .groups = "drop"
    )

  res <-
    base::list(
      data_fold_effects = data_fold_effects,
      data_repeat_effects = data_repeat_effects,
      data_summary = data_summary
    )

  return(res)
}

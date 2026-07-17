#' @title Compare Matched-Fold sjSDM Decomposition Metrics
#' @description
#' Pairs full and reduced sjSDM metrics by repeat, fold, taxon, and metric,
#' retaining raw component-removal effects and explicit evaluability statuses.
#' @param data_fold_metrics
#' Long-format metric table containing full and reduced model variants.
#' @param data_taxon_eligibility
#' Taxon table containing unique `taxon` and logical `eligible` columns.
#' @return
#' A tibble with one row per reduced variant, repeat, fold, taxon, and metric.
#' `delta_full_advantage` is positive when the full model performs better.
#' @details
#' For Tjur R2 and AUC, the effect is full minus reduced. For log loss and
#' Brier score, the effect is reduced minus full. Negative effects are retained.
#' @examples
#' \dontrun{
#' compare_sjsdm_decomposition_fold_metrics(
#'   data_fold_metrics = data_metrics,
#'   data_taxon_eligibility = data_eligibility
#' )
#' }
#' @export
compare_sjsdm_decomposition_fold_metrics <- function(
    data_fold_metrics = NULL,
    data_taxon_eligibility = NULL) {
  vec_required_metric_columns <-
    base::c(
      "variant",
      "repeat_id",
      "fold_id",
      "taxon",
      "metric_id",
      "estimate",
      "metric_status"
    )

  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    base::all(
      vec_required_metric_columns %in%
        base::colnames(data_fold_metrics)
    ),
    msg = "data_fold_metrics must contain the decomposition metric contract."
  )

  assertthat::assert_that(
    base::is.data.frame(data_taxon_eligibility),
    base::all(
      base::c("taxon", "eligible") %in%
        base::colnames(data_taxon_eligibility)
    ),
    base::is.logical(data_taxon_eligibility[["eligible"]]),
    msg = "data_taxon_eligibility must identify eligible taxa."
  )

  vec_key_columns <-
    base::c("variant", "repeat_id", "fold_id", "taxon", "metric_id")

  data_duplicate_keys <-
    data_fold_metrics |>
    dplyr::count(
      dplyr::across(dplyr::all_of(vec_key_columns)),
      name = "n_key"
    ) |>
    dplyr::filter(.data[["n_key"]] > 1L)

  data_duplicate_eligibility <-
    data_taxon_eligibility |>
    dplyr::count(.data[["taxon"]], name = "n_taxon") |>
    dplyr::filter(.data[["n_taxon"]] > 1L)

  assertthat::assert_that(
    base::nrow(data_duplicate_keys) == 0L,
    base::nrow(data_duplicate_eligibility) == 0L,
    msg = "Metric and eligibility keys must be unique."
  )

  vec_supported_metrics <-
    base::c("tjur_r2", "auc", "log_loss", "brier_score")

  vec_component_labels <-
    base::c(
      no_abiotic = "Abiotic",
      no_spatial = "Spatial",
      no_associations = "Associations"
    )

  data_metrics_supported <-
    data_fold_metrics |>
    dplyr::filter(.data[["metric_id"]] %in% vec_supported_metrics)

  vec_reduced_variants <-
    data_metrics_supported |>
    dplyr::filter(.data[["variant"]] != "full") |>
    dplyr::distinct(.data[["variant"]]) |>
    dplyr::pull(.data[["variant"]])

  assertthat::assert_that(
    "full" %in% data_metrics_supported[["variant"]],
    base::length(vec_reduced_variants) > 0L,
    base::all(vec_reduced_variants %in% base::names(vec_component_labels)),
    msg = "Metrics must contain full and supported reduced variants."
  )

  data_full <-
    data_metrics_supported |>
    dplyr::filter(.data[["variant"]] == "full") |>
    dplyr::select(-dplyr::all_of("variant")) |>
    dplyr::rename(
      estimate_full = "estimate",
      metric_status_full = "metric_status"
    )

  data_reduced <-
    data_metrics_supported |>
    dplyr::filter(.data[["variant"]] != "full") |>
    dplyr::rename(
      reduced_variant = "variant",
      estimate_reduced = "estimate",
      metric_status_reduced = "metric_status"
    )

  vec_pair_columns <-
    base::c("repeat_id", "fold_id", "taxon", "metric_id")

  data_expected_pairs <-
    data_full |>
    dplyr::select(dplyr::all_of(vec_pair_columns)) |>
    tidyr::crossing(reduced_variant = vec_reduced_variants)

  data_taxon_eligibility_selected <-
    data_taxon_eligibility |>
    dplyr::select(
      dplyr::all_of(base::c("taxon", "eligible"))
    )

  res <-
    data_expected_pairs |>
    dplyr::left_join(
      data_full,
      by = vec_pair_columns
    ) |>
    dplyr::left_join(
      data_reduced,
      by = base::c(vec_pair_columns, "reduced_variant")
    ) |>
    dplyr::left_join(
      data_taxon_eligibility_selected,
      by = "taxon"
    ) |>
    dplyr::mutate(
      component = vec_component_labels[.data[["reduced_variant"]]],
      pair_status = dplyr::case_when(
        .data[["metric_status_full"]] != "ok" |
          !base::is.finite(.data[["estimate_full"]]) ~
          "full_not_evaluable",
        base::is.na(.data[["metric_status_reduced"]]) |
          .data[["metric_status_reduced"]] != "ok" |
          !base::is.finite(.data[["estimate_reduced"]]) ~
          "reduced_not_evaluable",
        TRUE ~ "ok"
      ),
      delta_full_advantage = dplyr::case_when(
        .data[["pair_status"]] != "ok" ~ NA_real_,
        .data[["metric_id"]] %in% base::c("log_loss", "brier_score") ~
          .data[["estimate_reduced"]] - .data[["estimate_full"]],
        TRUE ~ .data[["estimate_full"]] - .data[["estimate_reduced"]]
      )
    ) |>
    dplyr::select(
      dplyr::all_of(
        base::c(
          "reduced_variant",
          "component",
          "repeat_id",
          "fold_id",
          "taxon",
          "eligible",
          "metric_id",
          "estimate_full",
          "estimate_reduced",
          "delta_full_advantage",
          "metric_status_full",
          "metric_status_reduced",
          "pair_status"
        )
      )
    )

  assertthat::assert_that(
    !base::anyNA(res[["eligible"]]),
    msg = "Every compared taxon must have an eligibility decision."
  )

  return(res)
}

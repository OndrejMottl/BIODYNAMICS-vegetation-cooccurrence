#' @title Select sjSDM CV Calibration Representatives
#' @description
#' Deterministically selects the maximum-complexity spatial unit in each
#' analysis-tier-resolution group across continents and every supplied eligible
#' paleo temporal profile. Historical final-model outliers
#' are retained in provenance but do not trigger independent CV ladders.
#' @param data_units
#' Unit inventory with analysis, grouping, complexity-count, historical-budget,
#' and temporal indicator columns.
#' @return
#' Selected unit rows with `complexity_score` and semicolon-delimited
#' `selection_reason`.
#' @examples
#' \dontrun{
#' select_sjsdm_cv_calibration_representatives(data_units)
#' }
#' @export
select_sjsdm_cv_calibration_representatives <- function(
    data_units = NULL) {
  vec_required_columns <-
    base::c(
      "analysis_id",
      "tier_id",
      "continent_id",
      "resolution_id",
      "scale_id",
      "n_locations",
      "n_samples",
      "n_taxa",
      "n_iter",
      "n_sampling",
      "n_early_stopping",
      "is_temporal",
      "cv_strategy",
      "effective_folds"
    )

  assertthat::assert_that(
    base::is.data.frame(data_units),
    base::all(vec_required_columns %in% base::colnames(data_units)),
    msg = "Calibration unit inventory is incomplete or duplicated."
  )

  vec_unit_key <-
    base::c(
      "analysis_id",
      "tier_id",
      "continent_id",
      "resolution_id",
      "scale_id"
    )

  assertthat::assert_that(
    !base::any(base::duplicated(data_units[vec_unit_key])),
    msg = "Calibration unit inventory is incomplete or duplicated."
  )

  data_scored <-
    data_units |>
    dplyr::mutate(
      complexity_score =
        .data[["n_taxa"]] *
        (.data[["n_samples"]] + .data[["n_locations"]]),
      historical_outlier =
        .data[["n_iter"]] > 6400L |
        .data[["n_sampling"]] > 1000L |
        dplyr::coalesce(.data[["n_early_stopping"]] == 0L, FALSE)
    ) |>
    dplyr::filter(
      .data[["cv_strategy"]] == "spatially_stratified_group_kfold",
      .data[["effective_folds"]] >= 5L
    )

  vec_group_columns <-
    base::c(
      "analysis_id",
      "tier_id",
      "resolution_id"
    )

  data_spatial_representatives <-
    data_scored |>
    dplyr::filter(!.data[["is_temporal"]]) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(vec_group_columns))) |>
    dplyr::group_modify(
      ~ {
        .x |>
          dplyr::arrange(
            dplyr::desc(.data[["complexity_score"]]),
            .data[["scale_id"]]
          ) |>
          dplyr::slice_head(n = 1L) |>
          dplyr::mutate(selection_reason = "maximum_complexity")
      }
    ) |>
    dplyr::ungroup()

  data_temporal <-
    data_scored |>
    dplyr::filter(.data[["is_temporal"]]) |>
    dplyr::mutate(selection_reason = "paleo_temporal_profile")

  res <-
    dplyr::bind_rows(
      data_spatial_representatives,
      data_temporal
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(vec_unit_key))) |>
    dplyr::summarise(
      dplyr::across(
        -dplyr::all_of("selection_reason"),
        dplyr::first
      ),
      selection_reason = stringr::str_c(
        base::sort(base::unique(.data[["selection_reason"]])),
        collapse = ";"
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data[["analysis_id"]],
      .data[["tier_id"]],
      .data[["continent_id"]],
      .data[["resolution_id"]],
      .data[["scale_id"]]
    )

  return(res)
}

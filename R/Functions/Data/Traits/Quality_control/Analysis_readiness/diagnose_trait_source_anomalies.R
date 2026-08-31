#' @title Diagnose Trait Source Anomalies
#' @description
#' Prioritises multiplicative source-taxon unit anomalies using positive trait
#' medians, independent-source agreement, and robust domain-level log ranges.
#' The findings are diagnostic and never modify or approve corrections.
#' @param data_trait_records Long trait records retaining taxon, source, domain,
#' and value columns.
#' @param source_factor_relative_tolerance Maximum relative distance from the
#' nearest power-of-ten factor.
#' @param minimum_log10_gap Minimum absolute source comparison gap.
#' @param outlier_fence_multiplier Non-negative domain log-IQR multiplier.
#' @return A named list containing `data_source_taxon_summary`,
#' `data_source_anomalies`, and `data_domain_summary`.
#' @examples
#' diagnose_trait_source_anomalies(
#'   tibble::tibble(
#'     taxon_name = c("A", "A"),
#'     data_source_id = c(1L, 2L),
#'     trait_domain_name = "Stem specific density",
#'     trait_value = c(0.0003, 0.3)
#'   )
#' )
#' @export
diagnose_trait_source_anomalies <- function(
    data_trait_records,
    source_factor_relative_tolerance = 0.25,
    minimum_log10_gap = 0.75,
    outlier_fence_multiplier = 3) {
  vec_required_columns <-
    base::c(
      "taxon_name",
      "data_source_id",
      "trait_domain_name",
      "trait_value"
    )
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    base::all(vec_required_columns %in% base::names(data_trait_records)),
    msg = "Trait source records are missing required columns."
  )
  vec_parameters <-
    base::c(
      source_factor_relative_tolerance,
      minimum_log10_gap,
      outlier_fence_multiplier
    )
  assertthat::assert_that(
    base::all(base::is.finite(vec_parameters)),
    base::all(vec_parameters >= 0),
    msg = "Source anomaly thresholds must be finite and non-negative."
  )
  assertthat::assert_that(
    base::all(
      base::is.finite(data_trait_records[["trait_value"]]) &
        data_trait_records[["trait_value"]] > 0
    ),
    msg = "Source anomaly diagnosis requires positive finite values."
  )

  data_source_taxon_base <-
    data_trait_records |>
    dplyr::group_by(
      .data[["taxon_name"]],
      .data[["trait_domain_name"]],
      .data[["data_source_id"]]
    ) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      source_taxon_median = stats::median(.data[["trait_value"]]),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      source_taxon_log10_median =
        base::log10(.data[["source_taxon_median"]])
    )
  data_source_taxon_summary <-
    data_source_taxon_base |>
    dplyr::group_by(
      .data[["taxon_name"]],
      .data[["trait_domain_name"]]
    ) |>
    dplyr::mutate(
      n_sources_for_taxon = dplyr::n(),
      other_source_median = purrr::map_dbl(
        base::seq_len(dplyr::n()),
        function(index_source) {
          if (
            dplyr::n() == 1L
          ) {
            return(NA_real_)
          }
          stats::median(
            .data[["source_taxon_median"]][-index_source]
          )
        }
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      cross_source_ratio =
        .data[["other_source_median"]] /
          .data[["source_taxon_median"]],
      cross_source_log10_gap = base::abs(
        base::log10(.data[["cross_source_ratio"]])
      ),
      cross_source_nearest_factor =
        10^base::round(base::log10(.data[["cross_source_ratio"]])),
      cross_source_factor_relative_error = base::abs(
        .data[["cross_source_ratio"]] -
          .data[["cross_source_nearest_factor"]]
      ) / .data[["cross_source_nearest_factor"]],
      flag_cross_source_corroborated =
        .data[["n_sources_for_taxon"]] > 1L &
          .data[["cross_source_log10_gap"]] >= minimum_log10_gap &
          .data[["cross_source_factor_relative_error"]] <=
            source_factor_relative_tolerance
    )
  data_domain_summary <-
    data_source_taxon_summary |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::summarise(
      n_source_taxon_groups = dplyr::n(),
      domain_log10_median = stats::median(
        .data[["source_taxon_log10_median"]]
      ),
      lwr_25_log10 = stats::quantile(
        .data[["source_taxon_log10_median"]],
        probs = 0.25,
        names = FALSE
      ),
      upr_75_log10 = stats::quantile(
        .data[["source_taxon_log10_median"]],
        probs = 0.75,
        names = FALSE
      ),
      iqr_log10 = stats::IQR(
        .data[["source_taxon_log10_median"]]
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      global_outlier_lwr =
        .data[["lwr_25_log10"]] -
          outlier_fence_multiplier * .data[["iqr_log10"]],
      global_outlier_upr =
        .data[["upr_75_log10"]] +
          outlier_fence_multiplier * .data[["iqr_log10"]]
    )
  data_source_taxon_diagnosed <-
    data_source_taxon_summary |>
    dplyr::left_join(
      data_domain_summary,
      by = dplyr::join_by(trait_domain_name),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      flag_global_log_outlier =
        .data[["source_taxon_log10_median"]] <
          .data[["global_outlier_lwr"]] |
          .data[["source_taxon_log10_median"]] >
            .data[["global_outlier_upr"]],
      global_ratio_to_median =
        10^.data[["domain_log10_median"]] /
          .data[["source_taxon_median"]],
      global_nearest_factor =
        10^base::round(base::log10(.data[["global_ratio_to_median"]])),
      suggested_scale_factor = dplyr::if_else(
        .data[["flag_cross_source_corroborated"]],
        .data[["cross_source_nearest_factor"]],
        .data[["global_nearest_factor"]]
      ),
      diagnostic_reason = dplyr::case_when(
        .data[["flag_cross_source_corroborated"]] &
          .data[["flag_global_log_outlier"]] ~
          "cross_source_power_of_ten_and_global_outlier",
        .data[["flag_cross_source_corroborated"]] ~
          "cross_source_power_of_ten",
        .data[["flag_global_log_outlier"]] ~
          "global_log_outlier",
        TRUE ~ "no_anomaly"
      ),
      diagnostic_priority = dplyr::case_when(
        .data[["flag_cross_source_corroborated"]] &
          .data[["flag_global_log_outlier"]] ~ "high",
        .data[["flag_cross_source_corroborated"]] ~ "high",
        .data[["flag_global_log_outlier"]] ~ "medium",
        TRUE ~ "none"
      )
    )
  data_source_anomalies <-
    data_source_taxon_diagnosed |>
    dplyr::filter(
      .data[["flag_cross_source_corroborated"]] |
        .data[["flag_global_log_outlier"]]
    ) |>
    dplyr::arrange(
      dplyr::desc(.data[["diagnostic_priority"]]),
      .data[["trait_domain_name"]],
      .data[["taxon_name"]],
      .data[["data_source_id"]]
    )

  return(
    base::list(
      data_source_taxon_summary = data_source_taxon_diagnosed,
      data_source_anomalies = data_source_anomalies,
      data_domain_summary = data_domain_summary
    )
  )
}

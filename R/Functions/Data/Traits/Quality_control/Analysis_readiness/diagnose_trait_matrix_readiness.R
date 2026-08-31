#' @title Diagnose Trait Matrix Readiness
#' @description
#' Summarises coverage, transformed dynamic range, invalid values, and robust
#' taxon-level extremes in a community trait matrix without changing values.
#' @param data_trait_table Wide taxon-by-trait data frame.
#' @param vec_trait_transformations Named transformation contract accepted by
#' [prepare_trait_matrix_for_dissimilarity()].
#' @param taxon_column Character scalar naming the taxon identifier column.
#' @param maximum_missing_fraction Maximum acceptable missing fraction per
#' trait domain.
#' @param maximum_transformed_range Maximum acceptable transformed range.
#' @param outlier_fence_multiplier Non-negative Tukey-fence multiplier.
#' @return A named list containing `data_domain_summary`,
#' `data_taxon_anomalies`, and scalar `flag_ready`.
#' @examples
#' diagnose_trait_matrix_readiness(
#'   data_trait_table = tibble::tibble(
#'     taxon_name = c("A", "B"),
#'     `Plant heigh` = c(10, 100)
#'   ),
#'   vec_trait_transformations = c(`Plant heigh` = "log10")
#' )
#' @export
diagnose_trait_matrix_readiness <- function(
    data_trait_table,
    vec_trait_transformations,
    taxon_column = "taxon_name",
    maximum_missing_fraction = 0.5,
    maximum_transformed_range = 4,
    outlier_fence_multiplier = 3) {
  vec_numeric_parameters <-
    base::c(
      maximum_missing_fraction,
      maximum_transformed_range,
      outlier_fence_multiplier
    )
  assertthat::assert_that(
    base::all(base::is.finite(vec_numeric_parameters)),
    maximum_missing_fraction >= 0,
    maximum_missing_fraction <= 1,
    maximum_transformed_range >= 0,
    outlier_fence_multiplier >= 0,
    msg = "Readiness thresholds must be finite and non-negative."
  )
  assertthat::assert_that(
    !base::anyDuplicated(data_trait_table[[taxon_column]]),
    msg = "Trait matrix taxon identifiers must be unique."
  )

  data_trait_table_prepared <-
    prepare_trait_matrix_for_dissimilarity(
      data_trait_table = data_trait_table,
      vec_trait_transformations = vec_trait_transformations,
      taxon_column = taxon_column
    )
  vec_trait_columns <-
    base::names(vec_trait_transformations)
  data_trait_values_raw <-
    data_trait_table |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(vec_trait_columns),
      names_to = "trait_domain_name",
      values_to = "trait_value_raw"
    )
  data_trait_values_prepared <-
    data_trait_table_prepared |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(vec_trait_columns),
      names_to = "trait_domain_name",
      values_to = "trait_value_prepared"
    ) |>
    dplyr::select(
      dplyr::all_of(
        base::c(
          taxon_column,
          "trait_domain_name",
          "trait_value_prepared"
        )
      )
    )
  data_trait_values <-
    data_trait_values_raw |>
    dplyr::left_join(
      data_trait_values_prepared,
      by = base::c(taxon_column, "trait_domain_name"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      transformation = vec_trait_transformations[
        .data[["trait_domain_name"]]
      ]
    )

  data_domain_fences <-
    data_trait_values |>
    dplyr::filter(!base::is.na(.data[["trait_value_prepared"]])) |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::summarise(
      lwr_25_prepared = stats::quantile(
        .data[["trait_value_prepared"]],
        probs = 0.25,
        names = FALSE
      ),
      upr_75_prepared = stats::quantile(
        .data[["trait_value_prepared"]],
        probs = 0.75,
        names = FALSE
      ),
      iqr_prepared = stats::IQR(.data[["trait_value_prepared"]]),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      outlier_lwr =
        .data[["lwr_25_prepared"]] -
          outlier_fence_multiplier * .data[["iqr_prepared"]],
      outlier_upr =
        .data[["upr_75_prepared"]] +
          outlier_fence_multiplier * .data[["iqr_prepared"]]
    )
  data_domain_summary <-
    data_trait_values |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["transformation"]]
    ) |>
    dplyr::summarise(
      n_taxa = dplyr::n(),
      n_present = base::sum(!base::is.na(.data[["trait_value_raw"]])),
      n_missing = base::sum(base::is.na(.data[["trait_value_raw"]])),
      missing_fraction = .data[["n_missing"]] / .data[["n_taxa"]],
      value_minimum_raw = base::min(
        .data[["trait_value_raw"]],
        na.rm = TRUE
      ),
      value_median_raw = stats::median(
        .data[["trait_value_raw"]],
        na.rm = TRUE
      ),
      value_maximum_raw = base::max(
        .data[["trait_value_raw"]],
        na.rm = TRUE
      ),
      value_minimum_prepared = base::min(
        .data[["trait_value_prepared"]],
        na.rm = TRUE
      ),
      value_median_prepared = stats::median(
        .data[["trait_value_prepared"]],
        na.rm = TRUE
      ),
      value_maximum_prepared = base::max(
        .data[["trait_value_prepared"]],
        na.rm = TRUE
      ),
      transformed_range =
        .data[["value_maximum_prepared"]] -
          .data[["value_minimum_prepared"]],
      .groups = "drop"
    ) |>
    dplyr::mutate(
      flag_excessive_missingness =
        .data[["missing_fraction"]] > maximum_missing_fraction,
      flag_excessive_transformed_range =
        .data[["transformed_range"]] > maximum_transformed_range
    ) |>
    dplyr::arrange(.data[["trait_domain_name"]])
  data_taxon_anomalies <-
    data_trait_values |>
    dplyr::filter(!base::is.na(.data[["trait_value_prepared"]])) |>
    dplyr::left_join(
      data_domain_fences,
      by = dplyr::join_by(trait_domain_name),
      relationship = "many-to-one"
    ) |>
    dplyr::filter(
      .data[["trait_value_prepared"]] < .data[["outlier_lwr"]] |
        .data[["trait_value_prepared"]] > .data[["outlier_upr"]]
    ) |>
    dplyr::mutate(
      anomaly_direction = dplyr::if_else(
        .data[["trait_value_prepared"]] < .data[["outlier_lwr"]],
        "low",
        "high"
      )
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[[taxon_column]]
    )
  flag_ready <-
    !base::any(data_domain_summary[["flag_excessive_missingness"]]) &&
      !base::any(
        data_domain_summary[["flag_excessive_transformed_range"]]
      ) &&
      base::nrow(data_taxon_anomalies) == 0L

  return(
    base::list(
      data_domain_summary = data_domain_summary,
      data_taxon_anomalies = data_taxon_anomalies,
      flag_ready = flag_ready
    )
  )
}

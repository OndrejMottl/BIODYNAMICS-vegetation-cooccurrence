#' @title Prepare Matched Paleo-Modern Plot Data
#' @description
#' Filters the matched synthesis table to finite association estimates and
#' joins coverage counts that make unmatched-unit exclusions explicit.
#' @param data_comparison_unit Matched paleo-modern synthesis unit table.
#' @param data_comparison_coverage Synthesis coverage table.
#' @return A tibble containing paired estimates, their difference, and matched
#' and excluded-unit counts for the corresponding tier and resolution.
#' @export
prepare_matched_paleo_modern_plot_data <- function(
    data_comparison_unit,
    data_comparison_coverage) {
  validate_manuscript_plot_data(
    data_plot = data_comparison_unit,
    required_columns = base::c(
      "scale",
      "scale_id",
      "comparison_id",
      "comparison_resolution",
      "component",
      "R2_Nagelkerke_percentage_paleo",
      "R2_Nagelkerke_percentage_modern",
      "R2_delta_modern_minus_paleo"
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_comparison_coverage,
    required_columns = base::c(
      "scale",
      "comparison_id",
      "comparison_resolution",
      "n_paleo_units",
      "n_modern_units",
      "n_matched_units",
      "n_paleo_unmatched",
      "n_modern_unmatched"
    )
  )

  data_associations <-
    data_comparison_unit |>
    dplyr::filter(
      .data$component == "Associations",
      base::is.finite(.data$R2_Nagelkerke_percentage_paleo),
      base::is.finite(.data$R2_Nagelkerke_percentage_modern),
      base::is.finite(.data$R2_delta_modern_minus_paleo)
    )

  res_data <-
    data_associations |>
    dplyr::left_join(
      data_comparison_coverage,
      by = dplyr::join_by(
        scale,
        comparison_id,
        comparison_resolution
      ),
      multiple = "error"
    ) |>
    dplyr::mutate(
      scale = base::factor(
        .data$scale,
        levels = base::c("continental", "regional", "local")
      ),
      comparison_resolution = base::factor(
        .data$comparison_resolution,
        levels = base::c("Genus", "Family", "Functional type")
      )
    )

  if (
    base::any(
      base::is.na(
        dplyr::pull(res_data, .data$n_matched_units)
      )
    )
  ) {
    cli::cli_abort(
      "Matched paleo-modern rows are missing synthesis coverage evidence."
    )
  }

  validate_manuscript_plot_data(
    data_plot = res_data,
    required_columns = base::c(
      "scale",
      "scale_id",
      "comparison_resolution",
      "R2_Nagelkerke_percentage_paleo",
      "R2_Nagelkerke_percentage_modern",
      "R2_delta_modern_minus_paleo",
      "n_matched_units",
      "n_paleo_unmatched",
      "n_modern_unmatched"
    ),
    numeric_bounds = base::list(
      R2_Nagelkerke_percentage_paleo = base::c(0, 100),
      R2_Nagelkerke_percentage_modern = base::c(0, 100),
      R2_delta_modern_minus_paleo = base::c(-100, 100),
      n_matched_units = base::c(0, Inf),
      n_paleo_unmatched = base::c(0, Inf),
      n_modern_unmatched = base::c(0, Inf)
    )
  )

  return(res_data)
}

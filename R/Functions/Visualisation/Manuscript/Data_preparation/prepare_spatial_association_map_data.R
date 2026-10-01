#' @title Prepare Spatial Association Map Data
#' @description
#' Completes paleo spatial synthesis results against the intended spatial grid
#' and preparation inventory so unavailable models are not displayed as zero.
#' @param data_unit Paleo spatial synthesis unit table.
#' @param data_spatial_grid Spatial-grid table containing unit bounds.
#' @param data_preparation_inventory Stage 02 preparation inventory.
#' @param resolution_ids Character vector of resolution identifiers to include.
#' @return A tibble with one row per unit and resolution, an association
#' percentage, model counts, and an explicit `availability_status`.
#' @export
prepare_spatial_association_map_data <- function(
    data_unit,
    data_spatial_grid,
    data_preparation_inventory,
    resolution_ids = base::c(
      "genus",
      "family",
      "functional_type"
    )) {
  validate_manuscript_plot_data(
    data_plot = data_unit,
    required_columns = base::c(
      "scale",
      "scale_id",
      "resolution_id",
      "component",
      "R2_Nagelkerke_percentage"
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_spatial_grid,
    required_columns = base::c(
      "scale",
      "scale_id",
      "continent_id",
      "x_min",
      "x_max",
      "y_min",
      "y_max"
    )
  )
  validate_manuscript_plot_data(
    data_plot = data_preparation_inventory,
    required_columns = base::c(
      "analysis_id",
      "tier_id",
      "scale_id",
      "resolution_id",
      "preparation_status",
      "cv_feasibility_status",
      "n_samples",
      "n_taxa"
    )
  )
  assertthat::assert_that(
    base::is.character(resolution_ids),
    base::length(resolution_ids) > 0L,
    !base::any(base::is.na(resolution_ids)),
    !base::any(base::duplicated(resolution_ids)),
    msg = "`resolution_ids` must contain unique non-missing IDs."
  )

  data_associations <-
    data_unit |>
    dplyr::filter(
      .data$component == "Associations",
      .data$resolution_id %in% resolution_ids
    ) |>
    dplyr::select(
      "scale",
      "scale_id",
      "resolution_id",
      association_percentage = "R2_Nagelkerke_percentage"
    )

  if (
    base::any(
      base::duplicated(
        data_associations[
          base::c("scale", "scale_id", "resolution_id")
        ]
      )
    )
  ) {
    cli::cli_abort(
      "Paleo synthesis contains duplicate association model rows."
    )
  }

  data_preparation <-
    data_preparation_inventory |>
    dplyr::filter(
      .data$analysis_id == "paleo_spatial",
      .data$resolution_id %in% resolution_ids
    ) |>
    dplyr::select(
      scale = "tier_id",
      "scale_id",
      "resolution_id",
      "preparation_status",
      "cv_feasibility_status",
      "n_samples",
      "n_taxa"
    )

  data_expected <-
    data_spatial_grid |>
    dplyr::select(
      "scale",
      "scale_id",
      "continent_id",
      "x_min",
      "x_max",
      "y_min",
      "y_max"
    ) |>
    tidyr::crossing(resolution_id = resolution_ids)

  data_resolution_positions <-
    tibble::tibble(
      resolution_id = resolution_ids,
      resolution_offset = if (
        base::length(resolution_ids) == 1L
      ) {
        0
      } else {
        base::seq(
          from = -0.23,
          to = 0.23,
          length.out = base::length(resolution_ids)
        )
      }
    )

  res_data <-
    data_expected |>
    dplyr::left_join(
      data_associations,
      by = dplyr::join_by(scale, scale_id, resolution_id),
      multiple = "error"
    ) |>
    dplyr::left_join(
      data_preparation,
      by = dplyr::join_by(scale, scale_id, resolution_id),
      multiple = "error"
    ) |>
    dplyr::left_join(
      data_resolution_positions,
      by = dplyr::join_by(resolution_id),
      multiple = "error"
    ) |>
    dplyr::mutate(
      resolution_id = base::factor(
        .data$resolution_id,
        levels = .env$resolution_ids
      ),
      availability_status = dplyr::case_when(
        base::is.finite(.data$association_percentage) ~ "available",
        .data$preparation_status == "expected_infeasible" ~
          "expected_infeasible",
        .data$cv_feasibility_status == "full_model_infeasible" ~
          "expected_infeasible",
        .default = "missing_model"
      ),
      centre_x = (.data$x_min + .data$x_max) / 2,
      centre_y = (.data$y_min + .data$y_max) / 2,
      glyph_x = .data$centre_x +
        .data$resolution_offset * (.data$x_max - .data$x_min),
      glyph_y = .data$centre_y
    ) |>
    dplyr::arrange(
      .data$continent_id,
      .data$scale,
      .data$resolution_id,
      .data$scale_id
    )

  validate_manuscript_plot_data(
    data_plot = res_data,
    required_columns = base::c(
      "continent_id",
      "scale",
      "scale_id",
      "resolution_id",
      "association_percentage",
      "availability_status",
      "glyph_x",
      "glyph_y",
      "n_samples",
      "n_taxa"
    ),
    numeric_bounds = base::list(
      association_percentage = base::c(0, 100),
      n_samples = base::c(0, Inf),
      n_taxa = base::c(0, Inf)
    )
  )

  return(res_data)
}

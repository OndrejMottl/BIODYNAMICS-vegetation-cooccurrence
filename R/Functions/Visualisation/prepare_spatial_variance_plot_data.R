#' @title Prepare Spatial Variance Plot Data
#' @description
#' Adds shared labels and percentage columns for spatial variance
#' partitioning figures.
#' @param data_unit
#' Data frame with one row per spatial unit, resolution, and component.
#' Must contain `scale`, `resolution_id`, `component`, and the column
#' selected by `percentage_source_column`.
#' @param vec_scale_levels
#' Character vector giving the display order of spatial scales.
#' @param vec_resolution_labels
#' Named character vector mapping `resolution_id` values to display
#' labels.
#' @param percentage_source_column
#' Single character string naming the column to multiply by 100.
#' Defaults to `R2_Nagelkerke_adjusted`.
#' @return
#' A tibble containing the original columns plus `scale` as an ordered
#' factor, `resolution_label` as an ordered factor, `component_label`,
#' and `component_total_percentage`.
#' @export
prepare_spatial_variance_plot_data <- function(
    data_unit,
    vec_scale_levels,
    vec_resolution_labels,
    percentage_source_column = "R2_Nagelkerke_adjusted") {
  assertthat::assert_that(
    base::is.data.frame(data_unit),
    msg = "`data_unit` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_scale_levels) &&
      base::length(vec_scale_levels) > 0L,
    msg = "`vec_scale_levels` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_resolution_labels) &&
      base::length(vec_resolution_labels) > 0L &&
      !base::is.null(base::names(vec_resolution_labels)) &&
      base::all(base::names(vec_resolution_labels) != ""),
    msg = "`vec_resolution_labels` must be a named character vector."
  )

  assertthat::assert_that(
    base::is.character(percentage_source_column) &&
      base::length(percentage_source_column) == 1L &&
      base::nchar(percentage_source_column) > 0L,
    msg = "`percentage_source_column` must be a non-empty string."
  )

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_id",
      "component",
      percentage_source_column
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_unit)),
    msg = stringr::str_glue(
      "`data_unit` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  vec_resolution_levels <-
    data_unit |>
    dplyr::distinct(
      .data$resolution_id
    ) |>
    dplyr::filter(
      !.data$resolution_id %in% base::names(vec_resolution_labels)
    ) |>
    dplyr::pull(
      .data$resolution_id
    )

  vec_resolution_levels <-
    base::c(
      base::unname(vec_resolution_labels),
      vec_resolution_levels
    )

  res_data <-
    data_unit |>
    dplyr::mutate(
      scale = base::factor(
        .data$scale,
        levels = vec_scale_levels
      ),
      resolution_label = dplyr::recode(
        .x = .data$resolution_id,
        !!!vec_resolution_labels,
        .default = .data$resolution_id
      ),
      resolution_label = base::factor(
        .data$resolution_label,
        levels = vec_resolution_levels
      ),
      component_label = dplyr::case_when(
        .data$component == "Associations" ~ "Biotic co-occurrence",
        .default = .data$component
      ),
      component_total_percentage = .data[[percentage_source_column]] * 100
    )

  return(res_data)
}

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
#' Single character string naming the source percentage column.
#' Defaults to `R2_Nagelkerke_adjusted`.
#' @param scale_source_to_percentage
#' Logical. If `TRUE`, values from
#' `percentage_source_column` are multiplied by 100. Set to `FALSE`
#' (default) when the source column is already on a 0-100 scale.
#' @param sum_over_100_action
#' Single character string controlling behavior when grouped
#' `component_total_percentage` sums exceed 100. One of `"error"`
#' (default), `"warning"`, or `"ignore"`.
#' @return
#' A tibble containing the original columns plus `scale` as an ordered
#' factor, `resolution_label` as an ordered factor, `component_label`,
#' and `component_total_percentage`.
#' @export
prepare_spatial_variance_plot_data <- function(
    data_unit,
    vec_scale_levels,
    vec_resolution_labels,
  percentage_source_column = "R2_Nagelkerke_adjusted",
  scale_source_to_percentage = FALSE,
  sum_over_100_action = "error") {
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

  assertthat::assert_that(
    base::is.logical(scale_source_to_percentage) &&
      base::length(scale_source_to_percentage) == 1L &&
      !base::is.na(scale_source_to_percentage),
    msg = "`scale_source_to_percentage` must be TRUE or FALSE."
  )

  sum_over_100_action <-
    base::match.arg(
      sum_over_100_action,
      choices = base::c("error", "warning", "ignore")
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
      component_total_percentage = if (
        isTRUE(scale_source_to_percentage)
      ) {
        .data[[percentage_source_column]] * 100
      } else {
        .data[[percentage_source_column]]
      }
    )

  vec_grouping_columns <-
    base::intersect(
      base::c(
        "data_source",
        "scale",
        "scale_id",
        "resolution_id",
        "continent_id"
      ),
      base::colnames(res_data)
    )

  data_sum_exceeding <-
    res_data |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(vec_grouping_columns)
      )
    ) |>
    dplyr::summarise(
      component_total_percentage_sum = base::sum(
        .data$component_total_percentage,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(
      .data$component_total_percentage_sum > 100 + 1e-8
    )

  if (
    base::nrow(data_sum_exceeding) > 0L
  ) {
    message_sum_exceeding <-
      stringr::str_glue(
        "Found {base::nrow(data_sum_exceeding)} grouped rows with ",
        "component sums larger than 100."
      )

    if (
      base::identical(sum_over_100_action, "error")
    ) {
      cli::cli_abort(
        c(
          "Component percentages exceed 100 for one or more groups.",
          "i" = message_sum_exceeding
        )
      )
    }

    if (
      base::identical(sum_over_100_action, "warning")
    ) {
      cli::cli_warn(
        c(
          "Component percentages exceed 100 for one or more groups.",
          "i" = message_sum_exceeding
        )
      )
    }
  }

  return(res_data)
}

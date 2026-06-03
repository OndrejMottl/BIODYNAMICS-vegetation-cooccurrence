#' @title Prepare Spatial Variance Waffle Data
#' @description
#' Creates tile positions and precomputed trivariate fill colours for
#' unit-level waffle plots.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()] and
#' containing variance components for each observation.
#' @param vec_component_colours
#' Named character vector mapping canonical component IDs to base HEX
#' colours.
#' @param n_waffle_rows
#' Positive integer giving the number of rows in each waffle panel.
#' @param vec_required_components
#' Character vector of required canonical component IDs used for
#' trivariate colour mixing.
#' @param ranking_column
#' Single character string naming the column used for within-panel
#' tile ordering. Defaults to `component_total_percentage`.
#' @param anchor_component
#' Optional single component ID used to select one row per observation
#' after colour mixing. Defaults to `"Associations"` to preserve
#' historical behaviour. When `NULL`, the first value in
#' `vec_required_components` is used.
#' @return
#' A tibble with one row per observation and columns `tile_col`,
#' `tile_row`, `tile_fill_colour`, and `point_colour`.
#' @examples
#' data_plot <-
#'   tibble::tibble(
#'     scale = base::rep("local", 6),
#'     scale_id = base::c(
#'       "local_01",
#'       "local_01",
#'       "local_01",
#'       "local_02",
#'       "local_02",
#'       "local_02"
#'     ),
#'     resolution_id = base::rep("genus", 6),
#'     resolution_label = base::rep("Genus", 6),
#'     component = base::c(
#'       "Abiotic",
#'       "Spatial",
#'       "Associations",
#'       "Abiotic",
#'       "Spatial",
#'       "Associations"
#'     ),
#'     continent_id = base::c(
#'       "europe",
#'       "europe",
#'       "europe",
#'       "asia",
#'       "asia",
#'       "asia"
#'     ),
#'     component_total_percentage = base::c(50, 30, 20, 30, 30, 40)
#'   )
#'
#' prepare_spatial_variance_waffle_data(
#'   data_plot = data_plot,
#'   vec_component_colours = base::c(
#'     "Abiotic" = "#D95F02",
#'     "Spatial" = "#7570B3",
#'     "Associations" = "#1B9E77"
#'   )
#' )
#' @export
prepare_spatial_variance_waffle_data <- function(
    data_plot,
    vec_component_colours,
    n_waffle_rows = 5L,
    vec_required_components = base::c(
      "Abiotic",
      "Spatial",
      "Associations"
    ),
    ranking_column = "component_total_percentage",
    anchor_component = "Associations") {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )

  assertthat::assert_that(
    base::is.integer(n_waffle_rows) &&
      base::length(n_waffle_rows) == 1L &&
      n_waffle_rows > 0L,
    msg = "`n_waffle_rows` must be a single positive integer."
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours) &&
      !base::is.null(base::names(vec_component_colours)),
    msg = "`vec_component_colours` must be a named character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_required_components) &&
      base::length(vec_required_components) > 0L,
    msg = "`vec_required_components` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(ranking_column) &&
      base::length(ranking_column) == 1L &&
      base::nchar(ranking_column) > 0L,
    msg = "`ranking_column` must be a non-empty string."
  )

  assertthat::assert_that(
    base::is.null(anchor_component) ||
      (base::is.character(anchor_component) &&
        base::length(anchor_component) == 1L &&
        base::nchar(anchor_component) > 0L),
    msg = "`anchor_component` must be NULL or a non-empty string."
  )

  selected_anchor_component <-
    if (base::is.null(anchor_component)) {
      vec_required_components[[1]]
    } else {
      anchor_component
    }

  assertthat::assert_that(
    selected_anchor_component %in% vec_required_components,
    msg = "`anchor_component` must be present in `vec_required_components`."
  )

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_label",
      "component",
      "continent_id",
      "component_total_percentage",
      ranking_column
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_plot)),
    msg = stringr::str_glue(
      "`data_plot` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  vec_observation_columns <-
    base::intersect(
      base::c(
        "data_source",
        "scale",
        "scale_id",
        "resolution_id",
        "resolution_label",
        "continent_id"
      ),
      base::colnames(data_plot)
    )

  if (
    base::length(vec_observation_columns) == 0L
  ) {
    cli::cli_abort(
      "Could not determine observation ID columns from `data_plot`."
    )
  }

  data_plot_prepared <-
    data_plot |>
    dplyr::mutate(
      observation_id = purrr::pmap_chr(
        dplyr::pick(
          dplyr::all_of(vec_observation_columns)
        ),
        ~ stringr::str_c(..., collapse = "__")
      )
    )

  data_plot_prepared <-
    data_plot_prepared |>
    dplyr::group_by(
      .data$observation_id
    ) |>
    dplyr::mutate(
      component_sum_required = base::sum(
        .data$component_total_percentage[
          .data$component %in% vec_required_components
        ],
        na.rm = TRUE
      )
    ) |>
    dplyr::ungroup()

  if (
    base::any(
      !base::is.finite(data_plot_prepared$component_sum_required) |
        data_plot_prepared$component_sum_required <= 0
    )
  ) {
    cli::cli_abort(
      "Required-component composition sum must be finite and positive."
    )
  }

  data_plot_prepared <-
    data_plot_prepared |>
    dplyr::mutate(
      component_total_percentage = dplyr::if_else(
        .data$component %in% vec_required_components,
        .data$component_total_percentage /
          .data$component_sum_required * 100,
        .data$component_total_percentage
      )
    ) |>
    dplyr::select(
      -"component_sum_required"
    )

  data_mixed_colours <-
    mix_variance_component_colours(
      data_component_shares = data_plot_prepared,
      vec_component_colours = vec_component_colours,
      vec_required_components = vec_required_components,
      observation_id_column = "observation_id",
      component_column = "component",
      share_column = "component_total_percentage"
    )

  data_anchor <-
    data_plot_prepared |>
    dplyr::filter(
      .data$component == selected_anchor_component
    )

  if (
    base::nrow(data_anchor) == 0L
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Input collapses to empty after filtering `{selected_anchor_component}` rows."
      )
    )
  }

  res_data <-
    data_anchor |>
    dplyr::left_join(
      y = data_mixed_colours,
      by = "observation_id"
    ) |>
    dplyr::arrange(
      .data$scale,
      .data$resolution_label,
      .data[[ranking_column]]
    ) |>
    dplyr::group_by(
      .data$scale,
      .data$resolution_label
    ) |>
    dplyr::mutate(
      tile_index = dplyr::row_number(),
      tile_col = ((.data$tile_index - 1L) %/% n_waffle_rows) + 1L,
      tile_row = ((.data$tile_index - 1L) %% n_waffle_rows) + 1L
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      point_colour = colorspace::darken(
        col = .data$tile_fill_colour,
        amount = 0.4
      )
    )

  if (
    base::any(base::is.na(res_data$tile_fill_colour))
  ) {
    cli::cli_abort(
      "Trivariate fill colours are missing for one or more observations."
    )
  }

  return(res_data)
}


#' @title Prepare Spatial Variance Waffle Data
#' @description
#' Creates tile positions and point colours for unit-level waffle plots
#' of the Associations component.
#' @param data_plot
#' Data frame returned by [prepare_spatial_variance_plot_data()] and
#' containing `continent_id` and `R2_Nagelkerke_percentage`.
#' @param n_waffle_rows
#' Positive integer giving the number of rows in each waffle panel.
#' @return
#' A tibble filtered to `component == "Associations"` with `tile_col`,
#' `tile_row`, and `point_colour` columns added.
#' @export
prepare_spatial_variance_waffle_data <- function(
    data_plot,
    n_waffle_rows = 5L) {
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

  vec_required_columns <-
    base::c(
      "scale",
      "resolution_label",
      "component",
      "continent_id",
      "R2_Nagelkerke_percentage"
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_plot)),
    msg = stringr::str_glue(
      "`data_plot` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  res_data <-
    data_plot |>
    dplyr::filter(
      .data$component == "Associations"
    ) |>
    dplyr::arrange(
      .data$scale,
      .data$resolution_label,
      .data$R2_Nagelkerke_percentage
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
        col = viridisLite::viridis(
          n = 1000L,
          option = "D"
        )[base::pmax(
          1L,
          base::pmin(
            1000L,
            base::round(.data$R2_Nagelkerke_percentage / 100 * 999) + 1L
          )
        )],
        amount = 0.4
      )
    )

  return(res_data)
}

#' @title Summarise Expected Genus Richness
#' @description
#' Sums predicted genus probabilities for each grid cell and age slice.
#' The resulting value is expected genus richness, not a probability.
#' @param data_predicted_long
#' Long prediction data with one row per grid cell, age, and taxon.
#' @param value_column
#' Character scalar naming the probability column to sum.
#' @return
#' A tibble with one row per grid cell and age, plus
#' `expected_genus_richness` and `n_taxa`.
#' @examples
#' summarise_expected_genus_richness(
#'   tibble::tibble(
#'     grid_id = c(1, 1),
#'     coord_long = c(10, 10),
#'     coord_lat = c(50, 50),
#'     age = c(0, 0),
#'     taxon = c("A", "B"),
#'     predicted_probability = c(0.2, 0.3)
#'   )
#' )
#' @export
summarise_expected_genus_richness <- function(
    data_predicted_long,
    value_column = "predicted_probability") {
  assertthat::assert_that(
    base::is.data.frame(data_predicted_long),
    msg = "`data_predicted_long` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(value_column) &&
      base::length(value_column) == 1L &&
      base::nchar(value_column) > 0L,
    msg = "`value_column` must be a single non-empty string."
  )

  vec_required_columns <-
    base::c(
      "grid_id",
      "coord_long",
      "coord_lat",
      "age",
      "taxon",
      value_column
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_predicted_long)),
    msg = stringr::str_glue(
      "`data_predicted_long` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  res_richness <-
    data_predicted_long |>
    dplyr::group_by(
      .data$grid_id,
      .data$coord_long,
      .data$coord_lat,
      .data$age
    ) |>
    dplyr::summarise(
      expected_genus_richness = base::sum(.data[[value_column]]),
      n_taxa = dplyr::n_distinct(.data$taxon),
      .groups = "drop"
    )

  return(res_richness)
}

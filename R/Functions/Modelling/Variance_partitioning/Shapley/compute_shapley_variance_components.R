#' @title Compute Shapley-Allocated Variance Components
#' @description
#' Converts a long-format variance-partitioning table into
#' per-age percentages for Abiotic, Associations, and Spatial
#' components using equal-split Shapley allocation.
#' @param data_source
#' A non-empty data frame with columns `age`, `component`, and
#' `R2_Nagelkerke`. Missing intersection labels are treated as
#' zero, and negative R² values are clamped to zero.
#' @return
#' A tibble with exactly three rows per age and columns `age`,
#' `component`, `R2_Nagelkerke_adjusted`, and
#' `R2_Nagelkerke_percentage`.
#' @details
#' Each two-way intersection is split equally between its two
#' components, and the three-way intersection is split equally
#' among all three components. The adjusted values therefore sum
#' to the total of all seven clamped fractions.
#' @seealso [extract_jsdm_variance_fractions()],
#'   [aggregate_jsdm_variance_components()]
#' @export
compute_shapley_variance_components <- function(data_source) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    base::nrow(data_source) > 0,
    msg = "'data_source' must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("age", "component", "R2_Nagelkerke") %in%
        base::colnames(data_source)
    ),
    msg = stringr::str_c(
      "'data_source' must contain columns",
      " 'age', 'component', and 'R2_Nagelkerke'."
    )
  )

  res <-
    data_source |>
    dplyr::mutate(
      R2_clamped =
        base::pmax(.data[["R2_Nagelkerke"]], 0)
    ) |>
    dplyr::group_by(.data[["age"]]) |>
    dplyr::group_modify(allocate_shapley_variance_components) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data[["age"]]) |>
    dplyr::mutate(
      R2_Nagelkerke_percentage = {
        adjusted_values <-
          .data[["R2_Nagelkerke_adjusted"]]
        adjusted_sum <-
          base::sum(adjusted_values)

        if (adjusted_sum > 0) {
          adjusted_values / adjusted_sum * 100
        } else {
          base::rep(NA_real_, base::length(adjusted_values))
        }
      }
    ) |>
    dplyr::ungroup()

  return(res)
}

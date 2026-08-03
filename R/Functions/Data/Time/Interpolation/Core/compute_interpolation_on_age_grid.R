#' @title Compute Interpolation on an Age Grid
#' @description
#' Computes interpolated values on a regular age grid for one numeric series.
#' @param data_time_series_group
#' A data frame containing one age column and one value column.
#' @param age_variable_name
#' Name of the numeric age column.
#' @param value_variable_name
#' Name of the numeric value column.
#' @param interpolation_method
#' Interpolation method passed to [stats::approx()].
#' @param extrapolation_rule
#' Numeric extrapolation rule passed to [stats::approx()].
#' @param ties_function
#' Function used by [stats::approx()] to combine tied ages.
#' @param age_min
#' Minimum age in the output grid.
#' @param age_max
#' Maximum age in the output grid.
#' @param time_step
#' Positive spacing between consecutive ages in the output grid.
#' @return
#' A tibble containing the interpolated age and value columns.
#' @keywords internal
.compute_interpolation_on_age_grid <- function(
    data_time_series_group,
    age_variable_name,
    value_variable_name,
    interpolation_method,
    extrapolation_rule,
    ties_function,
    age_min,
    age_max,
    time_step) {
  data_interpolated <-
    data_time_series_group |>
    dplyr::select(
      !!rlang::sym(age_variable_name),
      !!rlang::sym(value_variable_name)
    ) |>
    grDevices::xy.coords() |>
    stats::approx(
      xout = base::seq(
        age_min,
        age_max,
        by = time_step
      ),
      ties = ties_function,
      method = interpolation_method,
      rule = extrapolation_rule
    ) |>
    tibble::as_tibble() |>
    dplyr::rename(
      !!rlang::sym(age_variable_name) := x,
      !!rlang::sym(value_variable_name) := y
    )

  base::return(data_interpolated)
}

#' @title Interpolate Data
#' @description
#' Interpolates data over a specified age range and timestep using a method.
#' @param data
#' A data frame containing the data to be interpolated.
#' @param age_var
#' Name of the age variable column (default: "age").
#' @param value_var
#' Name of the value variable column (default: "pollen_prop").
#' @param method
#' Interpolation method to use (default: "linear").
#' @param rule
#' Integer specifying the extrapolation rule (default: 1).
#' @param ties
#' Function to handle tied values (default: `mean`).
#' @param age_min
#' Minimum age for interpolation (default: 0).
#' @param age_max
#' Maximum age for interpolation (default: 12000).
#' @param timestep
#' Timestep for interpolation (default: 500).
#' @return
#' A data frame with interpolated values, including dataset name, taxon, age,
#' and value columns.
#' @details
#' Nests data by dataset and taxon, performs interpolation using `stats::approx`,
#' and returns the interpolated data in a flat format.
#' @export
interpolate_data <- function(
    data,
    age_var = "age",
    value_var = "pollen_prop",
    method = "linear",
    rule = 1,
    ties = mean,
    age_min = 0,
    age_max = 12e03,
    timestep = 500) {
  data %>%
    tidyr::nest(data_nested = !c("dataset_name", "taxon")) %>%
    dplyr::mutate(
      data_interpolated = purrr::map(
        .x = data_nested,
        .f = purrr::possibly(
          .f = ~ .x %>%
            dplyr::select(
              !!rlang::sym(age_var),
              !!rlang::sym(value_var)
            ) %>%
            grDevices::xy.coords() %>%
            stats::approx(
              xout = seq(
                age_min,
                age_max,
                by = timestep
              ),
              ties = ties,
              method = method,
              rule = rule
            ) %>%
            tibble::as_tibble() %>%
            dplyr::rename(
              !!rlang::sym(age_var) := x,
              !!rlang::sym(value_var) := y
            ),
          otherwise = NULL
        )
      )
    ) %>%
    tidyr::unnest(data_interpolated) %>%
    dplyr::select(
      "dataset_name",
      "taxon",
      !!rlang::sym(age_var),
      !!rlang::sym(value_var)
    ) %>%
    return()
}

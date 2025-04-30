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
#' @seealso [stats::approx()]
#' @export
interpolate_data <- function(data = NULL,
                             by = "dataset_name",
                             age_var = "age",
                             value_var = "pollen_prop",
                             method = "linear",
                             rule = 1,
                             ties = mean,
                             age_min = 0,
                             age_max = 12e03,
                             timestep = 500) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    is.character(by) && length(by) > 0,
    msg = "by must be a character vector with at least one element"
  )

  assertthat::assert_that(
    all(by %in% colnames(data)),
    msg = paste0(
      "data must contain the following columns: ",
      paste(by, collapse = ", ")
    )
  )

  assertthat::assert_that(
    is.character(age_var) && length(age_var) == 1,
    msg = "age_var must be a single character string"
  )

  assertthat::assert_that(
    is.character(value_var) && length(value_var) == 1,
    msg = "value_var must be a single character string"
  )

  assertthat::assert_that(
    is.character(method) && length(method) == 1,
    msg = "method must be a single character string"
  )

  assertthat::assert_that(
    is.numeric(rule) && length(rule) == 1,
    msg = "rule must be a single numeric value"
  )

  assertthat::assert_that(
    is.function(ties),
    msg = "ties must be a function"
  )

  assertthat::assert_that(
    is.numeric(age_min) && length(age_min) == 1,
    msg = "age_min must be a single numeric value"
  )

  assertthat::assert_that(
    is.numeric(age_max) && length(age_max) == 1,
    msg = "age_max must be a single numeric value"
  )

  assertthat::assert_that(
    age_min < age_max,
    msg = "age_min must be less than age_max"
  )

  assertthat::assert_that(
    is.numeric(timestep) && length(timestep) == 1,
    msg = "timestep must be a single numeric value"
  )

  assertthat::assert_that(
    timestep > 0,
    msg = "timestep must be greater than 0"
  )

  data %>%
    tidyr::nest(
      data_nested = !dplyr::any_of(by)
    ) %>%
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
      dplyr::any_of(by),
      !!rlang::sym(age_var),
      !!rlang::sym(value_var)
    ) %>%
    return()
}

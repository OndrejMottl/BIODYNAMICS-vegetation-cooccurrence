#' @title Interpolate Community Dataset from Shared Inputs
#' @description
#' Filters shared paleo community preprocessing inputs to one dataset
#' and interpolates that dataset.
#' @param data_interpolation_index
#' A metadata object produced by [make_community_interpolation_index()].
#' It must contain `dataset_name` and `flag_empty` elements.
#' @param data
#' Shared or regular community proportion data with a `dataset_name`
#' column.
#' @param data_age_uncertainty
#' Shared or regular age-uncertainty data with a `dataset_name` column.
#' @param n_cores
#' Number of cores passed to
#' [interpolate_community_data_with_uncertainty()]. Dynamic target
#' branches should use `1L`.
#' @param ...
#' Additional arguments passed to
#' [interpolate_community_data_with_uncertainty()].
#' @return
#' A data frame with columns `dataset_name`, `taxon`, `age`, and
#' `value`.
#' @details
#' The function keeps dynamic branch payloads small by receiving only a
#' dataset identifier and filtering larger shared inputs inside the
#' branch.
#' @examples
#' data_example <- tibble::tibble(
#'   dataset_name = "core_a",
#'   sample_name = "sample_a",
#'   taxon = "Taxon",
#'   age = 0,
#'   value = 1
#' )
#' data_uncertainty <- tibble::tibble(
#'   dataset_name = base::character(),
#'   sample_name = base::character(),
#'   iteration = base::integer(),
#'   age_uncertainty = base::numeric()
#' )
#' index <- base::list(dataset_name = "core_a", flag_empty = FALSE)
#' interpolate_community_dataset_from_shared_inputs(
#'   data_interpolation_index = index,
#'   data = data_example,
#'   data_age_uncertainty = data_uncertainty,
#'   age_min = 0,
#'   age_max = 500,
#'   timestep = 500
#' )
#' @seealso
#'   [make_community_interpolation_index()],
#'   [interpolate_community_data_with_uncertainty()]
#' @export
interpolate_community_dataset_from_shared_inputs <- function(
    data_interpolation_index,
    data,
    data_age_uncertainty,
    n_cores = 1L,
    ...) {
  assertthat::assert_that(
    base::is.list(data_interpolation_index),
    msg = "'data_interpolation_index' must be a list"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "flag_empty") %in%
        base::names(data_interpolation_index)
    ),
    msg = stringr::str_c(
      "'data_interpolation_index' must contain 'dataset_name'",
      "and 'flag_empty' elements.",
      sep = " "
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data),
    msg = "'data' must contain a 'dataset_name' column"
  )

  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty),
    msg = "'data_age_uncertainty' must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_age_uncertainty),
    msg = stringr::str_c(
      "'data_age_uncertainty' must contain a 'dataset_name'",
      "column.",
      sep = " "
    )
  )

  assertthat::assert_that(
    base::is.numeric(n_cores) &&
      base::length(n_cores) == 1L &&
      base::is.finite(n_cores) &&
      n_cores >= 1L &&
      n_cores == base::as.integer(n_cores),
    msg = "'n_cores' must be a single positive integer"
  )

  flag_empty <-
    purrr::chuck(data_interpolation_index, "flag_empty")

  assertthat::assert_that(
    assertthat::is.flag(flag_empty),
    msg = "'flag_empty' must be a single logical value"
  )

  data_selected <-
    data |>
    dplyr::slice(0L)

  data_age_uncertainty_selected <-
    data_age_uncertainty |>
    dplyr::slice(0L)

  if (
    !isTRUE(flag_empty)
  ) {
    dataset_name <-
      purrr::chuck(data_interpolation_index, "dataset_name")

    assertthat::assert_that(
      base::is.character(dataset_name) &&
        base::length(dataset_name) == 1L &&
        !base::is.na(dataset_name),
      msg = "'dataset_name' must be a single non-missing string"
    )

    data_selected <-
      data |>
      dplyr::filter(dataset_name == .env$dataset_name)

    data_age_uncertainty_selected <-
      data_age_uncertainty |>
      dplyr::filter(dataset_name == .env$dataset_name)
  }

  res_interpolated <-
    interpolate_community_data_with_uncertainty(
      data = data_selected,
      data_age_uncertainty = data_age_uncertainty_selected,
      n_cores = n_cores,
      ...
    )

  base::return(res_interpolated)
}

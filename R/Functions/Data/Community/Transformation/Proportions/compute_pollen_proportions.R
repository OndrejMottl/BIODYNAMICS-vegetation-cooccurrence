#' @title Compute Pollen Proportions
#' @description
#' Computes row-level pollen proportions from supplied sample totals.
#' @param data_community
#' A data frame containing `sample_name` and `pollen_count` columns.
#' @param data_pollen_sums
#' A data frame containing `sample_name` and `pollen_sum` columns.
#' @return
#' A data frame with pollen proportions, excluding `pollen_sum` and
#' `pollen_count` columns.
#' @details
#' Joins the input data with total pollen counts and stores the calculated
#' proportion in `value`.
#' @export
compute_pollen_proportions <- function(
    data_community = NULL,
    data_pollen_sums = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame."
  )
  assertthat::assert_that(
    base::is.data.frame(data_pollen_sums),
    msg = "data_pollen_sums must be a data frame."
  )
  assertthat::assert_that(
    base::all(
      base::c("sample_name", "pollen_count") %in%
        base::names(data_community)
    ),
    msg = stringr::str_c(
      "data_community must contain 'sample_name' and 'pollen_count' columns."
    )
  )
  assertthat::assert_that(
    base::all(
      base::c("sample_name", "pollen_sum") %in%
        base::names(data_pollen_sums)
    ),
    msg = stringr::str_c(
      "data_pollen_sums must contain 'sample_name' and 'pollen_sum' columns."
    )
  )

  res_pollen_proportions <-
    data_community |>
    dplyr::left_join(
      data_pollen_sums,
      by = "sample_name"
    ) |>
    dplyr::mutate(
      value = pollen_count / pollen_sum,
      .after = pollen_count
    ) |>
    dplyr::select(
      -dplyr::all_of(
        base::c("pollen_sum", "pollen_count")
      )
    )

  return(res_pollen_proportions)
}

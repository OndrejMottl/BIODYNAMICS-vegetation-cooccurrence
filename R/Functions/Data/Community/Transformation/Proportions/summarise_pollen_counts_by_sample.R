#' @title Summarise Pollen Counts by Sample
#' @description
#' Summarises the total pollen count for each sample.
#' @param data_community
#' A data frame containing `sample_name` and `pollen_count` columns.
#' @return
#' A data frame with two columns: `sample_name` and `pollen_sum`,
#' where `pollen_sum` is the total pollen count for each sample.
#' @details
#' Missing values in `pollen_count` are ignored.
#' @export
summarise_pollen_counts_by_sample <- function(data_community = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame."
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
    base::is.numeric(data_community[["pollen_count"]]),
    msg = "data_community[['pollen_count']] must be numeric."
  )

  res_pollen_sums <-
    data_community |>
    dplyr::group_by(sample_name) |>
    dplyr::summarise(
      pollen_sum = base::sum(pollen_count, na.rm = TRUE),
      .groups = "drop"
    )

  return(res_pollen_sums)
}

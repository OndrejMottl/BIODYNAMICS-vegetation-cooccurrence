#' @title Extract Community Records
#' @description
#' Extracts nested community records from an in-memory VegVault result.
#' @param data_vegvault
#' A data frame containing the columns `dataset_name` and `data_community`.
#' @return
#' A data frame containing `dataset_name` and the unnested community-record
#' columns.
#' @details
#' This function extracts an in-memory component. It does not load data from
#' persistent storage.
#' @examples
#' data_vegvault <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     data_community = base::list(
#'       tibble::tibble(sample_name = "sample_1", Pinus = 10)
#'     )
#'   )
#'
#' extract_community_records(data_vegvault = data_vegvault)
#' @export
extract_community_records <- function(data_vegvault = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_vegvault),
    msg = "data_vegvault must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "data_community") %in%
        base::colnames(data_vegvault)
    ),
    msg = stringr::str_c(
      "data_vegvault must contain columns",
      " ",
      "'dataset_name' and 'data_community'"
    )
  )

  res_community_records <-
    data_vegvault |>
    dplyr::select(
      dataset_name,
      data_community
    ) |>
    tidyr::unnest(data_community)

  return(res_community_records)
}

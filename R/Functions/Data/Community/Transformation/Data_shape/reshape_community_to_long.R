#' @title Reshape Community Data to Long Format
#' @description
#' Reshapes wide community counts to one taxon observation per row.
#' @param data_community
#' A wide data frame containing `dataset_name`, `sample_name`, and at least one
#' taxon-count column.
#' @return
#' A data frame in long format with columns `dataset_name`, `sample_name`,
#' `taxon`, and `pollen_count`.
#' @details
#' Missing taxon counts are omitted from the returned long data.
#' @examples
#' data_community <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     sample_name = "sample_1",
#'     Pinus = 10,
#'     Betula = 5
#'   )
#'
#' reshape_community_to_long(data_community = data_community)
#' @export
reshape_community_to_long <- function(data_community = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "sample_name") %in%
        base::colnames(data_community)
    ),
    msg = stringr::str_c(
      "data_community must contain columns",
      " ",
      "'dataset_name' and 'sample_name'"
    )
  )

  assertthat::assert_that(
    base::ncol(data_community) > 2L,
    msg = "data_community must contain at least one taxon column"
  )

  res_community_long <-
    data_community |>
    tidyr::pivot_longer(
      cols = !c("dataset_name", "sample_name"),
      names_to = "taxon",
      values_to = "pollen_count",
      values_drop_na = TRUE
    )

  return(res_community_long)
}

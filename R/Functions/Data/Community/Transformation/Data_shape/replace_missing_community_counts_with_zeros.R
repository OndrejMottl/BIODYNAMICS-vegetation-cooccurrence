#' @title Replace Missing Community Counts with Zeros
#' @description
#' Replaces missing values in wide taxon-count columns with zeros.
#' @param data_community
#' A wide data frame containing `dataset_name`, `sample_name`, and at least one
#' taxon-count column.
#' @return
#' The input data frame with missing taxon counts replaced by zeros.
#' @details
#' Identifier columns are preserved without modification. Taxon columns must
#' be numeric because zero represents an observed absence.
#' @examples
#' data_community <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     sample_name = "sample_1",
#'     Pinus = NA_real_
#'   )
#'
#' replace_missing_community_counts_with_zeros(
#'   data_community = data_community
#' )
#' @export
replace_missing_community_counts_with_zeros <- function(
    data_community = NULL) {
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

  vec_identifier_columns <-
    base::c("dataset_name", "sample_name")

  vec_taxon_columns <-
    base::setdiff(
      base::colnames(data_community),
      vec_identifier_columns
    )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        data_community[vec_taxon_columns],
        base::is.numeric
      )
    ),
    msg = "all taxon columns in data_community must be numeric"
  )

  res_community_complete <-
    data_community |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(vec_taxon_columns),
        ~ tidyr::replace_na(.x, 0)
      )
    )

  return(res_community_complete)
}

#' @title Join Sample Ages
#' @description
#' Joins sample ages to records using dataset and sample identifiers.
#' @param data_records
#' A data frame containing `dataset_name` and `sample_name`.
#' @param data_sample_ages
#' A data frame containing `dataset_name`, `sample_name`, and `age`.
#' @return
#' `data_records` with the matching `age` column joined.
#' @details
#' The age table must have at most one row per dataset-sample key. Unmatched
#' records are retained with a missing age.
#' @examples
#' data_records <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     sample_name = "sample_1",
#'     value = 10
#'   )
#' data_sample_ages <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     sample_name = "sample_1",
#'     age = 100
#'   )
#'
#' join_sample_ages(
#'   data_records = data_records,
#'   data_sample_ages = data_sample_ages
#' )
#' @export
join_sample_ages <- function(
    data_records = NULL,
    data_sample_ages = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_records),
    msg = "data_records must be a data frame"
  )

  assertthat::assert_that(
    base::is.data.frame(data_sample_ages),
    msg = "data_sample_ages must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "sample_name") %in%
        base::colnames(data_records)
    ),
    msg = stringr::str_c(
      "data_records must contain columns ",
      "`dataset_name` and `sample_name`"
    )
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "sample_name", "age") %in%
        base::colnames(data_sample_ages)
    ),
    msg = stringr::str_c(
      "data_sample_ages must contain columns ",
      "`dataset_name`, `sample_name`, and `age`"
    )
  )

  res_records_with_ages <-
    dplyr::left_join(
      x = data_records,
      y = data_sample_ages,
      by = base::c("dataset_name", "sample_name"),
      relationship = "many-to-one"
    )

  return(res_records_with_ages)
}

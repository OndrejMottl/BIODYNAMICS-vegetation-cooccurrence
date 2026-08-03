#' @title Extract Sample Ages
#' @description
#' Extracts sample ages from an in-memory VegVault result.
#' @param data_vegvault
#' A data frame containing `dataset_name` and nested `data_samples` columns.
#' @return
#' A data frame with columns `dataset_name`, `sample_name`, and `age`.
#' @details
#' This function extracts an in-memory component. It does not load data from
#' persistent storage.
#' @examples
#' data_vegvault <-
#'   tibble::tibble(
#'     dataset_name = "example",
#'     data_samples = base::list(
#'       tibble::tibble(sample_name = "sample_1", age = 100)
#'     )
#'   )
#'
#' extract_sample_ages(data_vegvault = data_vegvault)
#' @export
extract_sample_ages <- function(data_vegvault = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_vegvault),
    msg = "data_vegvault must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "data_samples") %in%
        base::colnames(data_vegvault)
    ),
    msg = stringr::str_c(
      "data_vegvault must contain columns ",
      "`dataset_name` and `data_samples`"
    )
  )

  res_sample_ages <-
    data_vegvault |>
    dplyr::select(
      dataset_name,
      data_samples
    ) |>
    tidyr::unnest(data_samples) |>
    dplyr::select(
      "dataset_name",
      "sample_name",
      "age"
    )

  return(res_sample_ages)
}

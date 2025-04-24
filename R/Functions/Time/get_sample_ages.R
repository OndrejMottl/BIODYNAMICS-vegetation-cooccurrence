#' @title Get Sample Ages
#' @description
#' Extracts sample ages from a data frame containing dataset and sample info.
#' @param data
#' A data frame. Must contain the columns `dataset_name` and `data_samples`.
#' @return
#' A data frame with columns `dataset_name`, `sample_name`, and `age`.
#' @details
#' Validates the input data frame, ensures required columns are present, and
#' extracts sample ages by unnesting the `data_samples` column.
#' @export
get_sample_ages <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "data_samples") %in% colnames(data)),
    msg = "data must contain columns 'dataset_name' and 'data_samples'"
  )

  data %>%
    dplyr::select(dataset_name, data_samples) %>%
    tidyr::unnest(data_samples) %>%
    dplyr::select(
      "dataset_name",
      "sample_name",
      "age"
    ) %>%
    return()
}

#' @title Classify Dataset Prefix
#' @description
#' Classifies dataset names into `bien`, `splot`, or `other` groups.
#' @param data_source
#' A character vector of dataset names.
#' @return
#' A character vector with values `bien`, `splot`, or `other`.
#' @export
classify_dataset_prefix <- function(data_source = NULL) {
  assertthat::assert_that(
    base::is.character(data_source),
    msg = "data_source must be a character vector."
  )

  assertthat::assert_that(
    !base::any(base::is.na(data_source)),
    msg = "data_source must not contain NA values."
  )

  res <-
    dplyr::case_when(
      stringr::str_detect(data_source, "^bien_") ~ "bien",
      stringr::str_detect(data_source, "^splot_") ~ "splot",
      TRUE ~ "other"
    )

  return(res)
}

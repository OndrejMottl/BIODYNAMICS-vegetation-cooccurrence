#' @title Classify Dataset Prefix
#' @description
#' Classifies dataset names into `bien`, `splot`, or `other` groups.
#' @param vec_dataset_names
#' A character vector of dataset names.
#' @return
#' A character vector with values `bien`, `splot`, or `other`.
#' @export
classify_dataset_prefix <- function(vec_dataset_names = NULL) {
  assertthat::assert_that(
    base::is.character(vec_dataset_names),
    msg = "vec_dataset_names must be a character vector."
  )

  assertthat::assert_that(
    !base::any(base::is.na(vec_dataset_names)),
    msg = "vec_dataset_names must not contain NA values."
  )

  res_dataset_prefixes <-
    dplyr::case_when(
      stringr::str_detect(vec_dataset_names, "^bien_") ~ "bien",
      stringr::str_detect(vec_dataset_names, "^splot_") ~ "splot",
      TRUE ~ "other"
    )

  return(res_dataset_prefixes)
}

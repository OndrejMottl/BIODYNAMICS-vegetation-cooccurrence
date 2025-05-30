#' @title Prepare Data for Model Fitting
#' @description
#' Prepares community or abiotic data for model fitting by reshaping it into
#' a wide format with appropriate column names.
#' @param data
#' A data frame containing the input data. For `type = "community"`, it must
#' include columns `dataset_name`, `age`, `taxon`, and `pollen_prop`. For
#' `type = "abiotic"`, it must include columns `dataset_name`, `age`,
#' `abiotic_variable_name`, and `abiotic_value`.
#' @param type
#' A character string specifying the type of data to prepare. Must be either
#' "community" or "abiotic" (default: "community").
#' @return
#' A data frame in wide format, with `sample_name` as row names and either
#' taxa or abiotic variable names as columns. For community data, missing
#' values are filled with 0. For abiotic data, missing values are left as NA.
#' @details
#' The function validates the input data and reshapes it based on the
#' specified `type`. For community data, it combines `dataset_name` and `age`
#' into a `sample_name` column, selects relevant columns, and pivots the data
#' to a wide format. For abiotic data, it performs similar steps but uses
#' abiotic variable names and values.
#' @export
prepare_data_for_fit <- function(data = NULL, type = c("community", "abiotic")) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  type <- match.arg(type)

  assertthat::assert_that(
    type %in% c("community", "abiotic"),
    msg = "type must be either 'community' or 'abiotic'"
  )

  res <-
    switch(type,
      "community" = data %>%
        dplyr::mutate(
          sample_name = paste0(dataset_name, "__", age),
        ) %>%
        dplyr::select("sample_name", "taxon", "pollen_prop") %>%
        tidyr::pivot_wider(
          names_from = "taxon",
          values_from = "pollen_prop",
          values_fill = 0
        ) %>%
        tibble::column_to_rownames("sample_name"),
      "abiotic" = data %>%
        dplyr::mutate(
          sample_name = paste0(dataset_name, "__", age),
        ) %>%
        dplyr::select(
          "sample_name", "abiotic_variable_name", "abiotic_value"
        ) %>%
        tidyr::pivot_wider(
          names_from = "abiotic_variable_name",
          values_from = "abiotic_value",
          values_fill = NULL
        ) %>%
        tibble::column_to_rownames("sample_name")
    )

    return(res)
}

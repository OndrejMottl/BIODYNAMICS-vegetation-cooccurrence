#' @title Prepare Abiotic Data for Model Fitting
#' @description
#' Reshapes long-format abiotic data into a wide data frame
#' suitable for downstream scaling, filtering to the canonical
#' sample index supplied by `align_sample_ids()`.
#' @param data_abiotic_long
#' A data frame in long format with columns `dataset_name`, `age`,
#' `abiotic_variable_name`, and `abiotic_value`.
#' @param data_sample_ids
#' A data frame of valid `(dataset_name, age)` pairs as returned by
#' `align_sample_ids()`.
#' @return
#' A data frame in wide format with real columns `dataset_name`,
#' `age`, and one column per abiotic variable. Rows are ordered by
#' `dataset_name` then `age`, matching the order in
#' `data_sample_ids`. Missing variable–sample combinations are
#' left as `NA`. The `age` column is preserved as a plain numeric
#' column (not encoded in row names) to simplify downstream
#' scaling.
#' @details
#' Unlike the former `prepare_data_for_fit(type = "abiotic")`, this
#' function retains `dataset_name` and `age` as real columns so
#' that `scale_abiotic_for_fit()` can operate on them without
#' parsing row names. Row names are added by
#' `scale_abiotic_for_fit()` as part of the scaling step.
#' @seealso [align_sample_ids()], [scale_abiotic_for_fit()],
#'   [assemble_data_to_fit()]
#' @export
prepare_abiotic_for_fit <- function(
    data_abiotic_long = NULL,
    data_sample_ids = NULL) {
  assertthat::assert_that(
    is.data.frame(data_abiotic_long),
    msg = "data_abiotic_long must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(
      c(
        "dataset_name", "age",
        "abiotic_variable_name", "abiotic_value"
      ) %in% names(data_abiotic_long)
    ),
    msg = paste0(
      "data_abiotic_long must contain columns 'dataset_name',",
      " 'age', 'abiotic_variable_name', 'abiotic_value'"
    )
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_sample_ids)),
    msg = paste0(
      "data_sample_ids must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  res <-
    data_abiotic_long |>
    dplyr::inner_join(
      data_sample_ids,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::select(
      dataset_name,
      age,
      abiotic_variable_name,
      abiotic_value
    ) |>
    tidyr::pivot_wider(
      names_from = "abiotic_variable_name",
      values_from = "abiotic_value",
      values_fill = NULL
    )

  return(res)
}

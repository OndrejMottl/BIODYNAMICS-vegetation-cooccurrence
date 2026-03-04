#' @title Prepare Community Data for Model Fitting
#' @description
#' Reshapes long-format community data into a wide matrix suitable
#' for model fitting, filtering to the canonical sample index
#' supplied by `align_sample_ids()`.
#' @param data_community_long
#' A data frame in long format with columns `dataset_name`, `age`,
#' `taxon`, and `pollen_prop`.
#' @param data_sample_ids
#' A data frame of valid `(dataset_name, age)` pairs as returned by
#' `align_sample_ids()`.
#' @return
#' A numeric matrix with row names in the format
#' `"<dataset_name>__<age>"` and taxon names as column names.
#' Missing taxon–sample combinations are filled with `0`. Rows are
#' ordered by `dataset_name` then `age`, matching the order in
#' `data_sample_ids`.
#' @details
#' Only samples present in `data_sample_ids` are retained. Rows
#' with `NA` or zero `pollen_prop` are dropped before pivoting.
#' The function widens the data and converts the result to a matrix
#' directly, so the output is ready for `filter_constant_taxa()`
#' and `assemble_data_to_fit()`.
#' @seealso [align_sample_ids()], [filter_constant_taxa()],
#'   [assemble_data_to_fit()]
#' @export
prepare_community_for_fit <- function(
    data_community_long = NULL,
    data_sample_ids = NULL) {
  assertthat::assert_that(
    is.data.frame(data_community_long),
    msg = "data_community_long must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("dataset_name", "age", "taxon", "pollen_prop") %in%
        names(data_community_long)
    ),
    msg = paste0(
      "data_community_long must contain columns",
      " 'dataset_name', 'age', 'taxon', 'pollen_prop'"
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
    data_community_long |>
    dplyr::inner_join(
      data_sample_ids,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    tidyr::drop_na(pollen_prop) |>
    dplyr::filter(pollen_prop > 0) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::mutate(
      sample_name = paste0(dataset_name, "__", age)
    ) |>
    dplyr::select(sample_name, taxon, pollen_prop) |>
    tidyr::pivot_wider(
      names_from = "taxon",
      values_from = "pollen_prop",
      values_fill = 0
    ) |>
    tibble::column_to_rownames("sample_name") |>
    as.matrix()

  return(res)
}

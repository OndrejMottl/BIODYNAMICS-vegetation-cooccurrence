#' @title Prepare Spatial Predictors for Model Fitting
#' @description
#' Expands dataset-level spatial predictor data to the sample
#' level by joining against the canonical `(dataset_name, age)`
#' sample index, producing a data frame whose rows align with the
#' community matrix and abiotic data used for model fitting.
#' @param data_spatial
#' A data frame with `dataset_name` as row names and one or more
#' spatial predictor columns (e.g. `coord_x_km`, `coord_y_km`
#' from `project_coords_to_metric()`).
#' @param data_sample_ids
#' A data frame of valid `(dataset_name, age)` pairs as returned
#' by `align_sample_ids()`.
#' @return
#' A data frame with row names in the format
#' `"<dataset_name>__<age>"` and the same predictor columns as
#' `data_spatial`. Rows are sorted by `dataset_name` then `age`,
#' matching the ordering of the community matrix and abiotic data
#' produced by the respective preparation functions. Rows with
#' any `NA` in the spatial predictors are dropped.
#' @details
#' Spatial predictors are stored at the dataset level (one row
#' per site) but models require one row per sample
#' (site × time-slice). This function replicates each dataset's
#' spatial values across all its valid sample ages. The row-name
#' format `"<dataset_name>__<age>"` matches that of the community
#' matrix and abiotic data frame. Unlike `prepare_coords_for_fit`,
#' this function is generic and imposes no assumptions on which
#' spatial predictor columns are present.
#' @seealso
#'   [project_coords_to_metric()], [align_sample_ids()],
#'   [assemble_data_to_fit()], [prepare_coords_for_fit()]
#' @export
prepare_spatial_predictors_for_fit <- function(
    data_spatial = NULL,
    data_sample_ids = NULL) {
  assertthat::assert_that(
    is.data.frame(data_spatial),
    msg = "data_spatial must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_sample_ids)),
    msg = paste0(
      "data_sample_ids must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  assertthat::assert_that(
    nrow(data_spatial) > 0,
    msg = "data_spatial must have at least one row"
  )

  assertthat::assert_that(
    ncol(data_spatial) > 0,
    msg = "data_spatial must have at least one column"
  )

  res <-
    data_sample_ids |>
    dplyr::inner_join(
      data_spatial |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by(dataset_name)
    ) |>
    tidyr::drop_na() |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::mutate(
      .row_name = paste0(dataset_name, "__", age)
    ) |>
    dplyr::select(-dataset_name, -age) |>
    tibble::column_to_rownames(".row_name")

  return(res)
}

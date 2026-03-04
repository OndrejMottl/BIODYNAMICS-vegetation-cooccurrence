#' @title Prepare Coordinate Data for Model Fitting
#' @description
#' Expands dataset-level coordinate data to the sample level by
#' joining against the canonical `(dataset_name, age)` sample
#' index, producing a data frame whose rows align with the
#' community matrix and abiotic data used for model fitting.
#' @param data_coords
#' A data frame with `dataset_name` as row names and columns
#' `coord_long` and `coord_lat`.
#' @param data_sample_ids
#' A data frame of valid `(dataset_name, age)` pairs as returned by
#' `align_sample_ids()`.
#' @return
#' A data frame with row names in the format
#' `"<dataset_name>__<age>"` and columns `coord_long` and
#' `coord_lat`. Rows are sorted by `dataset_name` then `age`,
#' matching the ordering of `data_sample_ids`.
#' @details
#' Coordinates are stored at dataset level but models require one
#' row per sample. This function replicates each dataset's
#' coordinates across all its valid sample ages. The row-name
#' format matches that of the community matrix and abiotic data
#' frame produced by the respective preparation functions.
#' @seealso [align_sample_ids()], [assemble_data_to_fit()]
#' @export
prepare_coords_for_fit <- function(
    data_coords = NULL,
    data_sample_ids = NULL) {
  assertthat::assert_that(
    is.data.frame(data_coords),
    msg = "data_coords must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("coord_long", "coord_lat") %in% names(data_coords)
    ),
    msg = paste0(
      "data_coords must contain columns",
      " 'coord_long' and 'coord_lat'"
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
    data_sample_ids |>
    dplyr::inner_join(
      data_coords |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by(dataset_name)
    ) |>
    tidyr::drop_na(coord_long, coord_lat) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::mutate(
      .row_name = paste0(dataset_name, "__", age)
    ) |>
    dplyr::select(-dataset_name, -age) |>
    tibble::column_to_rownames(".row_name")

  return(res)
}

#' @title Get Dataset Coordinates
#' @description
#' Extracts unique coordinates for each dataset, excluding gridpoints.
#' @param data
#' A data frame containing columns 'dataset_name', 'dataset_type',
#' 'coord_long', and 'coord_lat'. Rows with `dataset_type == "gridpoints"`
#' are excluded.
#' @return
#' A data frame with unique coordinates for each dataset, with
#' `dataset_name` as row names.
#' @export
get_coords <- function(data) {
  data %>%
    dplyr::filter(
      dataset_type != "gridpoints"
    ) %>%
    dplyr::select(
      "dataset_name",
      "coord_long",
      "coord_lat"
    ) %>%
    dplyr::distinct() %>%
    tibble::column_to_rownames("dataset_name") %>%
    return()
}

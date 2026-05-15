#' @title Detect Duplicate Modern Sites
#' @description
#' Detects modern datasets that share the same geographic coordinates.
#' @param data_source
#' A data frame with `coord_long` and `coord_lat` columns. Dataset names may
#' be stored either in a `dataset_name` column or in row names.
#' @return
#' A tibble with one row per dataset involved in a duplicated coordinate
#' group. Returns a zero-row tibble when no duplicate sites are detected.
#' @export
detect_duplicate_sites <- function(data_source = NULL) {
  data_coordinates <-
    normalize_coordinates(data_source = data_source)

  res <-
    data_coordinates |>
    dplyr::group_by(coord_long, coord_lat) |>
    dplyr::mutate(
      n_sites = dplyr::n(),
      duplicate_site_group = dplyr::cur_group_id()
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(n_sites > 1L) |>
    dplyr::arrange(coord_long, coord_lat, dataset_name) |>
    dplyr::select(
      duplicate_site_group,
      dataset_name,
      coord_long,
      coord_lat,
      n_sites
    )

  return(res)
}

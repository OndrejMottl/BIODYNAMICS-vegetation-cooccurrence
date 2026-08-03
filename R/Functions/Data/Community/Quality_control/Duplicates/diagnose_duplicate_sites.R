#' @title Diagnose Duplicate Modern Sites
#' @description
#' Returns modern datasets that share the same geographic coordinates.
#' @param data_coordinates
#' A data frame with `coord_long` and `coord_lat` columns. Dataset names may
#' be stored either in a `dataset_name` column or in row names.
#' @return
#' A tibble with one row per dataset involved in a duplicated coordinate
#' group. Returns a zero-row tibble when no duplicate sites are detected.
#' @export
diagnose_duplicate_sites <- function(data_coordinates = NULL) {
  data_coordinates_normalised <-
    normalise_coordinates(data_coordinates = data_coordinates)

  res_duplicate_sites <-
    data_coordinates_normalised |>
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

  return(res_duplicate_sites)
}

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
    return()
}

#' @title Build a Land Prediction Grid
#' @description
#' Creates a regular longitude-latitude prediction grid for one spatial
#' unit, masks it to land, and projects coordinates to a metric CRS.
#' @param scale_id
#' Character scalar identifying a spatial unit in `path_spatial_grid`.
#' @param grid_resolution
#' Numeric scalar grid resolution in decimal degrees.
#' @param target_crs
#' Integer EPSG code used by [project_coords_to_metric()].
#' @param path_spatial_grid
#' Path to the spatial grid CSV catalogue.
#' @param land_polygons
#' Optional `sf` polygon object used as the land mask. If `NULL`, Natural
#' Earth country polygons are loaded with `rnaturalearth`.
#' @return
#' Named list with `data_grid`, `data_grid_coords_projected`, `x_lim`,
#' and `y_lim`.
#' @examples
#' \dontrun{
#' build_land_prediction_grid(
#'   scale_id = "europe",
#'   grid_resolution = 0.5,
#'   target_crs = 3035L
#' )
#' }
#' @export
build_land_prediction_grid <- function(
    scale_id,
    grid_resolution,
    target_crs = 3035L,
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv"),
    land_polygons = NULL) {
  assertthat::assert_that(
    base::is.character(scale_id) &&
      base::length(scale_id) == 1L &&
      base::nchar(scale_id) > 0L,
    msg = "`scale_id` must be a single non-empty string."
  )

  assertthat::assert_that(
    base::is.numeric(grid_resolution) &&
      base::length(grid_resolution) == 1L &&
      base::is.finite(grid_resolution) &&
      grid_resolution > 0,
    msg = "`grid_resolution` must be a single positive number."
  )

  list_window <-
    get_spatial_window(
      scale_id = scale_id,
      file = path_spatial_grid
    )

  x_lim <-
    list_window[["x_lim"]]

  y_lim <-
    list_window[["y_lim"]]

  data_grid_base <-
    tidyr::expand_grid(
      coord_long = base::seq(
        from = base::min(x_lim),
        to = base::max(x_lim),
        by = grid_resolution
      ),
      coord_lat = base::seq(
        from = base::min(y_lim),
        to = base::max(y_lim),
        by = grid_resolution
      )
    ) |>
    dplyr::mutate(grid_id = dplyr::row_number()) |>
    dplyr::select(
      "grid_id",
      "coord_long",
      "coord_lat"
    )

  if (
    base::is.null(land_polygons)
  ) {
    land_polygons <-
      rnaturalearth::ne_countries(
        scale = "medium",
        returnclass = "sf"
      )
  }

  data_grid_land <-
    data_grid_base |>
    sf::st_as_sf(
      coords = c("coord_long", "coord_lat"),
      crs = 4326L,
      remove = FALSE
    ) |>
    sf::st_filter(
      y = land_polygons,
      .predicate = sf::st_intersects
    ) |>
    sf::st_drop_geometry() |>
    tibble::as_tibble()

  assertthat::assert_that(
    base::nrow(data_grid_land) > 0L,
    msg = "The land-masked prediction grid has no cells."
  )

  data_grid_coords_projected <-
    data_grid_land |>
    dplyr::mutate(
      dataset_name = stringr::str_glue("grid_{.data$grid_id}")
    ) |>
    dplyr::select(
      "dataset_name",
      "coord_long",
      "coord_lat"
    ) |>
    tibble::column_to_rownames("dataset_name") |>
    project_coords_to_metric(target_crs = target_crs)

  res_grid <-
    base::list(
      data_grid = data_grid_land,
      data_grid_coords_projected = data_grid_coords_projected,
      x_lim = x_lim,
      y_lim = y_lim
    )

  return(res_grid)
}

#' @title Resolve the Projection for Spatial Predictors
#' @description
#' Chooses the coordinate reference system used to project a model unit's
#' coordinates, from the unit's continent and the per-continent projection
#' map.
#' @param scale_id
#' Optional spatial-unit identifier from the spatial grid catalogue, as
#' returned by [resolve_scale_id_from_store()]. `NULL` for stores that are not
#' spatial units, such as temporal stores.
#' @param continent_id
#' Optional continent identifier from the profile (`continent_id`), used when
#' there is no `scale_id`.
#' @param crs_by_continent
#' Named list mapping continent identifiers to an EPSG integer or a CRS
#' string accepted by [project_coords_to_metric()]
#' (`spatial_crs_by_continent` in the configuration).
#' @param file_spatial_grid
#' Path to the spatial grid catalogue.
#' @return
#' The projection for the unit's continent: an integer EPSG code or one CRS
#' string.
#' @details
#' A `scale_id` is mapped to its continent with
#' [resolve_continent_ids_from_scale_ids()]. When both a `scale_id` and a
#' `continent_id` are given they must agree. The function aborts when no
#' continent can be determined or the continent has no projection, so a
#' missing entry never falls back to the European projection (issue #204).
#' @seealso [project_coords_to_metric()]
#' @examples
#' resolve_spatial_crs(
#'   continent_id = "europe",
#'   crs_by_continent = list(europe = 3035L)
#' )
#' @export
resolve_spatial_crs <- function(
    scale_id = NULL,
    continent_id = NULL,
    crs_by_continent,
    file_spatial_grid = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    base::is.null(scale_id) || assertthat::is.string(scale_id),
    base::is.null(continent_id) || assertthat::is.string(continent_id),
    msg = "`scale_id` and `continent_id` must be NULL or one string."
  )
  assertthat::assert_that(
    base::is.list(crs_by_continent),
    base::length(crs_by_continent) > 0L,
    !base::is.null(base::names(crs_by_continent)),
    msg = "`crs_by_continent` must be a named list of projections."
  )

  continent_id_from_scale <-
    if (
      base::is.null(scale_id)
    ) {
      NULL
    } else {
      resolve_continent_ids_from_scale_ids(
        scale_id = scale_id,
        file = file_spatial_grid
      )
    }

  if (
    !base::is.null(continent_id_from_scale) &&
      !base::is.null(continent_id) &&
      !base::identical(continent_id_from_scale, continent_id)
  ) {
    cli::cli_abort(
      base::c(
        "The unit's continent and the profile's continent differ.",
        "x" = "{.val {scale_id}} is in {.val {continent_id_from_scale}}.",
        "x" = "The profile sets {.val {continent_id}}."
      ),
      class = "spatial_crs_continent_conflict"
    )
  }

  continent_id_resolved <-
    if (
      base::is.null(continent_id_from_scale)
    ) {
      continent_id
    } else {
      continent_id_from_scale
    }

  if (
    base::is.null(continent_id_resolved)
  ) {
    cli::cli_abort(
      base::c(
        "Cannot choose a projection without a continent.",
        "i" = stringr::str_c(
          "Run a spatial-unit store or set `continent_id` in the profile."
        )
      ),
      class = "spatial_crs_continent_missing"
    )
  }

  if (
    !continent_id_resolved %in% base::names(crs_by_continent)
  ) {
    cli::cli_abort(
      base::c(
        "No projection is configured for {.val {continent_id_resolved}}.",
        "i" = "Add it to `spatial_crs_by_continent`."
      ),
      class = "spatial_crs_projection_missing"
    )
  }

  res <-
    crs_by_continent[[continent_id_resolved]]

  return(res)
}

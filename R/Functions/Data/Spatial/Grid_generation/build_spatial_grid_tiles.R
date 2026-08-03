#' @title Build Spatial Grid Tiles
#' @description
#' Builds clipped regular grid tiles for one parent spatial unit.
#' @param parent_scale_id
#' A non-empty character scalar identifying the parent spatial unit.
#' @param x_minimum_parent,x_maximum_parent
#' Finite numeric scalars giving the horizontal parent bounds.
#' @param y_minimum_parent,y_maximum_parent
#' Finite numeric scalars giving the vertical parent bounds.
#' @param tile_size_degrees
#' A positive finite numeric scalar giving the square tile size in degrees.
#' @param scale_name
#' A non-empty character scalar naming the output spatial scale.
#' @param scale_id_prefix
#' A non-empty character scalar prepended to sequential tile identifiers.
#' @return
#' A tibble with one row per non-empty clipped tile and the columns `scale_id`,
#' `scale`, `parent_id`, `x_min`, `x_max`, `y_min`, and `y_max`.
#' @examples
#' build_spatial_grid_tiles(
#'   parent_scale_id = "europe",
#'   x_minimum_parent = -10,
#'   x_maximum_parent = 40,
#'   y_minimum_parent = 35,
#'   y_maximum_parent = 70,
#'   tile_size_degrees = 20,
#'   scale_name = "regional",
#'   scale_id_prefix = "eu_r"
#' )
#' @export
build_spatial_grid_tiles <- function(
    parent_scale_id = NULL,
    x_minimum_parent = NULL,
    x_maximum_parent = NULL,
    y_minimum_parent = NULL,
    y_maximum_parent = NULL,
    tile_size_degrees = NULL,
    scale_name = NULL,
    scale_id_prefix = NULL) {
  assertthat::assert_that(
    base::is.character(parent_scale_id),
    base::length(parent_scale_id) == 1L,
    base::nzchar(parent_scale_id),
    msg = "`parent_scale_id` must be one non-empty character value."
  )
  assertthat::assert_that(
    base::is.character(scale_name),
    base::length(scale_name) == 1L,
    base::nzchar(scale_name),
    msg = "`scale_name` must be one non-empty character value."
  )
  assertthat::assert_that(
    base::is.character(scale_id_prefix),
    base::length(scale_id_prefix) == 1L,
    base::nzchar(scale_id_prefix),
    msg = "`scale_id_prefix` must be one non-empty character value."
  )
  assertthat::assert_that(
    base::is.numeric(x_minimum_parent),
    base::length(x_minimum_parent) == 1L,
    base::is.finite(x_minimum_parent),
    base::is.numeric(x_maximum_parent),
    base::length(x_maximum_parent) == 1L,
    base::is.finite(x_maximum_parent),
    x_minimum_parent < x_maximum_parent,
    msg = stringr::str_c(
      "`x_minimum_parent` and `x_maximum_parent` must be finite",
      " ",
      "numeric values defining a positive-width interval."
    )
  )
  assertthat::assert_that(
    base::is.numeric(y_minimum_parent),
    base::length(y_minimum_parent) == 1L,
    base::is.finite(y_minimum_parent),
    base::is.numeric(y_maximum_parent),
    base::length(y_maximum_parent) == 1L,
    base::is.finite(y_maximum_parent),
    y_minimum_parent < y_maximum_parent,
    msg = stringr::str_c(
      "`y_minimum_parent` and `y_maximum_parent` must be finite",
      " ",
      "numeric values defining a positive-height interval."
    )
  )
  assertthat::assert_that(
    base::is.numeric(tile_size_degrees),
    base::length(tile_size_degrees) == 1L,
    base::is.finite(tile_size_degrees),
    tile_size_degrees > 0,
    msg = "`tile_size_degrees` must be one positive finite number."
  )

  vec_x_breaks <-
    base::seq(
      from = base::floor(
        x_minimum_parent / tile_size_degrees
      ) * tile_size_degrees,
      to = base::ceiling(
        x_maximum_parent / tile_size_degrees
      ) * tile_size_degrees,
      by = tile_size_degrees
    )

  vec_y_breaks <-
    base::seq(
      from = base::floor(
        y_minimum_parent / tile_size_degrees
      ) * tile_size_degrees,
      to = base::ceiling(
        y_maximum_parent / tile_size_degrees
      ) * tile_size_degrees,
      by = tile_size_degrees
    )

  res_spatial_grid_tiles <-
    tidyr::expand_grid(
      x_left = vec_x_breaks[-base::length(vec_x_breaks)],
      y_bottom = vec_y_breaks[-base::length(vec_y_breaks)]
    ) |>
    dplyr::mutate(
      x_min = base::pmax(.data[["x_left"]], x_minimum_parent),
      x_max = base::pmin(
        .data[["x_left"]] + tile_size_degrees,
        x_maximum_parent
      ),
      y_min = base::pmax(.data[["y_bottom"]], y_minimum_parent),
      y_max = base::pmin(
        .data[["y_bottom"]] + tile_size_degrees,
        y_maximum_parent
      )
    ) |>
    dplyr::filter(
      .data[["x_max"]] > .data[["x_min"]],
      .data[["y_max"]] > .data[["y_min"]]
    ) |>
    dplyr::select(-"x_left", -"y_bottom") |>
    dplyr::mutate(
      tile_index = dplyr::row_number(),
      scale_id = stringr::str_c(
        scale_id_prefix,
        stringr::str_pad(
          string = .data[["tile_index"]],
          width = 3,
          side = "left",
          pad = "0"
        )
      ),
      scale = scale_name,
      parent_id = parent_scale_id
    ) |>
    dplyr::select(
      "scale_id",
      "scale",
      "parent_id",
      "x_min",
      "x_max",
      "y_min",
      "y_max"
    )

  return(res_spatial_grid_tiles)
}

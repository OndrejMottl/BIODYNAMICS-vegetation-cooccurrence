#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Generate spatial grid catalogue
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Generates Data/Input/spatial_grid.csv, the single source
#   of truth for all spatial units used in the spatial
#   scale analysis.
#
# Structure:
#   continental  — 3 hand-defined units (whole continents)
#   regional     — 20 x 20 degree tiles within each continent
#   local        — 5 x 5 degree tiles within each regional tile
#
# Re-run this script whenever tile definitions need updating.
# The CSV is version-controlled; do not edit it by hand.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Helper: generate regular grid tiles -----
#----------------------------------------------------------#

# Returns a tibble of non-overlapping tiles that cover the
#   supplied bounding box at the given step size.
# Tiles that fall completely outside the continent bounding
#   box are dropped; partially-overlapping tiles are clipped.
generate_tiles <- function(
    parent_id,
    x_min_parent,
    x_max_parent,
    y_min_parent,
    y_max_parent,
    step,
    scale,
    id_prefix) {
  vec_x_breaks <-
    seq(
      from = floor(x_min_parent / step) * step,
      to = ceiling(x_max_parent / step) * step,
      by = step
    )

  vec_y_breaks <-
    seq(
      from = floor(y_min_parent / step) * step,
      to = ceiling(y_max_parent / step) * step,
      by = step
    )

  data_tiles <-
    tidyr::expand_grid(
      x_left = vec_x_breaks[-length(vec_x_breaks)],
      y_bottom = vec_y_breaks[-length(vec_y_breaks)]
    ) |>
    dplyr::mutate(
      x_min = pmax(.data$x_left, x_min_parent),
      x_max = pmin(.data$x_left + step, x_max_parent),
      y_min = pmax(.data$y_bottom, y_min_parent),
      y_max = pmin(.data$y_bottom + step, y_max_parent)
    ) |>
    # Drop tiles that collapsed to zero width / height after clipping
    dplyr::filter(
      .data$x_max > .data$x_min,
      .data$y_max > .data$y_min
    ) |>
    dplyr::select(-"x_left", -"y_bottom") |>
    dplyr::mutate(
      tile_idx = dplyr::row_number(),
      scale_id = paste0(
        id_prefix,
        stringr::str_pad(
          string = .data$tile_idx,
          width = 3,
          side = "left",
          pad = "0"
        )
      ),
      scale = scale,
      parent_id = parent_id
    ) |>
    dplyr::select(
      "scale_id", "scale", "parent_id", "x_min", "x_max", "y_min", "y_max"
    )

  return(data_tiles)
}


#----------------------------------------------------------#
# 2. Continental units -----
#----------------------------------------------------------#

# Hand-defined — one row per continent / large region.
# Bounds cover the main Northern Hemisphere pollen data areas.
data_continental <-
  tibble::tibble(
    scale_id = c("europe", "america", "asia"),
    scale = "continental",
    parent_id = NA_character_,
    x_min = c(-10, -130, 60),
    x_max = c(40, -60, 140),
    y_min = c(35, 30, 50),
    y_max = c(70, 70, 75)
  )


#----------------------------------------------------------#
# 3. Regional units (20 x 20 degree tiles) -----
#----------------------------------------------------------#

data_regional <-
  data_continental |>
  dplyr::rowwise() |>
  dplyr::reframe(
    generate_tiles(
      parent_id = .data$scale_id,
      x_min_parent = .data$x_min,
      x_max_parent = .data$x_max,
      y_min_parent = .data$y_min,
      y_max_parent = .data$y_max,
      step = 20,
      scale = "regional",
      id_prefix = paste0(
        stringr::str_sub(.data$scale_id, 1, 2), "_r"
      )
    )
  )


#----------------------------------------------------------#
# 4. Local units (5 x 5 degree tiles) -----
#----------------------------------------------------------#

data_local <-
  data_regional |>
  dplyr::rowwise() |>
  dplyr::reframe(
    generate_tiles(
      parent_id = .data$scale_id,
      x_min_parent = .data$x_min,
      x_max_parent = .data$x_max,
      y_min_parent = .data$y_min,
      y_max_parent = .data$y_max,
      step = 5,
      scale = "local",
      id_prefix = paste0(.data$scale_id, "_l")
    )
  )


#----------------------------------------------------------#
# 5. Combine and write -----
#----------------------------------------------------------#

data_spatial_grid <-
  dplyr::bind_rows(
    data_continental,
    data_regional,
    data_local
  )

readr::write_csv(
  x = data_spatial_grid,
  file = here::here("Data/Input/spatial_grid.csv")
)

cli::cli_inform(
  c(
    "v" = "Spatial grid written to {.file Data/Input/spatial_grid.csv}",
    "i" = "Rows: {nrow(data_spatial_grid)}",
    "i" = "Continental: {nrow(data_continental)}",
    "i" = "Regional:    {nrow(data_regional)}",
    "i" = "Local:       {nrow(data_local)}"
  )
)

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
#   of truth for all spatial units used in both the spatial
#   scale analysis and the jSDM model fitting.
#
# Structure:
#   continental  — 3 hand-defined units (whole continents)
#   regional     — 20 x 20 degree tiles within each continent
#   local        — 5 x 5 degree tiles within each regional tile
#
# Each row carries four model fitting parameters that control how
#   the jSDM is trained for that spatial unit:
#   n_iter          — number of training iterations
#   n_step_size     — SGD mini-batch size (NA = auto / 10% of sites)
#   n_sampling      — Monte Carlo samples per epoch
#   n_samples_anova — Monte Carlo samples for ANOVA partitioning
#
# Defaults are assigned per scale level. Individual tiles that
#   contain denser pollen records are given higher n_iter via
#   explicit per-tile override tables defined below.
#
# Re-run this script whenever tile definitions or model fitting
#   parameters need updating.
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
# At continental extent, site counts are low relative to model
#   complexity, so a short training run (400 iterations, 100
#   MC samples) is sufficient.
data_continental <-
  tibble::tibble(
    scale_id = c("europe", "america", "asia"),
    scale = "continental",
    parent_id = NA_character_,
    x_min = c(-10, -130, 60),
    x_max = c(40, -60, 140),
    y_min = c(35, 30, 50),
    y_max = c(70, 70, 75),
    n_iter = 400L,
    n_step_size = NA_integer_,
    n_sampling = 100L,
    n_samples_anova = 500L
  )


#----------------------------------------------------------#
# 3. Regional units (20 x 20 degree tiles) -----
#----------------------------------------------------------#

# Default model fitting params for regional tiles: moderate
#   training run (1 600 iterations, 250 MC samples).
# Tiles with denser pollen records are overridden below
#   to 3 200 iterations for better model convergence.
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
  ) |>
  dplyr::mutate(
    n_iter = 1600L,
    n_step_size = NA_integer_,
    n_sampling = 250L,
    n_samples_anova = 500L
  )

# Per-tile overrides — tiles with higher data density need
#   more iterations to reach convergence.
data_regional_overrides <-
  tibble::tibble(
    scale_id = c(
      # Europe
      "eu_r004", "eu_r005", "eu_r008",
      # North America
      "am_r002", "am_r006", "am_r007", "am_r008", "am_r010",
      # Asia
      "as_r008"
    ),
    n_iter = 3200L
  )

data_regional <-
  data_regional |>
  dplyr::rows_update(
    y = data_regional_overrides,
    by = "scale_id",
    unmatched = "error"
  )


#----------------------------------------------------------#
# 4. Local units (5 x 5 degree tiles) -----
#----------------------------------------------------------#

# Default model fitting params for local tiles: longer training
#   run (3 200 iterations) because local extents tend to have
#   more sites with finer spatial variation.
# Tiles in data-rich areas are overridden below to either
#   6 400 or 10 000 iterations.
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
  ) |>
  dplyr::mutate(
    n_iter = 3200L,
    n_step_size = NA_integer_,
    n_sampling = 200L,
    n_samples_anova = 500L
  )

# Per-tile overrides — tiles in the densest pollen-data regions
#   require substantially more iterations to converge.
data_local_overrides <-
  tibble::tibble(
    scale_id = c(
      # 10 000 iterations — highest-density tile
      "eu_r002_l001",
      # 6 400 iterations — Europe
      "eu_r001_l002",
      "eu_r002_l004",
      "eu_r002_l008",
      "eu_r005_l002",
      "eu_r005_l007",
      "eu_r005_l009",
      "eu_r005_l014",
      "eu_r005_l015",
      "eu_r008_l003",
      "eu_r008_l004",
      "eu_r008_l007",
      "eu_r009_l001",
      "eu_r009_l003",
      # 6 400 iterations — North America
      "am_r004_l002",
      "am_r005_l005",
      "am_r005_l009",
      "am_r007_l004",
      "am_r008_l006",
      "am_r008_l009",
      "am_r011_l001",
      "am_r011_l004",
      "am_r011_l005",
      "am_r011_l009",
      "am_r011_l014"
    ),
    n_iter = c(
      10000L,
      rep(6400L, 24L)
    )
  )

data_local <-
  data_local |>
  dplyr::rows_update(
    y = data_local_overrides,
    by = "scale_id",
    unmatched = "error"
  )


#----------------------------------------------------------#
# 5. Combine and write -----
#----------------------------------------------------------#

# All three scale levels now carry the model fitting parameters.
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

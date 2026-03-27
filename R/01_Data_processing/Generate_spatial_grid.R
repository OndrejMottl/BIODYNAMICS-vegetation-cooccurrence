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
# Each row carries five model fitting parameters that control how
#   the jSDM is trained for that spatial unit:
#   n_iter            — number of training iterations
#   n_step_size       — SGD mini-batch size (NA = auto / 10% of sites)
#   n_sampling        — Monte Carlo samples per epoch
#   n_samples_anova   — Monte Carlo samples for ANOVA partitioning
#   n_early_stopping  — patience for early stopping
#                       (NA = disabled, 0 = auto)
#
# !! WARNING !!
# The current Data/Input/spatial_grid.csv contains manually tuned
#   model fitting parameters for spatial units whose jSDM did not
#   converge under default settings.  Running this script will
#   OVERWRITE all those per-unit adjustments with fresh defaults.
#   Only proceed if you intend to regenerate the grid from scratch.
#   See the `flag_allow_overwrite` safety flag in section 0.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Safety guard — must be set to TRUE before the script is allowed to
#   write Data/Input/spatial_grid.csv.  The existing file contains
#   manually adjusted model fitting parameters for spatial units whose
#   jSDM models did not converge with default settings; setting this
#   flag to TRUE will overwrite ALL those adjustments with the
#   defaults generated below.  Change with care.
flag_allow_overwrite <- FALSE

if (
  isFALSE(flag_allow_overwrite)
) {
  cli::cli_abort(
    c(
      "!" = paste(
        "Script aborted:",
        "{.code flag_allow_overwrite} is {.code FALSE}."
      ),
      "i" = paste(
        "The existing {.file Data/Input/spatial_grid.csv}",
        "contains manually tuned"
      ),
      " " = "model fitting parameters for units that did not converge.",
      "i" = paste(
        "Set {.code flag_allow_overwrite <- TRUE} in this script",
        "to proceed."
      ),
      "x" = "ALL manual adjustments will be lost if you overwrite."
    )
  )
}


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
# Parameters are set per continent reflecting differences in
#   dataset size and model complexity; higher n_iter and
#   n_sampling are used for the larger America and Asia extents.
data_continental <-
  tibble::tibble(
    scale_id = c("europe", "america", "asia"),
    scale = "continental",
    parent_id = NA_character_,
    x_min = c(-10, -130, 60),
    x_max = c(40, -60, 140),
    y_min = c(35, 30, 50),
    y_max = c(70, 70, 75),
    n_iter = c(400L, 800L, 3200L),
    n_step_size = NA_integer_,
    n_sampling = c(100L, 100L, 500L),
    n_samples_anova = 500L,
    n_early_stopping = c(NA_integer_, 0L, 0L)
  )


#----------------------------------------------------------#
# 3. Regional units (20 x 20 degree tiles) -----
#----------------------------------------------------------#

# Default model fitting params for regional tiles: moderate
#   training run (1 600 iterations, 250 MC samples).
# Note: individual tiles may require manual adjustment after
#   generation if the jSDM does not converge with these defaults.
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
    n_samples_anova = 500L,
    n_early_stopping = NA_integer_
  )


#----------------------------------------------------------#
# 4. Local units (5 x 5 degree tiles) -----
#----------------------------------------------------------#

# Default model fitting params for local tiles: longer training
#   run (3 200 iterations) because local extents tend to have
#   more sites with finer spatial variation.
# Note: individual tiles may require manual adjustment after
#   generation if the jSDM does not converge with these defaults.
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
    n_samples_anova = 500L,
    n_early_stopping = NA_integer_
  )


#----------------------------------------------------------#
# 5. Combine and write -----
#----------------------------------------------------------#

# All three scale levels now carry the model fitting parameters.
# NOTE: the values written here are INITIAL DEFAULTS only.
#   After running this script, manually adjust n_iter, n_sampling,
#   and n_early_stopping for any spatial units whose jSDM models
#   do not converge under the defaults.
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
    "i" = "Local:       {nrow(data_local)}",
    "!" = paste(
      "Review and manually adjust model fitting parameters for",
      "any units that do not converge."
    )
  )
)

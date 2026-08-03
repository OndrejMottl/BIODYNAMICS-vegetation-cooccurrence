#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Build spatial grid catalogue
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Generates Data/Input/spatial_grid.csv, the geometry/catalogue source
#   of truth for all spatial units used in spatial analyses.
#
# Structure:
#   continental - 3 hand-defined units (whole continents)
#   regional - 20 x 20 degree tiles within each continent
#   local - 5 x 5 degree tiles within each regional tile
#
# Model fitting parameters live in Data/Input/Model_tuning/.
# Regenerating this file changes spatial unit geometry only.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Safety guard must be set to TRUE before the script is allowed to
#   write Data/Input/spatial_grid.csv. Change with care because
#   downstream target stores and model tuning files refer to these
#   scale_id values.
flag_allow_overwrite <- FALSE

if (
  base::isFALSE(flag_allow_overwrite)
) {
  cli::cli_abort(
    base::c(
      "!" = stringr::str_c(
        "Script aborted: ",
        "{.code flag_allow_overwrite} is {.code FALSE}."
      ),
      "i" = stringr::str_c(
        "The existing {.file Data/Input/spatial_grid.csv} ",
        "contains spatial unit definitions used by"
      ),
      " " = "pipeline stores and model tuning files.",
      "i" = stringr::str_c(
        "Set {.code flag_allow_overwrite <- TRUE} in this script ",
        "to proceed."
      ),
      "x" = "Existing spatial unit definitions will be overwritten."
    )
  )
}


#----------------------------------------------------------#
# 1. Continental units -----
#----------------------------------------------------------#

# Hand-defined units contain one row per continent or large region.
# Bounds cover the main Northern Hemisphere pollen data areas.
data_continental <-
  tibble::tibble(
    scale_id = base::c("europe", "america", "asia"),
    scale = "continental",
    parent_id = NA_character_,
    continent_id = base::c("europe", "america", "asia"),
    x_min = base::c(-10, -130, 60),
    x_max = base::c(40, -60, 140),
    y_min = base::c(35, 30, 50),
    y_max = base::c(70, 70, 75)
  )


#----------------------------------------------------------#
# 2. Regional units (20 x 20 degree tiles) -----
#----------------------------------------------------------#

data_regional <-
  data_continental |>
  dplyr::rowwise() |>
  dplyr::reframe(
    build_spatial_grid_tiles(
      parent_scale_id = .data[["scale_id"]],
      x_minimum_parent = .data[["x_min"]],
      x_maximum_parent = .data[["x_max"]],
      y_minimum_parent = .data[["y_min"]],
      y_maximum_parent = .data[["y_max"]],
      tile_size_degrees = 20,
      scale_name = "regional",
      scale_id_prefix = stringr::str_c(
        stringr::str_sub(.data[["scale_id"]], 1, 2),
        "_r"
      )
    )
  ) |>
  dplyr::mutate(
    continent_id = .data[["parent_id"]]
  )


#----------------------------------------------------------#
# 3. Local units (5 x 5 degree tiles) -----
#----------------------------------------------------------#

data_local <-
  data_regional |>
  dplyr::rowwise() |>
  dplyr::reframe(
    build_spatial_grid_tiles(
      parent_scale_id = .data[["scale_id"]],
      x_minimum_parent = .data[["x_min"]],
      x_maximum_parent = .data[["x_max"]],
      y_minimum_parent = .data[["y_min"]],
      y_maximum_parent = .data[["y_max"]],
      tile_size_degrees = 5,
      scale_name = "local",
      scale_id_prefix = stringr::str_c(
        .data[["scale_id"]],
        "_l"
      )
    )
  ) |>
  dplyr::left_join(
    data_regional |>
      dplyr::select("scale_id", "continent_id") |>
      dplyr::rename(continent_id_from_parent = "continent_id"),
    by = dplyr::join_by("parent_id" == "scale_id")
  ) |>
  dplyr::mutate(
    continent_id = .data[["continent_id_from_parent"]]
  ) |>
  dplyr::select(-"continent_id_from_parent")


#----------------------------------------------------------#
# 4. Combine and write -----
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
  base::c(
    "v" = "Spatial grid written to {.file Data/Input/spatial_grid.csv}",
    "i" = "Rows: {nrow(data_spatial_grid)}",
    "i" = "Continental: {nrow(data_continental)}",
    "i" = "Regional:    {nrow(data_regional)}",
    "i" = "Local:       {nrow(data_local)}",
    "i" = "Model tuning is stored separately in Data/Input/Model_tuning/."
  )
)

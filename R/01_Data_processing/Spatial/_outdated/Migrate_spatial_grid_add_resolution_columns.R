#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   One-time migration: add resolution model-param columns
#              to Data/Input/spatial_grid.csv
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Adds nine new columns to the existing spatial grid CSV:
#
#   continent_id          — the continental parent for every unit
#                           (europe | america | asia)
#   n_iter_family         — family-resolution model iterations
#   n_step_size_family    — family-resolution SGD mini-batch size
#   n_sampling_family     — family-resolution Monte Carlo samples
#   n_early_stopping_family — family-resolution early stopping
#   n_iter_ft             — FT-resolution model iterations
#   n_step_size_ft        — FT-resolution SGD mini-batch size
#   n_sampling_ft         — FT-resolution Monte Carlo samples
#   n_early_stopping_ft   — FT-resolution early stopping
#
# Initial values for the 8 parameter columns are COPIES of the
#   genus-level (default) values.  Adjust them per spatial unit
#   after convergence testing at each new resolution.
#
# Note: n_samples_anova is NOT resolution-specific and remains
#   as a single shared column.
#
# This script is SAFE to run on the live CSV: it reads the
#   existing file, adds columns, and writes back.  Running it
#   a second time will fail because the guard at step 2 detects
#   that 'continent_id' already exists.
#
# Run ONCE, then commit the updated spatial_grid.csv.
# Do NOT regenerate via Generate_spatial_grid.R — that script
#   overwrites all manually tuned convergence parameters.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Read existing grid -----
#----------------------------------------------------------#

path_grid <-
  here::here("Data/Input/spatial_grid.csv")

data_grid <-
  readr::read_csv(
    file = path_grid,
    show_col_types = FALSE
  )


#----------------------------------------------------------#
# 2. Guard: abort if migration already applied -----
#----------------------------------------------------------#

assertthat::assert_that(
  !"continent_id" %in% base::names(data_grid),
  msg = stringr::str_glue(
    "Column 'continent_id' already exists in {path_grid}. ",
    "Migration has already been applied — aborting."
  )
)


#----------------------------------------------------------#
# 3. Build continent_id lookup -----
#----------------------------------------------------------#

# continental rows -> continent_id = their own scale_id
# regional rows    -> continent_id = parent_id
#                     (parent is always a continental scale_id)
# local rows       -> continent_id = grandparent
#                     (join through the regional parent)

data_continent_for_continental <-
  data_grid |>
  dplyr::filter(.data$scale == "continental") |>
  dplyr::select("scale_id") |>
  dplyr::mutate(continent_id = .data$scale_id)

data_continent_for_regional <-
  data_grid |>
  dplyr::filter(.data$scale == "regional") |>
  dplyr::mutate(continent_id = .data$parent_id) |>
  dplyr::select("scale_id", "continent_id")

data_continent_for_local <-
  data_grid |>
  dplyr::filter(.data$scale == "local") |>
  dplyr::select("scale_id", "parent_id") |>
  dplyr::left_join(
    data_continent_for_regional |>
      dplyr::rename(
        regional_scale_id = "scale_id",
        continent_id_from_regional = "continent_id"
      ),
    by = dplyr::join_by("parent_id" == "regional_scale_id")
  ) |>
  dplyr::select("scale_id", continent_id = "continent_id_from_regional")

data_continent_lookup <-
  dplyr::bind_rows(
    data_continent_for_continental,
    data_continent_for_regional,
    data_continent_for_local
  )


#----------------------------------------------------------#
# 4. Add continent_id and resolution param columns -----
#----------------------------------------------------------#

data_grid_updated <-
  data_grid |>
  dplyr::left_join(
    data_continent_lookup,
    by = dplyr::join_by("scale_id")
  ) |>
  dplyr::relocate("continent_id", .after = "parent_id") |>
  dplyr::mutate(
    n_iter_family = .data$n_iter,
    n_step_size_family = .data$n_step_size,
    n_sampling_family = .data$n_sampling,
    n_early_stopping_family = .data$n_early_stopping,
    n_iter_ft = .data$n_iter,
    n_step_size_ft = .data$n_step_size,
    n_sampling_ft = .data$n_sampling,
    n_early_stopping_ft = .data$n_early_stopping
  )


#----------------------------------------------------------#
# 5. Validate -----
#----------------------------------------------------------#

n_missing_continent <-
  data_grid_updated |>
  dplyr::filter(base::is.na(.data$continent_id)) |>
  base::nrow()

assertthat::assert_that(
  n_missing_continent == 0L,
  msg = stringr::str_glue(
    "{n_missing_continent} row(s) could not be assigned a ",
    "continent_id. Check scale / parent_id values in the CSV."
  )
)

n_rows_original <-
  base::nrow(data_grid)

n_rows_updated <-
  base::nrow(data_grid_updated)

assertthat::assert_that(
  n_rows_original == n_rows_updated,
  msg = stringr::str_glue(
    "Row count changed after migration: ",
    "before = {n_rows_original}, after = {n_rows_updated}. ",
    "Check for unintended joins."
  )
)


#----------------------------------------------------------#
# 6. Write back -----
#----------------------------------------------------------#

readr::write_csv(
  x = data_grid_updated,
  file = path_grid
)

cli::cli_inform(
  c(
    "v" = "Migration complete. Updated {.file {path_grid}}",
    "i" = "Rows: {n_rows_updated}",
    "i" = stringr::str_glue(
      "New columns added: continent_id, ",
      "n_iter_family, n_step_size_family, n_sampling_family, ",
      "n_early_stopping_family, n_iter_ft, n_step_size_ft, ",
      "n_sampling_ft, n_early_stopping_ft"
    ),
    "!" = stringr::str_c(
      "Initial values for _family and _ft columns are copies ",
      "of the genus-level defaults. ",
      "Adjust per spatial unit after convergence testing."
    )
  )
)

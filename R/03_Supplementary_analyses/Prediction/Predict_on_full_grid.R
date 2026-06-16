#----------------------------------------------------------#
#
#
#               Vegetation Co-occurrence
#
#          Predict on full spatio-temporal grid
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone supplementary script for predicting genus
# occurrence probabilities and expected genus richness on a
# regular land grid. This script is intentionally independent
# of the IAVS 2026 presentation scripts.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

sel_project <- "project_paleo_spatial_continental"
selected_scale_id <- "europe"
selected_resolution_id <- "genus"
selected_taxon <- "Fagus"
sel_grid_resolution <- 0.5
flag_verbose <- TRUE

Sys.setenv(R_CONFIG_ACTIVE = sel_project)

path_output <-
  here::here(
    "Outputs",
    "Prediction"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

path_chelsa_cache <-
  here::here(
    "Data",
    "Temp",
    "chelsa",
    "spatial_resolution_prediction",
    selected_scale_id
  )

base::dir.create(
  path = path_chelsa_cache,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Resolve model store and settings -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "paleo",
    scales = "continental",
    pipeline_name = "pipeline_paleo_spatial_resolution"
  ) |>
  dplyr::filter(
    .data$scale_id == selected_scale_id,
    .data$store_exists
  )

if (
  base::nrow(data_store_index) != 1L
) {
  cli::cli_abort(
    c(
      "Expected exactly one existing Europe spatial-resolution store.",
      "i" = "Run the paleo spatial-resolution continental pipeline first."
    )
  )
}

store_path <-
  data_store_index |>
  dplyr::pull("store_path")

prediction_inputs <-
  read_spatial_resolution_prediction_inputs(
    store_path = store_path,
    resolution_id = selected_resolution_id
  )

age_lim <-
  get_active_config(c("vegvault_data", "age_lim"))

time_step <-
  get_active_config(c("data_processing", "time_step"))

selected_abiotic_variables <-
  get_active_config(c("vegvault_data", "sel_abiotic_var_name"))

spatial_mode <-
  get_active_config(c("model_fitting", "spatial_mode"))

spatial_crs <-
  get_active_config(c("model_fitting", "spatial_crs"))

vec_age_slices <-
  base::seq(
    from = base::min(age_lim),
    to = base::max(age_lim),
    by = time_step
  )


#----------------------------------------------------------#
# 2. Build prediction grid -----
#----------------------------------------------------------#

list_prediction_grid <-
  build_land_prediction_grid(
    scale_id = selected_scale_id,
    grid_resolution = sel_grid_resolution,
    target_crs = spatial_crs
  )

if (
  isTRUE(flag_verbose)
) {
  cli::cli_inform(
    c(
      "i" = "Predicting on {nrow(list_prediction_grid[['data_grid']])} cells.",
      "i" = "Ages: {stringr::str_c(vec_age_slices, collapse = ', ')}."
    )
  )
}


#----------------------------------------------------------#
# 3. Predict all age slices -----
#----------------------------------------------------------#

data_predicted_long <-
  vec_age_slices |>
  rlang::set_names() |>
  purrr::map(
    .progress = flag_verbose,
    .f = ~ predict_spatial_resolution_grid_age(
      prediction_inputs = prediction_inputs,
      data_grid = list_prediction_grid[["data_grid"]],
      data_grid_coords_projected =
        list_prediction_grid[["data_grid_coords_projected"]],
      age = .x,
      abiotic_variables = selected_abiotic_variables,
      x_lim = list_prediction_grid[["x_lim"]],
      y_lim = list_prediction_grid[["y_lim"]],
      cache_dir = path_chelsa_cache,
      spatial_mode = spatial_mode
    )
  ) |>
  purrr::list_rbind()

data_expected_genus_richness <-
  summarise_expected_genus_richness(
    data_predicted_long = data_predicted_long
  )

data_selected_taxon_prediction <-
  data_predicted_long |>
  dplyr::filter(
    .data$taxon == selected_taxon
  )

if (
  base::nrow(data_selected_taxon_prediction) == 0L
) {
  cli::cli_abort(
    stringr::str_glue(
      "Selected taxon '{selected_taxon}' was not found in predictions."
    )
  )
}


#----------------------------------------------------------#
# 4. Save supplementary outputs -----
#----------------------------------------------------------#

file_prediction_long <-
  base::file.path(
    path_output,
    "full_grid_prediction_probabilities_europe_genus.qs"
  )

file_expected_richness <-
  base::file.path(
    path_output,
    "full_grid_expected_genus_richness_europe_genus.qs"
  )

file_selected_taxon <-
  base::file.path(
    path_output,
    stringr::str_glue(
      "full_grid_prediction_probability_",
      "{stringr::str_to_lower(selected_taxon)}_europe_genus.csv"
    )
  )

file_expected_richness_csv <-
  base::file.path(
    path_output,
    "full_grid_expected_genus_richness_europe_genus.csv"
  )

qs2::qs_save(
  x = data_predicted_long,
  file = file_prediction_long
)

qs2::qs_save(
  x = data_expected_genus_richness,
  file = file_expected_richness
)

readr::write_csv(
  x = data_selected_taxon_prediction,
  file = file_selected_taxon
)

readr::write_csv(
  x = data_expected_genus_richness,
  file = file_expected_richness_csv
)

if (
  isTRUE(flag_verbose)
) {
  cli::cli_inform(
    c(
      "v" = "Saved full-grid prediction outputs.",
      "i" = "Probabilities: {.path {file_prediction_long}}",
      "i" = "Expected richness: {.path {file_expected_richness}}"
    )
  )
}

#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Slide 12 paleo prediction animations
#
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

if (
  !base::requireNamespace("magick", quietly = TRUE)
) {
  cli::cli_abort(
    c(
      "The {.pkg magick} package is required to create GIF outputs.",
      "i" = "Install {.pkg magick} before rendering slide 12."
    )
  )
}

list_oracle_design <-
  load_design_config(
    path = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "design_config.json"
    )
  )

vec_oracle_palette <-
  list_oracle_design |>
  purrr::chuck(
    "config",
    "palette"
  )

vec_font_match <-
  stringr::str_match(
    string = purrr::chuck(
      list_oracle_design,
      "config",
      "typography",
      "body_family"
    ),
    pattern = "'([^']+)'"
  )

font_family <-
  vec_font_match[1, 2]

path_font <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "fonts",
    "VT323-Regular.ttf"
  )

if (
  !base::file.exists(path_font)
) {
  cli::cli_abort(
    c(
      "The VT323 font file is missing.",
      "i" = "Expected path: {.path {path_font}}."
    )
  )
}

try(
  systemfonts::register_font(
    name = font_family,
    plain = path_font
  ),
  silent = TRUE
)

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_continental")

selected_scale_id <- "europe"
selected_resolution_id <- "genus"
selected_taxon <- "Picea"

flag_smoke_mode <-
  base::identical(
    base::Sys.getenv("BIODYNAMICS_PREDICTION_SMOKE"),
    "true"
  )

selected_grid_resolution <-
  if (
    isTRUE(flag_smoke_mode)
  ) {
    5
  } else {
    0.5
  }


selected_taxon_fill_colors <-
  base::c(
    vec_oracle_palette[["surface_alt"]],
    vec_oracle_palette[["cyan"]]
  )


richness_fill_colors <-
  base::c(
    vec_oracle_palette[["surface_alt"]],
    vec_oracle_palette[["muted"]],
    vec_oracle_palette[["phosphor"]],
    vec_oracle_palette[["amber"]],
    vec_oracle_palette[["purple"]],
    vec_oracle_palette[["cyan"]]
  )

observed_point_color <-
  vec_oracle_palette[["amber"]]

path_output <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "figures",
    "results"
  )

path_chelsa_cache <-
  here::here(
    "Data",
    "Temp",
    "chelsa",
    "slide_12_paleo_predictions",
    selected_scale_id
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_chelsa_cache,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Load model inputs -----
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
      "Expected exactly one Europe spatial-resolution store.",
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
    from = base::max(age_lim),
    to = base::min(age_lim),
    by = -time_step
  )

if (
  isTRUE(flag_smoke_mode)
) {
  vec_age_slices <- vec_age_slices[[1L]]
}


#----------------------------------------------------------#
# 2. Predict grid -----
#----------------------------------------------------------#

list_prediction_grid <-
  build_land_prediction_grid(
    scale_id = selected_scale_id,
    grid_resolution = selected_grid_resolution,
    target_crs = spatial_crs
  )

data_predicted_long <-
  vec_age_slices |>
  rlang::set_names() |>
  purrr::map(
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

data_selected_taxon <-
  data_predicted_long |>
  dplyr::filter(
    .data$taxon == selected_taxon
  )

if (
  base::nrow(data_selected_taxon) == 0L
) {
  cli::cli_abort(
    stringr::str_glue(
      "Selected taxon '{selected_taxon}' was not found in predictions."
    )
  )
}

data_expected_richness <-
  summarise_expected_genus_richness(
    data_predicted_long = data_predicted_long
  )

model_r2_nagelkerke <-
  prediction_inputs |>
  purrr::chuck("model_evaluation", "model", "R2-Nagelkerke") |>
  base::unname()

data_species_metrics <-
  prediction_inputs |>
  purrr::chuck("model_evaluation", "species")

auc_median <-
  dplyr::pull(data_species_metrics, "AUC") |>
  stats::median(na.rm = TRUE)

auc_selected_taxon <-
  data_species_metrics |>
  dplyr::filter(
    .data$species == selected_taxon
  ) |>
  dplyr::pull("AUC") |>
  base::as.numeric()

data_coords_observed_raw <-
  prediction_inputs |>
  purrr::chuck("data_coords_projected") |>
  tibble::rownames_to_column(var = "dataset_name")

data_coords_observed <-
  if (
    base::all(
      base::c("coord_long", "coord_lat") %in%
        base::colnames(data_coords_observed_raw)
    )
  ) {
    data_coords_observed_raw |>
      dplyr::select(
        "dataset_name",
        "coord_long",
        "coord_lat"
      )
  } else {
    data_coords_observed_sf <-
      data_coords_observed_raw |>
      sf::st_as_sf(
        coords = c("coord_x_km", "coord_y_km"),
        crs = spatial_crs,
        remove = FALSE
      ) |>
      sf::st_transform(crs = 4326L)

    mat_coords_observed <-
      sf::st_coordinates(data_coords_observed_sf)

    data_coords_observed_sf |>
      dplyr::mutate(
        coord_long = mat_coords_observed[, 1],
        coord_lat = mat_coords_observed[, 2]
      ) |>
      sf::st_drop_geometry() |>
      dplyr::select(
        "dataset_name",
        "coord_long",
        "coord_lat"
      )
  }

data_observations_selected_species <-
  prediction_inputs |>
  purrr::chuck("data_model_input", "data_community_to_fit") |>
  as.data.frame() |>
  tibble::rownames_to_column(var = "sample_id") |>
  tibble::as_tibble() |>
  dplyr::mutate(
    dataset_name = stringr::str_remove(.data$sample_id, "__.*$"),
    age = base::as.integer(stringr::str_extract(.data$sample_id, "[0-9]+$")),
  ) |>
  tidyr::pivot_longer(
    cols = -base::c("sample_id", "dataset_name", "age"),
    names_to = "taxon",
    values_to = "observed_presence"
  ) |>
  dplyr::filter(
    .data$observed_presence == 1L,
    .data$taxon == selected_taxon
  ) |>
  dplyr::left_join(
    data_coords_observed |>
      dplyr::select(
        "dataset_name",
        "coord_long",
        "coord_lat"
      ),
    by = "dataset_name"
  ) |>
  dplyr::select(
    "age",
    "coord_long",
    "coord_lat"
  ) |>
  dplyr::distinct()

data_world <-
  ggplot2::map_data(map = "world") |>
  dplyr::filter(
    .data$long >= base::min(list_prediction_grid[["x_lim"]]) - 2,
    .data$long <= base::max(list_prediction_grid[["x_lim"]]) + 2,
    .data$lat >= base::min(list_prediction_grid[["y_lim"]]) - 2,
    .data$lat <= base::max(list_prediction_grid[["y_lim"]]) + 2
  )


#----------------------------------------------------------#
# 3. Build frames -----
#----------------------------------------------------------#
#----------------------------------------------------------#
# 4. Save animations -----
#----------------------------------------------------------#

save_prediction_animation(
  data_frame = data_selected_taxon,
  value_column = "predicted_probability",
  subtitle_label = stringr::str_glue("{selected_taxon}"),
  fill_label = "Probability",
  fill_limits = c(0, 1),
  vec_age_slices = vec_age_slices,
  path_output = path_output,
  list_prediction_grid = list_prediction_grid,
  data_world = data_world,
  grid_resolution = selected_grid_resolution,
  time_step = time_step,
  fill_colors = selected_taxon_fill_colors,
  metric_label = stringr::str_glue(
    "Model Nagelkerke R² ~ {base::round(model_r2_nagelkerke, 3)} |",
    " {selected_taxon} AUC ~ {base::round(auc_selected_taxon, 3)}"
  ),
  data_points = data_observations_selected_species,
  point_color = observed_point_color,
  frame_directory_name = "slide_12_future_predictions_selected_taxon",
  output_file_name = "slide_12_future_predictions_selected_taxon.gif",
  vec_palette = vec_oracle_palette,
  font_family = font_family
)

save_prediction_animation(
  data_frame = data_expected_richness,
  value_column = "expected_genus_richness",
  subtitle_label = "Genus",
  fill_label = "Richness",
  fill_limits = c(
    0,
    base::max(data_expected_richness[["expected_genus_richness"]])
  ),
  vec_age_slices = vec_age_slices,
  path_output = path_output,
  list_prediction_grid = list_prediction_grid,
  data_world = data_world,
  grid_resolution = selected_grid_resolution,
  time_step = time_step,
  fill_trans = scales::log1p_trans(),
  fill_colors = richness_fill_colors,
  metric_label = stringr::str_glue(
    "Model Nagelkerke R² ~ {base::round(model_r2_nagelkerke, 3)} |",
    " Median AUC ~ {base::round(auc_median, 3)}"
  ),
  frame_directory_name =
    "slide_12_future_predictions_expected_genus_richness",
  output_file_name =
    "slide_12_future_predictions_expected_genus_richness.gif",
  vec_palette = vec_oracle_palette,
  font_family = font_family
)

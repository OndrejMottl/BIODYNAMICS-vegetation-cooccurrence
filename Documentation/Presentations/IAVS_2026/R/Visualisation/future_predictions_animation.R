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
    vec_oracle_palette[["purple"]]
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

format_age_label <- function(age) {
  if (
    age == 0
  ) {
    return("0 ka BP")
  }

  res_label <-
    stringr::str_glue("{base::format(age / 1000, trim = TRUE)} ka BP")

  return(res_label)
}

build_prediction_frame <- function(
    data_frame,
    age_value,
    value_column,
    subtitle_label,
    fill_label,
    fill_limits,
    fill_trans = scales::transform_identity(),
    fill_colors = c("black", "white"),
    data_points = NULL,
    point_color = "red",
    metric_label = NULL) {
  data_age <-
    data_frame |>
    dplyr::filter(
      .data$age == age_value
    )

  metric_label <-
    metric_label[!base::is.na(metric_label)]

  metric_label <-
    metric_label[base::nzchar(metric_label)]

  caption_text <-
    stringr::str_flatten(metric_label, collapse = " | ")

  assertthat::assert_that(
    base::is.character(fill_colors),
    base::length(fill_colors) >= 2L,
    msg = "`fill_colors` must contain at least two colours."
  )

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::coord_quickmap(
      xlim = list_prediction_grid[["x_lim"]],
      ylim = list_prediction_grid[["y_lim"]],
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_fill_gradientn(
      colours = fill_colors,
      limits = fill_limits,
      trans = fill_trans,
      name = fill_label,
      guide = ggplot2::guide_colorbar(
        nbin = 200,
        title.position = "top",
        title.hjust = 0.5,
        barwidth = grid::unit(0.5, "lines"),
        barheight = grid::unit(5, "lines")
      )
    ) +
    ggview::canvas(
      width = 800,
      height = 620,
      units = "px",
      dpi = 300,
      bg = vec_oracle_palette[["background"]]
    ) +
    theme_oracle(base_family = font_family, base_size = 11) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(
        fill = vec_oracle_palette[["background"]],
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = vec_oracle_palette[["background"]],
        colour = NA
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = vec_oracle_palette[["border"]],
        linewidth = 0.12,
        linetype = "dotted"
      ),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "right",
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.margin = ggplot2::margin(0, 0, 0, 0),
      legend.background = ggplot2::element_blank(),
      legend.box.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_rect(
        fill = vec_oracle_palette[["background"]],
        colour = NA
      ),
      legend.title = ggplot2::element_text(
        size = 8,
        family = font_family,
        colour = vec_oracle_palette[["cyan"]]
      ),
      legend.text = ggplot2::element_text(
        size = 7,
        family = font_family,
        colour = vec_oracle_palette[["phosphor"]]
      ),
      plot.title = ggplot2::element_text(
        colour = vec_oracle_palette[["phosphor"]],
        family = font_family,
        face = "bold"
      ),
      plot.subtitle = ggplot2::element_text(
        colour = vec_oracle_palette[["cyan"]],
        family = font_family
      ),
      plot.caption = ggplot2::element_text(
        colour = vec_oracle_palette[["phosphor"]],
        family = font_family,
        size = 8,
        hjust = 0,
        margin = ggplot2::margin(5, 0, 0, 0)
      ),
      plot.margin = ggplot2::margin(5, 5, 5, 5)
    ) +
    ggplot2::labs(
      title = format_age_label(age_value),
      subtitle = subtitle_label,
      caption = caption_text
    ) +
    ggplot2::geom_tile(
      data = data_age,
      mapping = ggplot2::aes(
        x = .data$coord_long,
        y = .data$coord_lat,
        fill = .data[[value_column]]
      ),
      width = selected_grid_resolution,
      height = selected_grid_resolution,
      alpha = 0.9
    ) +
    ggplot2::geom_polygon(
      data = data_world,
      mapping = ggplot2::aes(
        x = .data$long,
        y = .data$lat,
        group = .data$group
      ),
      fill = NA,
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.14,
      alpha = 0.75
    )

  if (
    isFALSE(base::is.null(data_points))
  ) {
    data_points_age <-
      data_points |>
      dplyr::filter(
        .data$age == age_value
      ) |>
      tidyr::drop_na(
        "coord_long",
        "coord_lat"
      )

    res_plot <-
      res_plot +
      ggplot2::geom_point(
        data = data_points_age,
        mapping = ggplot2::aes(
          x = .data$coord_long,
          y = .data$coord_lat
        ),
        inherit.aes = FALSE,
        size = 0.5,
        shape = 4,
        colour = point_color,
        alpha = 0.5
      )
  }

  return(res_plot)
}

save_prediction_animation <- function(
    data_frame,
    value_column,
    subtitle_label,
    fill_label,
    fill_limits,
    fill_trans = scales::transform_identity(),
    fill_colors = NULL,
    data_points = NULL,
    point_color = "#ff4d4d",
    metric_label = NULL,
    frame_directory_name,
    output_file_name) {
  if (
    base::is.null(fill_trans)
  ) {
    fill_trans <- scales::transform_identity()
  }

  path_frame_output <-
    base::file.path(
      path_output,
      "frames",
      frame_directory_name
    )

  base::dir.create(
    path = path_frame_output,
    showWarnings = FALSE,
    recursive = TRUE
  )

  vec_stale_frames <-
    base::list.files(
      path = path_frame_output,
      pattern = base::paste0("^", frame_directory_name, "_.*[.]png$"),
      full.names = TRUE
    )

  if (
    base::length(vec_stale_frames) > 0L
  ) {
    base::unlink(x = vec_stale_frames)
  }

  frame_index_width <-
    base::nchar(base::length(vec_age_slices))

  data_frame_paths <-
    tibble::tibble(
      frame_index = base::seq_along(vec_age_slices),
      age = vec_age_slices
    ) |>
    dplyr::mutate(
      frame_id = stringr::str_pad(
        string = .data$frame_index,
        width = frame_index_width,
        side = "left",
        pad = "0"
      ),
      frame_path = base::file.path(
        path_frame_output,
        stringr::str_glue(
          "{frame_directory_name}_{frame_id}_",
          "{base::as.integer(age)}.png"
        )
      )
    )

  purrr::pwalk(
    .l = data_frame_paths,
    .f = function(frame_index, age, frame_id, frame_path) {
      plot_frame <-
        if (
          base::is.null(data_points)
        ) {
          build_prediction_frame(
            data_frame = data_frame,
            age_value = age,
            value_column = value_column,
            subtitle_label = subtitle_label,
            fill_label = fill_label,
            fill_limits = fill_limits,
            fill_trans = fill_trans,
            fill_colors = fill_colors,
            metric_label = metric_label
          )
        } else {
          build_prediction_frame(
            data_frame = data_frame,
            age_value = age,
            value_column = value_column,
            subtitle_label = subtitle_label,
            fill_label = fill_label,
            fill_limits = fill_limits,
            fill_trans = fill_trans,
            data_points = data_points |>
              dplyr::filter(
                base::abs(.data$age - age) <= (time_step / 2)
              ) |>
              tidyr::drop_na(
                "coord_long",
                "coord_lat"
              ),
            fill_colors = fill_colors,
            point_color = point_color,
            metric_label = metric_label
          )
        }

      ggview::save_ggplot(
        plot = plot_frame,
        file = frame_path,
        device = ragg::agg_png
      )
    }
  )

  list_animation <-
    build_gif_from_frames(
      vec_frame_paths = data_frame_paths |>
        dplyr::pull("frame_path"),
      output_path = base::file.path(
        path_output,
        output_file_name
      ),
      fps = 2,
      loop = 0L,
      optimize = TRUE
    )

  if (
    !isTRUE(purrr::chuck(list_animation, "used_magick"))
  ) {
    cli::cli_abort(
      "Could not create GIF because no GIF backend was available."
    )
  }
}


#----------------------------------------------------------#
# 4. Save animations -----
#----------------------------------------------------------#

save_prediction_animation(
  data_frame = data_selected_taxon,
  value_column = "predicted_probability",
  subtitle_label = stringr::str_glue("{selected_taxon}"),
  fill_label = "Probability",
  fill_limits = c(0, 1),
  fill_colors = selected_taxon_fill_colors,
  metric_label = stringr::str_glue(
    "Model Nagelkerke R² ~ {base::round(model_r2_nagelkerke, 3)} |",
    " {selected_taxon} AUC ~ {base::round(auc_selected_taxon, 3)}"
  ),
  data_points = data_observations_selected_species,
  point_color = observed_point_color,
  frame_directory_name = "slide_12_future_predictions_selected_taxon",
  output_file_name = "slide_12_future_predictions_selected_taxon.gif"
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
  fill_trans = scales::log1p_trans(),
  fill_colors = richness_fill_colors,
  metric_label = stringr::str_glue(
    "Model Nagelkerke R² ~ {base::round(model_r2_nagelkerke, 3)} |",
    " Median AUC ~ {base::round(auc_median, 3)}"
  ),
  frame_directory_name =
    "slide_12_future_predictions_expected_genus_richness",
  output_file_name =
    "slide_12_future_predictions_expected_genus_richness.gif"
)

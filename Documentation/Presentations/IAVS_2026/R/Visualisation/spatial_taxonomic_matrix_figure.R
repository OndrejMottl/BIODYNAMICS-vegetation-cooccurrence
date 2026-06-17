#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Slide 09 spatial taxonomic association figure
#
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

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

path_output <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "figures",
    "results"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

vec_scale_levels <-
  base::c(
    "local",
    "regional",
    "continental"
  )

vec_scale_labels <-
  base::c(
    "local" = "LOCAL",
    "regional" = "REGIONAL",
    "continental" = "CONTINENTAL"
  )

vec_resolution_labels <-
  base::c(
    "genus" = "Genus",
    "family" = "Family",
    "functional_type" = "Functional type"
  )

vec_required_components <-
  base::c(
    "Abiotic",
    "Spatial",
    "Associations"
  )

vec_component_colours <-
  base::c(
    "Abiotic" = vec_oracle_palette[["amber"]],
    "Spatial" = vec_oracle_palette[["cyan"]],
    "Associations" = vec_oracle_palette[["purple"]]
  )

vec_continent_shapes <-
  base::c(
    "america" = 22,
    "asia" = 24,
    "europe" = 21
  )


#----------------------------------------------------------#
# 1. Load spatial results -----
#----------------------------------------------------------#

file_paleo_unit <-
  get_latest_dated_file_path(
    file_name_base = "paleo_patterns_unit",
    path_directory = here::here("Outputs", "Tables"),
    file_extension = "csv"
  )

data_paleo_unit <-
  readr::read_csv(
    file = file_paleo_unit,
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    continent_id = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data", "Input", "spatial_grid.csv")
    )
  )


#----------------------------------------------------------#
# 2. Prepare plot data -----
#----------------------------------------------------------#

data_paleo_plot <-
  prepare_spatial_variance_plot_data(
    data_unit = data_paleo_unit,
    vec_scale_levels = vec_scale_levels,
    vec_resolution_labels = vec_resolution_labels,
    percentage_source_column = "R2_Nagelkerke_percentage",
    scale_source_to_percentage = FALSE
  )

data_mix_colours <-
  prepare_spatial_variance_waffle_data(
    data_plot = data_paleo_plot,
    vec_component_colours = vec_component_colours,
    vec_required_components = vec_required_components,
    method = "perc_avg"
  ) |>
  dplyr::select(
    "scale",
    "scale_id",
    "resolution_id",
    "continent_id",
    "tile_fill_colour"
  )

data_association_spread <-
  data_paleo_plot |>
  dplyr::filter(
    .data$component == "Associations"
  ) |>
  dplyr::left_join(
    y = data_mix_colours,
    by = dplyr::join_by(
      scale,
      scale_id,
      resolution_id,
      continent_id
    )
  ) |>
  dplyr::mutate(
    scale_index = base::as.integer(.data$scale),
    scale_label = base::unname(
      vec_scale_labels[base::as.character(.data$scale)]
    )
  )

data_association_mean <-
  data_association_spread |>
  dplyr::group_by(
    .data$resolution_label,
    .data$scale,
    .data$scale_index
  ) |>
  dplyr::summarise(
    mean_association = base::mean(
      .data$component_total_percentage,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    x = .data$scale_index - 0.34,
    xend = .data$scale_index + 0.34
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

plot_association_spread <-
  data_association_spread |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$scale_index,
      y = .data$component_total_percentage
    )
  ) +
  ggplot2::facet_wrap(
    facets = ggplot2::vars(resolution_label),
    nrow = 1
  ) +
  ggplot2::scale_x_continuous(
    trans = "reverse",
    breaks = base::seq_along(vec_scale_levels),
    labels = base::unname(vec_scale_labels),
    limits = base::c(0.45, 3.55),
    expand = ggplot2::expansion(mult = base::c(0.02, 0.02))
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 60),
    breaks = base::seq(0, 60, by = 20),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_fill_identity() +
  ggplot2::scale_shape_manual(
    values = vec_continent_shapes,
    name = NULL,
    breaks = base::names(vec_continent_shapes),
    labels = base::c(
      "America",
      "Asia",
      "Europe"
    ),
    guide = ggplot2::guide_legend(
      nrow = 3,
      override.aes = base::list(
        fill = NA,
        colour = vec_oracle_palette[["phosphor"]],
        alpha = 1,
        stroke = 0.9
      )
    )
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Association\nvariance"
  ) +
  ggview::canvas(
    width = 1120,
    height = 540,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  create_oracle_theme(
    base_family = font_family,
    base_size = 9
  ) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.22
    ),
    axis.line = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.28
    ),
    axis.text.x = ggplot2::element_text(
      colour = vec_oracle_palette[["cyan"]],
      size = 7.4,
      angle = 17,
      vjust = 0.92
    ),
    axis.text.y = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 7.8
    ),
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 7.8,
      lineheight = 0.82
    ),
    legend.position = "bottom",
    legend.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.key = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.title = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 7.5
    ),
    legend.text = ggplot2::element_text(
      colour = vec_oracle_palette[["text"]],
      size = 7.2
    ),
    strip.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.25
    ),
    strip.text = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 9.3,
      face = "bold"
    ),
    panel.spacing.x = grid::unit(0.5, "lines"),
    plot.margin = ggplot2::margin(6, 8, 4, 4)
  ) +
  ggplot2::geom_violin(
    mapping = ggplot2::aes(
      x = .data$scale_index,
      y = .data$component_total_percentage,
      group = .data$scale_index
    ),
    inherit.aes = FALSE,
    fill = vec_oracle_palette[["muted"]],
    colour = NA,
    alpha = 0.3,
    width = 0.68,
    scale = "width",
    trim = TRUE
  ) +
  ggplot2::geom_segment(
    data = data_association_mean,
    mapping = ggplot2::aes(
      x = .data$x,
      xend = .data$xend,
      y = .data$mean_association,
      yend = .data$mean_association
    ),
    inherit.aes = FALSE,
    colour = vec_oracle_palette[["purple"]],
    linewidth = 1.1,
    alpha = 0.85,
    lineend = "round"
  ) +
  ggplot2::geom_jitter(
    mapping = ggplot2::aes(
      fill = .data$tile_fill_colour,
      shape = .data$continent_id
    ),
    width = 0.25,
    height = 0,
    size = 0.9,
    colour = vec_oracle_palette[["background"]],
    stroke = 0.05,
    alpha = 1
  )

plot_association_spread_no_legend <-
  plot_association_spread +
  ggplot2::theme(
    legend.position = "none"
  )

plot_shape_legend <-
  cowplot::get_legend(
    plot_association_spread
  )

plot_triangle_legend <-
  plot_variance_component_triangle_legend(
    vec_component_colours = vec_component_colours,
    vec_required_components = vec_required_components,
    vec_component_labels = base::c(
      "CLIM",
      "SPACE",
      "ASSOC"
    ),
    max_component_value = 100,
    component_step = 2,
    font_family = font_family,
    label_colour = base::c(
      "Abiotic" = vec_oracle_palette[["amber"]],
      "Spatial" = vec_oracle_palette[["cyan"]],
      "Associations" = vec_oracle_palette[["purple"]]
    ),
    title_colour = vec_oracle_palette[["phosphor"]],
    border_colour = vec_oracle_palette[["border"]],
    background_colour = vec_oracle_palette[["background"]],
    point_size = 1.8,
    label_size = 2,
    triangle_x_offset = 0.16,
    method = "perc_avg"
  ) +
  ggplot2::theme(
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  )

figure_spatial_taxonomic_matrix <-
  cowplot::plot_grid(
    plot_association_spread_no_legend,
    cowplot::plot_grid(
      plot_triangle_legend,
      plot_shape_legend,
      nrow = 2,
      rel_heights = base::c(0.3, 0.4)
    ),
    nrow = 1,
    rel_widths = base::c(1.4, 0.3)
  ) +
  ggview::canvas(
    width = 1500,
    height = 600,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_spatial_taxonomic_matrix,
  file = base::file.path(
    path_output,
    "slide_09_spatial_taxonomic_matrix.png"
  ),
  device = ragg::agg_png
)

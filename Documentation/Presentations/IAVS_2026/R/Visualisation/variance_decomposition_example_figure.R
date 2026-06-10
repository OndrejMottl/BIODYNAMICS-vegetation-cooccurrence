#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Variance decomposition example figures
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

vec_component_colours <-
  base::c(
    "Climate" = vec_oracle_palette[["amber"]],
    "Space" = vec_oracle_palette[["cyan"]],
    "Associations" = vec_oracle_palette[["purple"]]
  )


#----------------------------------------------------------#
# 1. Example data -----
#----------------------------------------------------------#

data_example_components <-
  tibble::tibble(
    component = base::c(
      "Climate",
      "Space",
      "Associations"
    ),
    component_share = base::c(
      60,
      30,
      10
    )
  ) |>
  dplyr::mutate(
    component = base::factor(
      .data$component,
      levels = base::names(vec_component_colours)
    ),
    xmin = dplyr::lag(
      base::cumsum(.data$component_share),
      default = 0
    ),
    xmax = base::cumsum(.data$component_share),
    fill_colour = vec_component_colours[base::as.character(.data$component)]
  )

data_example_point_colour <-
  data_example_components |>
  dplyr::mutate(
    observation_id = "example"
  ) |>
  mix_variance_component_colours(
    vec_component_colours = vec_component_colours,
    vec_required_components = base::names(vec_component_colours),
    observation_id_column = "observation_id",
    component_column = "component",
    share_column = "component_share",
    method = "perc_avg"
  )

value_example_point_colour <-
  data_example_point_colour |>
  dplyr::pull(.data$tile_fill_colour)


#----------------------------------------------------------#
# 2. Make figures -----
#----------------------------------------------------------#

figure_component_stack_example <-
  data_example_components |>
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = base::c(0, 100),
    ylim = base::c(0, 1),
    expand = FALSE,
    clip = "off"
  ) +
  ggplot2::scale_fill_identity() +
  ggplot2::scale_colour_identity() +
  ggview::canvas(
    width = 360,
    height = 80,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::theme_void() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  ) +
  ggplot2::geom_rect(
    mapping = ggplot2::aes(
      xmin = .data$xmin,
      xmax = .data$xmax,
      ymin = 0.16,
      ymax = 0.84,
      fill = .data$fill_colour
    ),
    colour = NA
  )

figure_component_point_example <-
  ggplot2::ggplot() +
  ggplot2::coord_equal(
    xlim = base::c(-1, 1),
    ylim = base::c(-1, 1),
    expand = FALSE,
    clip = "off"
  ) +
  ggview::canvas(
    width = 180,
    height = 180,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::theme_void() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      x = 0,
      y = 0
    ),
    shape = 21,
    size = 11,
    fill = value_example_point_colour,
    colour = value_example_point_colour,
    stroke = 0.1
  )


#----------------------------------------------------------#
# 3. Save figures -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_component_stack_example,
  file = base::file.path(
    path_output,
    "slide_06_component_stack_example.png"
  ),
  device = ragg::agg_png
)

ggview::save_ggplot(
  plot = figure_component_point_example,
  file = base::file.path(
    path_output,
    "slide_06_component_point_example.png"
  ),
  device = ragg::agg_png
)

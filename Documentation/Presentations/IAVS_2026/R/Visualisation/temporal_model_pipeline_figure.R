#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Temporal model pipeline schematic figure
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

selected_age <- 2000


#----------------------------------------------------------#
# 1. Data for schematic -----
#----------------------------------------------------------#

node_box <- function(
    id,
    label,
    x,
    y,
    width,
    height,
    colour,
    fill = vec_oracle_palette[["surface"]],
    text_colour = vec_oracle_palette[["text"]],
    text_size = 2.9,
    fontface = "bold") {
  res_box <-
    tibble::tibble(
      id = id,
      label = label,
      x = x,
      y = y,
      width = width,
      height = height,
      xmin = x - width / 2,
      xmax = x + width / 2,
      ymin = y - height / 2,
      ymax = y + height / 2,
      colour = colour,
      fill = fill,
      text_colour = text_colour,
      text_size = text_size,
      fontface = fontface
    )

  return(res_box)
}

colour_temporal <- vec_oracle_palette[["red"]]
colour_community <- vec_oracle_palette[["phosphor"]]
colour_climate <- vec_oracle_palette[["amber"]]
colour_spatial <- vec_oracle_palette[["cyan"]]
colour_association <- vec_oracle_palette[["purple"]]
colour_shared <- vec_oracle_palette[["muted"]]

data_slice_boxes <-
  tibble::tibble(
    age = base::seq(0, 20000, by = 500),
    x = base::seq(5, 88, length.out = base::length(age)),
    y = 82,
    width = 1.05,
    height = dplyr::if_else(age == selected_age, 11, 6),
    colour = dplyr::if_else(
      age == selected_age,
      colour_temporal,
      vec_oracle_palette[["border"]]
    ),
    alpha = dplyr::if_else(age == selected_age, 0.95, 0.55)
  ) |>
  dplyr::mutate(
    xmin = x - width / 2,
    xmax = x + width / 2,
    ymin = y - height / 2,
    ymax = y + height / 2
  )

data_input_boxes <-
  dplyr::bind_rows(
    node_box(
      id = "community",
      label = "COMMUNITY",
      x = 20,
      y = 55,
      width = 22,
      height = 12,
      colour = colour_community,
      text_colour = colour_community,
      text_size = 3.55
    ),
    node_box(
      id = "abiotic",
      label = "ABIOTIC",
      x = 50,
      y = 55,
      width = 19,
      height = 12,
      colour = colour_climate,
      text_colour = colour_climate,
      text_size = 3.55
    ),
    node_box(
      id = "coords",
      label = "COORDS",
      x = 78,
      y = 55,
      width = 18,
      height = 12,
      colour = colour_spatial,
      text_colour = colour_spatial,
      text_size = 3.55
    )
  )

data_process_boxes <-
  dplyr::bind_rows(
    node_box(
      id = "network",
      label = "NETWORK\nDIAGNOSTICS",
      x = 66,
      y = 28,
      width = 24,
      height = 14,
      colour = colour_shared,
      text_colour = colour_shared,
      text_size = 3.05
    ),
    node_box(
      id = "model",
      label = "{sjSDM}",
      x = 34,
      y = 28,
      width = 24,
      height = 14,
      colour = colour_association,
      text_colour = colour_association,
      text_size = 3.3
    )
  )

data_node_boxes <-
  dplyr::bind_rows(
    data_input_boxes,
    data_process_boxes
  )

data_links <-
  tidyr::expand_grid(
    source_id = dplyr::pull(data_input_boxes, id),
    target_id = dplyr::pull(data_process_boxes, id)
  ) |>
  dplyr::left_join(
    data_input_boxes |>
      dplyr::select(
        source_id = id,
        x,
        y = ymin
      ),
    by = dplyr::join_by(source_id)
  ) |>
  dplyr::left_join(
    data_process_boxes |>
      dplyr::select(
        target_id = id,
        xend = x,
        yend = ymax
      ),
    by = dplyr::join_by(target_id)
  ) |>
  dplyr::mutate(
    colour = colour_shared
  )

data_pipeline_frame <-
  tibble::tibble(
    xmin = 6,
    xmax = 94,
    ymin = 15,
    ymax = 66,
    colour = colour_temporal
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_temporal_pipeline <-
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = base::c(0, 100),
    ylim = base::c(0, 100),
    expand = FALSE,
    clip = "off"
  ) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_fill_identity() +
  ggplot2::scale_alpha_identity() +
  ggplot2::scale_size_identity() +
  ggview::canvas(
    width = 800,
    height = 600,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  create_oracle_theme(base_family = font_family, base_size = 11) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.grid = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    legend.position = "none",
    plot.margin = ggplot2::margin(8, 6, 8, 6)
  ) +
  ggplot2::geom_rect(
    data = data_slice_boxes,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      colour = colour,
      fill = colour,
      alpha = alpha
    )
  ) +
  ggplot2::geom_segment(
    data = data_links,
    mapping = ggplot2::aes(
      x = x,
      y = y,
      xend = xend,
      yend = yend,
      colour = colour
    ),
    linewidth = 0.45,
    alpha = 0.42
  ) +
  ggplot2::geom_rect(
    data = data_pipeline_frame,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      colour = colour
    ),
    fill = NA,
    linewidth = 0.6,
    alpha = 0.82
  ) +
  ggplot2::geom_rect(
    data = data_node_boxes,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      colour = colour,
      fill = fill
    ),
    linewidth = 0.55,
    alpha = 0.82
  ) +
  ggplot2::geom_text(
    data = data_node_boxes,
    mapping = ggplot2::aes(
      x = x,
      y = y,
      label = label,
      colour = text_colour,
      size = text_size,
      fontface = fontface
    ),
    lineheight = 0.82,
    family = font_family
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 50,
    y = 94,
    label = "500-YEAR SLICES",
    colour = vec_oracle_palette[["muted"]],
    family = font_family,
    fontface = "bold",
    size = 4.2
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 1,
    y = 82,
    label = "0",
    colour = vec_oracle_palette[["phosphor"]],
    family = font_family,
    size = 5.2
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 96,
    y = 82,
    label = "20ka",
    colour = vec_oracle_palette[["phosphor"]],
    family = font_family,
    size = 5.2
  )

#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_temporal_pipeline,
  file = base::file.path(
    path_output,
    "slide_10_temporal_pipeline.png"
  ),
  device = ragg::agg_png
)

#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Variance decomposition triangle figure
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


#----------------------------------------------------------#
# 1. Component colours -----
#----------------------------------------------------------#

vec_component_colours <-
  base::c(
    "Space" = vec_oracle_palette[["cyan"]],
    "Climate" = vec_oracle_palette[["amber"]],
    "Latent" = vec_oracle_palette[["purple"]]
  )

vec_component_labels <-
  base::c(
    "SPACE",
    "CLIMATE",
    "LATENT\nASSOCIATION"
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_variance_decomposition_triangle <-
  plot_variance_component_triangle_legend(
    vec_component_colours = vec_component_colours,
    vec_required_components = base::c(
      "Space",
      "Climate",
      "Latent"
    ),
    vec_component_labels = vec_component_labels,
    max_component_value = 100,
    component_step = 1,
    font_family = font_family,
    label_colour = vec_component_colours,
    title_colour = vec_oracle_palette[["phosphor"]],
    border_colour = vec_oracle_palette[["border"]],
    background_colour = vec_oracle_palette[["background"]],
    point_size = 3.2,
    label_size = 4.6,
    triangle_x_offset = 0.16,
    method = "perc_avg"
  ) +
  ggview::canvas(
    width = 750,
    height = 620,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::theme(
    plot.margin = ggplot2::margin(
      t = 24,
      r = 24,
      b = 28,
      l = 24
    )
  )


#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_variance_decomposition_triangle,
  file = base::file.path(
    path_output,
    "slide_06_variance_decomposition.png"
  ),
  device = ragg::agg_png
)

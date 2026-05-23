#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#          Generate IAVS 2026 Story Figures
#
#                   O. Mottl
#                    2026
#
#----------------------------------------------------------#

# This script is a test to generates a story figure for the IAVS 2026 presentation.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

path_presentation_relative <-
  "Documentation/Presentations/IAVS_2026"

here::i_am(
  stringr::str_c(
    path_presentation_relative,
    "/R/generate_story_figures.R"
  )
)

path_presentation <-
  here::here(path_presentation_relative)

source(
  here::here(
    "R",
    "Functions",
    "Presentation",
    "IAVS",
    "oracle_palette_values.R"
  )
)

source(
  here::here(
    "R",
    "Functions",
    "Presentation",
    "IAVS",
    "base_terminal_plot.R"
  )
)

source(
  here::here(
    "R",
    "Functions",
    "Presentation",
    "IAVS",
    "add_panel.R"
  )
)

path_assets <-
  stringr::str_c(path_presentation, "/assets")

path_story_figures <-
  stringr::str_c(path_presentation, "/figures/story")

base::dir.create(
  path = path_assets,
  recursive = TRUE,
  showWarnings = FALSE
)

base::dir.create(
  path = path_story_figures,
  recursive = TRUE,
  showWarnings = FALSE
)

vec_palette <-
  oracle_palette_values()

vec_plot_dimensions <-
  c(
    x_min = 0,
    x_max = 100,
    y_min = 0,
    y_max = 100 * (9 / 16)
  )
  
border_buffer <- 2

#----------------------------------------------------------#
# 1. Hidden majority particles -----
#----------------------------------------------------------#

make_data_hidden <- function() {
  base::set.seed(900723)

  center_x <- 50
  center_y <- 28
  x_radius <- 34
  y_radius <- 23

  data_dust <-
    tibble::tibble(
      angle = stats::runif(650L, min = 0, max = 2 * base::pi),
      radius = base::sqrt(stats::runif(650L, min = 0, max = 1))
    ) |>
    dplyr::mutate(
      x = center_x + base::cos(angle) * radius * x_radius,
      y = center_y + base::sin(angle) * radius * y_radius,
      x = x + stats::rnorm(dplyr::n(), sd = 0.35),
      y = y + stats::rnorm(dplyr::n(), sd = 0.28),
      alpha = stats::runif(dplyr::n(), min = 0.04, max = 0.18),
      size = stats::runif(dplyr::n(), min = 0.10, max = 0.30)
    )

  points_per_arm <- 850L

  data_spiral <-
    tibble::tibble(
      arm = base::rep(0:3, each = points_per_arm),
      index = base::rep(base::seq_len(points_per_arm), times = 4L)
    ) |>
    dplyr::mutate(
      fraction = (index - 1) / (points_per_arm - 1),
      angle_base = 0.30 + fraction * 1.62 * base::pi,
      angle = angle_base + arm * base::pi / 2,
      angle = angle + base::sin(fraction * 7 * base::pi) * 0.07,
      radius = 0.13 + 0.78 * fraction,
      thickness = 0.025 + 0.070 * fraction,
      radius = radius + stats::rnorm(dplyr::n(), sd = thickness),
      angle = angle + stats::rnorm(dplyr::n(), sd = 0.030),
      x = center_x + base::cos(angle) * radius * x_radius,
      y = center_y + base::sin(angle) * radius * y_radius,
      x = x + stats::rnorm(dplyr::n(), sd = 0.35 + fraction * 0.75),
      y = y + stats::rnorm(dplyr::n(), sd = 0.24 + fraction * 0.45),
      lower_cloud = y < center_y - 5 & fraction > 0.45,
      alpha = stats::runif(dplyr::n(), min = 0.10, max = 0.54),
      alpha = dplyr::if_else(lower_cloud, alpha + 0.28, alpha),
      size = stats::runif(dplyr::n(), min = 0.13, max = 0.62)
    ) |>
    dplyr::filter(dplyr::between(x, 7, 91), dplyr::between(y, 6, 50))

  data_hidden_cloud <-
    tibble::tibble(
      angle = stats::rnorm(1250L, mean = 1.52 * base::pi, sd = 0.34),
      radius = stats::rbeta(1250L, shape1 = 9.5, shape2 = 2.2)
    ) |>
    dplyr::mutate(
      x = center_x + base::cos(angle) * radius * x_radius,
      y = center_y + base::sin(angle) * radius * y_radius,
      y = y + base::sin((x - 17) / 8) * 1.8,
      x = x + stats::rnorm(dplyr::n(), sd = 1.00),
      y = y + stats::rnorm(dplyr::n(), sd = 0.58),
      alpha = stats::runif(dplyr::n(), min = 0.26, max = 0.92),
      size = stats::runif(dplyr::n(), min = 0.18, max = 0.78)
    ) |>
    dplyr::filter(dplyr::between(x, 12, 82), dplyr::between(y, 7, 31))

  data_core <-
    tibble::tibble(
      angle = stats::runif(420L, min = 0, max = 2 * base::pi),
      radius = stats::rbeta(420L, shape1 = 0.75, shape2 = 9.0)
    ) |>
    dplyr::mutate(
      x = center_x + base::cos(angle) * radius * 8.5,
      y = center_y + base::sin(angle) * radius * 6.0,
      alpha = stats::runif(dplyr::n(), min = 0.42, max = 1.00),
      size = stats::runif(dplyr::n(), min = 0.20, max = 1.35)
    )

  data_knot_centers <-
    tibble::tibble(
      knot_id = base::seq_len(34L),
      arm = base::sample(0:3, size = 34L, replace = TRUE),
      fraction = stats::runif(34L, min = 0.28, max = 0.97)
    ) |>
    dplyr::mutate(
      angle = 0.30 + fraction * 1.62 * base::pi,
      angle = angle + arm * base::pi / 2,
      angle = angle + base::sin(fraction * 7 * base::pi) * 0.07,
      radius = 0.13 + 0.78 * fraction,
      x = center_x + base::cos(angle) * radius * x_radius,
      y = center_y + base::sin(angle) * radius * y_radius,
      group = dplyr::case_when(
        angle %% (2 * base::pi) < 0.75 ~ "observed",
        y < 22 & x > 54 ~ "hidden",
        TRUE ~ "signal"
      ),
      alpha = stats::runif(dplyr::n(), min = 0.65, max = 1.00),
      size = stats::runif(dplyr::n(), min = 0.80, max = 1.75)
    )

  data_knot_cloud <-
    tibble::tibble(
      knot_id = base::rep(data_knot_centers[["knot_id"]], each = 30L),
      offset_x = stats::rnorm(34L * 30L, sd = 0.90),
      offset_y = stats::rnorm(34L * 30L, sd = 0.55)
    ) |>
    dplyr::left_join(
      data_knot_centers |>
        dplyr::select(knot_id, x_center = x, y_center = y, group),
      by = dplyr::join_by(knot_id)
    ) |>
    dplyr::mutate(
      x = x_center + offset_x,
      y = y_center + offset_y,
      alpha = stats::runif(dplyr::n(), min = 0.16, max = 0.76),
      size = stats::runif(dplyr::n(), min = 0.12, max = 0.52)
    )

  data_radar_arcs <-
    tibble::tibble(
      arc_id = base::seq_len(5L),
      radius = base::c(0.20, 0.34, 0.48, 0.62, 0.76),
      angle_min = base::c(0.10, 1.10, 2.05, 3.05, 4.25),
      angle_max = base::c(0.95, 1.85, 2.85, 3.95, 5.65)
    ) |>
    dplyr::slice(base::rep(dplyr::row_number(), each = 2L)) |>
    dplyr::mutate(
      arc_id = dplyr::row_number(),
      angle_min = angle_min + base::rep(c(0, base::pi), 5L),
      angle_max = angle_max + base::rep(c(0, base::pi), 5L)
    ) |>
    dplyr::reframe(
      angle = base::seq(angle_min, angle_max, length.out = 90L),
      x = center_x + base::cos(angle) * radius * x_radius,
      y = center_y + base::sin(angle) * radius * y_radius,
      .by = arc_id
    )

  data_radar_spokes <-
    tibble::tibble(
      angle = base::seq(0, 1.75 * base::pi, by = base::pi / 4),
      x = center_x,
      y = center_y,
      xend = center_x + base::cos(angle) * x_radius,
      yend = center_y + base::sin(angle) * y_radius
    )

  base::list(
    dust = data_dust,
    spiral = data_spiral,
    hidden_cloud = data_hidden_cloud,
    core = data_core,
    knot_centers = data_knot_centers,
    knot_cloud = data_knot_cloud,
    radar_arcs = data_radar_arcs,
    radar_spokes = data_radar_spokes
  )
}

list_hidden_data <-
  make_data_hidden()

plot_hidden <-
  base_terminal_plot(
    title = "01 | PROBLEM: THE HIDDEN MAJORITY",
    prompt = ">CONCEPTUAL / SYNTHETIC SIGNAL FIELD"
  ) +
  ggplot2::geom_point(
    data = list_hidden_data[["dust"]],
    mapping = ggplot2::aes(x = x, y = y),
    colour = vec_palette[["border"]],
    size = list_hidden_data[["dust"]] |>
      dplyr::pull(size),
    alpha = list_hidden_data[["dust"]] |>
      dplyr::pull(alpha),
    shape = 15
  ) +
  ggplot2::geom_point(
    data = list_hidden_data[["spiral"]],
    mapping = ggplot2::aes(x = x, y = y),
    colour = vec_palette[["phosphor"]],
    size = list_hidden_data[["spiral"]] |>
      dplyr::pull(size),
    alpha = list_hidden_data[["spiral"]] |>
      dplyr::pull(alpha),
    shape = 15
  ) +
  ggplot2::geom_point(
    data = list_hidden_data[["knot_cloud"]],
    mapping = ggplot2::aes(x = x, y = y),
    colour = vec_palette[["text"]],
    size = list_hidden_data[["knot_cloud"]] |>
      dplyr::pull(size),
    alpha = list_hidden_data[["knot_cloud"]] |>
      dplyr::pull(alpha),
    shape = 15
  ) +
   ggplot2::geom_point(
     data = list_hidden_data[["hidden_cloud"]],
     mapping = ggplot2::aes(x = x, y = y),
     colour = vec_palette[["phosphor"]],
     size = list_hidden_data[["hidden_cloud"]] |>
       dplyr::pull(size),
     alpha = list_hidden_data[["hidden_cloud"]] |>
       dplyr::pull(alpha),
     shape = 15
   ) +
  ggplot2::geom_point(
    data = list_hidden_data[["core"]],
    mapping = ggplot2::aes(x = x, y = y),
    colour = vec_palette[["text"]],
    size = list_hidden_data[["core"]] |>
      dplyr::pull(size),
    alpha = list_hidden_data[["core"]] |>
      dplyr::pull(alpha),
    shape = 15
  ) +
  ggplot2::geom_point(
    data = list_hidden_data[["knot_centers"]],
    mapping = ggplot2::aes(x = x, y = y, colour = group),
    size = list_hidden_data[["knot_centers"]] |>
      dplyr::pull(size),
    alpha = list_hidden_data[["knot_centers"]] |>
      dplyr::pull(alpha),
    shape = 15
  ) +
  ggplot2::scale_colour_manual(
    values = base::c(
      hidden = vec_palette[["amber"]],
      observed = vec_palette[["cyan"]],
      signal = vec_palette[["phosphor"]]
    )
  ) +
    ggplot2::geom_path(
    data = list_hidden_data[["radar_arcs"]],
    mapping = ggplot2::aes(x = x, y = y, group = arc_id),
    colour = vec_palette[["border"]],
    linewidth = 0.28,
    alpha = 0.52
  ) +
  ggplot2::geom_segment(
    data = list_hidden_data[["radar_spokes"]],
    mapping = ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
    colour = vec_palette[["border"]],
    linewidth = 0.28,
    alpha = 0.52
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = vec_plot_dimensions["x_min"] + border_buffer,
      xend = vec_plot_dimensions["x_max"] - border_buffer,
      y = (vec_plot_dimensions["y_max"] - border_buffer  + 
        vec_plot_dimensions["y_min"] + border_buffer) /2 ,
      yend = (vec_plot_dimensions["y_max"] - border_buffer  + 
        vec_plot_dimensions["y_min"] + border_buffer) /2 
    ),
    colour = vec_palette[["phosphor"]],
    linewidth = 0.017,
    alpha = 0.52
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = (vec_plot_dimensions["x_max"] - border_buffer  + 
        vec_plot_dimensions["x_min"] + border_buffer) /2 ,
      xend = (vec_plot_dimensions["x_max"] - border_buffer  + 
        vec_plot_dimensions["x_min"] + border_buffer) /2 ,
      y = vec_plot_dimensions["y_min"] + border_buffer,
      yend = vec_plot_dimensions["y_max"] - border_buffer
    ),
    colour = vec_palette[["phosphor"]],
    linewidth = 0.017,
    alpha = 0.52
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(x = 78, xend = 71, y = 47, yend = 42),
    colour = vec_palette[["cyan"]],
    linewidth = 0.42,
    alpha = 0.95
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(x = 80, xend = 70, y = 14, yend = 22),
    colour = vec_palette[["amber"]],
    linewidth = 0.42,
    alpha = 0.95
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 79,
    y = 48,
    label = "OBSERVED",
    hjust = 0,
    colour = vec_palette[["cyan"]],
    family = "mono",
    fontface = "bold",
    size = 4.0
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 81,
    y = 12,
    label = "HIDDEN",
    hjust = 0,
    colour = vec_palette[["amber"]],
    family = "mono",
    fontface = "bold",
    size = 4.0
  ) 

ggview::save_ggplot(
  plot = plot_hidden,
  file = stringr::str_c(
    path_story_figures,
    "/hidden_majority_particles.png"
  )
)
cli::cli_alert_success(
  "Story figures saved to {.path {path_story_figures}}."
)

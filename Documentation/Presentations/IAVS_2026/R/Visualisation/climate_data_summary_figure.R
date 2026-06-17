#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Community and climate preparation schematic figure
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

font_family <- vec_font_match[1, 2]

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
# 1. Current pipeline overview -----
#----------------------------------------------------------#

# The methods section still captures the broad logic, but the active
#   pipelines are now more explicit than the manuscript prose.
#
# Current paleo pipeline steps used for this schematic:
#
# 1. VegVault extraction
#    - Extract fossil pollen archive records in the configured
#      geographic and temporal window.
#    - Extract community data, coordinates, sample ages, and abiotic
#      values as separate targets.
#
# 2. Community stream
#    - Convert raw community tables to long format and add sample ages.
#    - Build a taxon vector and classify taxa with automated GBIF
#      backbone lookup.
#    - Merge automated classifications with the auxiliary manual
#      classification table.
#    - Export any still-missing taxa to a template and fail early if
#      classification is incomplete.
#    - Convert counts to proportions.
#    - Extract age-model uncertainty from VegVault and use it during
#      dataset-level interpolation to the configured time step.
#    - Remove non-Plantae records and classify retained community
#      rows to the configured taxonomic resolution.
#    - Filter rare taxa, taxa in too few cores, taxa in too few
#      samples, and optionally select the configured number of taxa.
#
# 3. Climate stream
#    - Extract abiotic data from VegVault and add sample ages.
#    - Run collinearity screening on wide predictor data after dropping
#      the age column and zero-variance predictors.
#    - Keep only the non-collinear predictor selection returned by
#      collinear::collinear().
#    - Interpolate selected predictors to the same configured time
#      step as the community stream.
#
# 4. Model-ready matrices
#    - Widen the community data to a sample x taxon matrix.
#    - Widen abiotic data to sample rows and predictor columns.
#    - Scale abiotic predictors before model assembly.
#    - For binomial models, binarize the community response and remove
#      constant taxa before checking the minimum retained taxon count.


#----------------------------------------------------------#
# 2. Data for schematic -----
#----------------------------------------------------------#

colour_community <-
  vec_oracle_palette[["phosphor"]]

colour_climate <-
  vec_oracle_palette[["amber"]]

colour_shared <-
  vec_oracle_palette[["muted"]]

colour_model <-
  vec_oracle_palette[["purple"]]


x_lims <- c(0, 900)
y_lims <- c(0, 850)

x_centre <- mean(x_lims)
y_centre <- mean(y_lims)

y_source_box <- 800
y_data_type <- 520
y_data_sub <- base::seq(690, 300, by = -112)
y_shared <- c(125, 230)
y_model <- 50

data_source_box <-
  node_box(
    id = "source",
    label = "VegVault",
    x = x_centre,
    y = y_source_box,
    width = 180,
    height = 70,
    colour = colour_shared,
    text_colour = colour_shared,
    text_size = 3.1
  )

data_type_box <-
  dplyr::bind_rows(
    node_box(
      id = "community_stream",
      label = "COMMUNITY DATA",
      colour = colour_community,
      width = 350,
      height = 450,
      x = x_centre - (x_centre / 2),
      y = y_data_type
    ),
    node_box(
      id = "climate_stream",
      label = "ABCIOTIC DATA",
        colour = colour_climate,
      width = 350,
      height = 450,
      x = x_centre + (x_centre / 2),
      y = y_data_type
    )
  ) 

data_community_boxes <-
  dplyr::bind_rows(
    node_box(
      id = "community_counts",
      label = "counts\nto proportions",
      x = x_centre - (x_centre / 2),
      y = y_data_sub[1],
      width = 200,
      height = 78,
      colour = colour_community,
      text_size = 2.95
    ),
    node_box(
      id = "community_age",
      label = "interpolate\nwith uncertainty",
      x = x_centre - (x_centre / 2),
      y = y_data_sub[2],
      width = 240,
      height = 84,
      colour = colour_community,
      text_size = 2.85
    ),
    node_box(
      id = "community_taxa",
      label = "taxonomy\nharmonisation",
      x = x_centre - (x_centre / 2),
      y = y_data_sub[3],
      width = 210,
      height = 82,
      colour = colour_community,
      text_size = 2.85
    ),
    node_box(
      id = "community_resolution",
      label = "select\nresolution",
      x = x_centre - (x_centre / 2),
      y = y_data_sub[4],
      width = 170,
      height = 78,
      colour = colour_community,
      text_size = 2.85
    )
  )

data_climate_boxes <-
  dplyr::bind_rows(
    node_box(
      id = "climate_candidates",
      label = "CHELSA\ncandidates",
      x = x_centre + (x_centre / 2),
      y = y_data_sub[1],
      width = 200,
      height = 78,
      colour = colour_climate,
      text_colour = colour_climate,
      text_size = 2.95
    ),
    node_box(
      id = "climate_variance",
      label = "drop invariant\npredictors",
      x = x_centre + (x_centre / 2),
      y = y_data_sub[2],
      width = 220,
      height = 82,
      colour = colour_climate,
      text_colour = colour_climate,
      text_size = 2.85
    ),
    node_box(
      id = "climate_screen",
      label = "select\nnon-collinear set",
      x = x_centre + (x_centre / 2),
      y = y_data_sub[3],
      width = 270,
      height = 82,
      colour = colour_climate,
      text_colour = colour_climate,
      text_size = 2.75
    ),
    node_box(
      id = "climate_grid",
      label = "interpolate",
      x = x_centre + (x_centre / 2),
      y = y_data_sub[4],
      width = 170,
      height = 78,
      colour = colour_climate,
      text_colour = colour_climate,
      text_size = 2.9
    )
  )

data_shared_boxes <-
  dplyr::bind_rows(
    node_box(
      id = "sample_filtering",
      label = "Sample filtering\nspatial/temporal",
      x = x_centre,
      y = y_shared[2],
      width = 250,
      height = 82,
      colour = colour_shared,
      text_colour = colour_shared,
      text_size = 2.85
    ),
    node_box(
      id = "core_filtering",
      label = "Core filtering",
      x = x_centre,
      y = y_shared[1],
      width = 200,
      height = 52,
      colour = colour_shared,
      text_colour = colour_shared,
      text_size = 2.85
    )
  )

data_model_box <-
  node_box(
    id = "model",
    label = "Model",
    x = x_centre,
    y = y_model,
    width = 120,
    height = 45,
    colour = colour_model,
    text_colour = colour_model,
    text_size = 2.95
  )

data_node_boxes <-
  dplyr::bind_rows(
    data_source_box,
    data_community_boxes,
    data_climate_boxes,
    data_shared_boxes,
    data_model_box
  ) |>
  dplyr::mutate(
    text_size = text_size * 0.8
  )

data_links_type <- 
  dplyr::bind_rows(
    data_community_boxes |> dplyr::mutate(stream = "community"),
    data_climate_boxes |> dplyr::mutate(stream = "climate")
  ) |>
  dplyr::group_by(stream) |>
  dplyr::arrange(y) |>
  dplyr::mutate(
    yend = dplyr::lead(ymin),
    xend = x
  ) |>
  dplyr::filter(!base::is.na(yend))  |>
  dplyr::ungroup()  |> 
  dplyr::select(x, y, xend, yend, colour)

#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

figure_climate_data_summary <-
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = x_lims,
    ylim = y_lims,
    expand = FALSE,
    clip = "off"
  ) +
  ggview::canvas(
    width = 900,
    height = 850,
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
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    legend.position = "none",
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  ) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_fill_identity() +
  ggplot2::scale_size_identity() +
  ggplot2::scale_alpha_identity() +
  # stream frames
  ggplot2::geom_rect(
    data = data_type_box,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      colour = colour
    ),
    fill = vec_oracle_palette[["background"]],
    linewidth = 0.55,
    alpha = 0.82
  ) +
  # data boxes titles
  ggplot2::geom_text(
    mapping = ggplot2::aes(
      x = c(
        x_centre - (x_centre / 2),
        x_centre + (x_centre / 2)
      ),
      y = y_data_type + 245,
      label = c(
        "COMMUNITY DATA",
        "ABIOTIC DATA"
      ),
      colour = c(
        colour_community,
        colour_climate
    )),
    family = font_family,
    fontface = "bold",
    lineheight = 0.86,
    size = 3.0
  ) +
  # curved links between streams and shared nodes
  # vegvault to community
   ggplot2::geom_curve(
     mapping = ggplot2::aes(
       x = data_source_box$xmin,
       xend = data_type_box  |> 
       dplyr::filter(id == "community_stream") |>
       dplyr::pull(x),
       y = data_source_box$y,
       yend = data_type_box  |>
       dplyr::filter(id == "community_stream") |>
       dplyr::pull(ymax)
     ),
     colour = colour_shared,
     alpha = 0.5,
     curvature = 0.18,
     linewidth = 0.45
   ) +
  # vegvault to climate
    ggplot2::geom_curve(
      mapping = ggplot2::aes(
        x = data_source_box$xmax,
        xend = data_type_box  |> 
        dplyr::filter(id == "climate_stream") |>
        dplyr::pull(x),
        y = data_source_box$y,
        yend = data_type_box  |>
        dplyr::filter(id == "climate_stream") |>
        dplyr::pull(ymax)
      ),
      colour = colour_shared,
      alpha = 0.5,
      curvature = -0.18,
      linewidth = 0.45
    ) +
  # community to shared
    ggplot2::geom_curve(
      mapping = ggplot2::aes(
        x = data_type_box  |> 
        dplyr::filter(id == "community_stream") |>
        dplyr::pull(x),
        xend = data_shared_boxes |>
        dplyr::filter(id == "sample_filtering") |>
        dplyr::pull(xmin),
        y = data_type_box  |>
        dplyr::filter(id == "community_stream") |>
        dplyr::pull(ymin),
        yend = data_shared_boxes |>
        dplyr::filter(id == "sample_filtering") |>
        dplyr::pull(y)
      ),
      colour = colour_shared,
      alpha = 0.5,
      curvature = 0.22,
      linewidth = 0.45
    ) +
  # climate to shared
    ggplot2::geom_curve(
      mapping = ggplot2::aes(
        x = data_type_box  |>
        dplyr::filter(id == "climate_stream") |>
        dplyr::pull(x),
        xend = data_shared_boxes |>
        dplyr::filter(id == "sample_filtering") |>
        dplyr::pull(xmax),
        y = data_type_box  |>
        dplyr::filter(id == "climate_stream") |>
        dplyr::pull(ymin),
        yend = data_shared_boxes |>
        dplyr::filter(id == "sample_filtering") |>
        dplyr::pull(y)
      ),
      colour = colour_shared,
      alpha = 0.5,
      curvature = -0.22,
      linewidth = 0.45
    ) +
  # Now links within streams
  ggplot2::geom_segment(
    data = data_links_type,
    mapping = ggplot2::aes(
      x = x,
      y = y,
      xend = xend,
      yend = yend,
      colour = colour
    ),
    linewidth = 0.45,
    alpha = 0.5
  ) +
  # shared links
   ggplot2::geom_segment(
     mapping = ggplot2::aes(
       x = x_centre,
       y = c(
         data_shared_boxes |> 
       dplyr::filter(id == "sample_filtering") |> 
       dplyr::pull(ymin),
        data_shared_boxes |> 
       dplyr::filter(id == "core_filtering") |> 
       dplyr::pull(ymin)
       ),
       xend = x_centre,
       yend = c(
        data_shared_boxes |> 
       dplyr::filter(id == "core_filtering") |> 
       dplyr::pull(ymax),
       data_model_box$ymax
       )
     ),
     colour = colour_shared,
     linewidth = 0.45,
     alpha = 0.5
   ) +
  # process nodes
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
  # node labels
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
    family = font_family,
    show.legend = FALSE
  ) 

#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_climate_data_summary,
  file = base::file.path(
    path_output,
    "slide_05_climate_screening.png"
  ),
  device = ragg::agg_png
)

#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Community and climate preparation schematic figure
#
#----------------------------------------------------------#

# This script is actually not used in the end as it is easier to replace 
#  mermaid diagrams

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

path_output_panels <-
  base::file.path(
    path_output,
    "panels"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_output_panels,
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
# 4. Stream alignment
#    - Intersect community, abiotic, and coordinate records by
#      dataset_name and age.
#    - Require complete abiotic records across retained predictors.
#    - Fail early when too few aligned samples remain.
#
# 5. Model-ready matrices
#    - Widen the community data to a sample x taxon matrix.
#    - Widen abiotic data to sample rows and predictor columns.
#    - Scale abiotic predictors before model assembly.
#    - For binomial models, binarize the community response and remove
#      constant taxa before checking the minimum retained taxon count.


#----------------------------------------------------------#
# 2. Data for schematic -----
#----------------------------------------------------------#

colour_community <- vec_oracle_palette[["phosphor"]]
colour_climate <- vec_oracle_palette[["amber"]]
colour_model <- vec_oracle_palette[["purple"]]

data_stage_boxes <-
  tibble::tibble(
    stage_id = base::c(
      "source",
      "community",
      "climate",
      "model"
    ),
    label = base::c(
      "EXTRACT",
      "COMMUNITY STREAM",
      "CLIMATE STREAM",
      "MODEL"
    ),
    detail = base::c(
      "VegVault\nrecords",
      "counts -> proportions\nage uncertainty -> 500 yr grid\nGBIF + aux taxonomy\nPlantae + resolution\nrare/core/sample filters",
      "CHELSA BIO candidates\nadd sample ages\ndrop zero-variance vars\nselect non-collinear set\ninterpolate to 500 yr grid",
      "jSDM\ninput"
    ),
    xmin = base::c(4, 25, 25, 84),
    xmax = base::c(18, 68, 68, 96),
    ymin = base::c(31, 52, 6, 31),
    ymax = base::c(49, 75, 31, 49),
    colour = base::c(
      vec_oracle_palette[["muted"]],
      colour_community,
      colour_climate,
      colour_model
    )
  ) |>
  dplyr::mutate(
    x = (xmin + xmax) / 2,
    y_label = dplyr::case_when(
      stage_id %in% base::c("source", "model") ~ ymax - 6,
      TRUE ~ ymax - 6
    ),
    y_detail = dplyr::case_when(
      stage_id %in% base::c("source", "model") ~ ymin + 7,
      TRUE ~ ymin + 11
    )
  )

data_stream_links <-
  tibble::tibble(
    x = base::c(18, 18, 68, 68),
    xend = base::c(25, 25, 84, 84),
    y = base::c(40, 40, 63.5, 18.5),
    yend = base::c(63.5, 18.5, 42, 40),
    colour = base::c(
      colour_community,
      colour_climate,
      colour_community,
      colour_climate
    )
  )

data_panel_headers <-
  tibble::tibble(
    label = "UPDATED PREPROCESSING MAP",
    x = 4,
    y = 78,
    hjust = 0,
    colour = vec_oracle_palette[["phosphor"]]
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

figure_climate_data_summary <-
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = base::c(0, 100),
    ylim = base::c(0, 80),
    expand = FALSE,
    clip = "off"
  ) +
  ggview::canvas(
    width = 1000,
    height = 800,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  theme_oracle(base_family = font_family, base_size = 10) +
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
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    legend.position = "none",
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  ) +
  ggplot2::geom_rect(
    mapping = ggplot2::aes(
      xmin = 2,
      xmax = 98,
      ymin = 2,
      ymax = 78
    ),
    fill = vec_oracle_palette[["surface"]],
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.25,
    alpha = 0.45
  ) +
  ggplot2::geom_segment(
    data = data_stream_links,
    mapping = ggplot2::aes(
      x = x,
      xend = xend,
      y = y,
      yend = yend,
      colour = colour
    ),
    arrow = grid::arrow(
      length = grid::unit(4, "pt"),
      type = "closed"
    ),
    linewidth = 0.45,
    alpha = 0.78
  ) +
  ggplot2::scale_colour_identity() +
  ggplot2::geom_rect(
    data = data_stage_boxes,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      colour = colour
    ),
    fill = vec_oracle_palette[["surface_alt"]],
    linewidth = 0.35,
    alpha = 0.78
  ) +
  ggplot2::geom_text(
    data = data_panel_headers,
    mapping = ggplot2::aes(
      x = x,
      y = y,
      label = label,
      colour = colour,
      hjust = hjust
    ),
    family = font_family,
    fontface = "bold",
    size = 2.9
  ) +
  ggplot2::geom_text(
    data = data_stage_boxes,
    mapping = ggplot2::aes(
      x = x,
      y = y_label,
      label = label,
      colour = colour
    ),
    family = font_family,
    fontface = "bold",
    size = 2.5
  ) +
  ggplot2::geom_text(
    data = data_stage_boxes,
    mapping = ggplot2::aes(
      x = x,
      y = y_detail,
      label = detail
    ),
    lineheight = 0.82,
    colour = vec_oracle_palette[["text"]],
    family = font_family,
    size = 1.85
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 4,
    y = 4.8,
    label = "Current code: paleo spatial + temporal pipelines",
    hjust = 0,
    colour = vec_oracle_palette[["muted"]],
    family = font_family,
    size = 1.75
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

ggview::save_ggplot(
  plot = figure_climate_data_summary,
  file = base::file.path(
    path_output_panels,
    "slide_05_climate_screening.png"
  ),
  device = ragg::agg_png
)

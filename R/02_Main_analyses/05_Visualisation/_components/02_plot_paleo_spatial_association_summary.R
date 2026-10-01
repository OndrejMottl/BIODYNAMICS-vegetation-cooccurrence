#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Plot paleo spatial association distributions
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Replaces the categorical waffle with a distribution-aware manuscript
# figure. Every point is one fitted spatial unit; medians, interquartile
# ranges, and eligible-unit counts summarize each tier and resolution.
# Workflow contract:
#   Run after paleo spatial synthesis publishes unit-level association data.
#   Reads and validates plot-ready tables without opening target stores.
#   Writes one dated summary as PDF, TIFF, and PNG plus its exact CSV data.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output_figures <-
  here::here("Outputs/Figures/Spatial")
path_output_tables <-
  here::here("Outputs/Tables/Visualisation")
base::dir.create(
  path = path_output_figures,
  showWarnings = FALSE,
  recursive = TRUE
)
base::dir.create(
  path = path_output_tables,
  showWarnings = FALSE,
  recursive = TRUE
)

graphical_options <-
  load_active_config_value("graphical")
config_manuscript <-
  resolve_manuscript_graphical_options(graphical_options)
tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Load and prepare synthesis data -----
#----------------------------------------------------------#

file_paleo_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_patterns_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
data_paleo_unit <-
  readr::read_csv(
    file_paleo_unit,
    show_col_types = FALSE
  )

vec_resolution_labels <-
  base::c(
    genus = "Genus",
    family = "Family",
    functional_type = "Functional type"
  )

data_association_unit <-
  prepare_spatial_variance_plot_data(
    data_unit = data_paleo_unit,
    vec_scale_levels = base::c("continental", "regional", "local"),
    vec_resolution_labels = vec_resolution_labels,
    percentage_source_column = "R2_Nagelkerke_percentage",
    scale_source_to_percentage = FALSE
  ) |>
  dplyr::filter(
    .data$component == "Associations",
    base::is.finite(.data$component_total_percentage)
  ) |>
  dplyr::mutate(
    continent_id = base::factor(
      .data$continent_id,
      levels = base::c("america", "europe", "asia")
    )
  )

data_association_summary <-
  data_association_unit |>
  dplyr::group_by(
    .data$scale,
    .data$resolution_label
  ) |>
  dplyr::summarise(
    median = stats::median(.data$component_total_percentage),
    lwr = stats::quantile(
      .data$component_total_percentage,
      probs = 0.25,
      names = FALSE
    ),
    upr = stats::quantile(
      .data$component_total_percentage,
      probs = 0.75,
      names = FALSE
    ),
    n_units = dplyr::n_distinct(.data$scale_id),
    .groups = "drop"
  )

validate_manuscript_plot_data(
  data_plot = data_association_unit,
  required_columns = base::c(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "component_total_percentage"
  ),
  numeric_bounds = base::list(
    component_total_percentage = base::c(0, 100)
  )
)

readr::write_csv(
  data_association_unit,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_spatial_association_summary_unit_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_association_summary,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_spatial_association_summary_group_{tag_date}.csv"
    )
  )
)


#----------------------------------------------------------#
# 2. Build figure -----
#----------------------------------------------------------#

vec_continent_colours <-
  build_manuscript_palette("continent")
vec_continent_shapes <-
  base::c(america = 21, europe = 22, asia = 24)

fig_paleo_association_summary <-
  data_association_unit |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$scale,
      y = .data$component_total_percentage
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$resolution_label),
    nrow = 1L
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 105),
    breaks = base::seq(0, 100, by = 20),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_fill_manual(
    values = vec_continent_colours,
    name = "Continent"
  ) +
  ggplot2::scale_shape_manual(
    values = vec_continent_shapes,
    name = "Continent"
  ) +
  ggplot2::labs(
    x = "Spatial tier",
    y = "Variance attributed to associations"
  ) +
  build_manuscript_theme() +
  ggplot2::theme(
    panel.grid.major.x = ggplot2::element_blank(),
    legend.position = "top"
  ) +
  ggview::canvas(
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_violin(
    mapping = ggplot2::aes(group = .data$scale),
    fill = "grey88",
    colour = NA,
    width = 0.72,
    scale = "width",
    trim = TRUE
  ) +
  ggplot2::geom_jitter(
    mapping = ggplot2::aes(
      fill = .data$continent_id,
      shape = .data$continent_id
    ),
    position = ggplot2::position_jitter(
      width = 0.13,
      height = 0,
      seed = 900723
    ),
    colour = "white",
    stroke = 0.25,
    size = 1.5,
    alpha = 0.7
  ) +
  ggplot2::geom_linerange(
    data = data_association_summary,
    mapping = ggplot2::aes(
      x = .data$scale,
      ymin = .data$lwr,
      ymax = .data$upr
    ),
    colour = "grey10",
    linewidth = 0.75,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_point(
    data = data_association_summary,
    mapping = ggplot2::aes(
      x = .data$scale,
      y = .data$median
    ),
    shape = 95,
    size = 6,
    colour = "grey10",
    inherit.aes = FALSE
  ) +
  ggplot2::geom_text(
    data = data_association_summary,
    mapping = ggplot2::aes(
      x = .data$scale,
      y = 102,
      label = stringr::str_glue("n = {n_units}")
    ),
    size = 2.4,
    colour = "grey30",
    inherit.aes = FALSE
  )


#----------------------------------------------------------#
# 3. Save manuscript outputs -----
#----------------------------------------------------------#

file_figure_base <-
  base::file.path(
    path_output_figures,
    stringr::str_glue(
      "paleo_spatial_association_summary_{tag_date}"
    )
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_paleo_association_summary,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved paleo association summary: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

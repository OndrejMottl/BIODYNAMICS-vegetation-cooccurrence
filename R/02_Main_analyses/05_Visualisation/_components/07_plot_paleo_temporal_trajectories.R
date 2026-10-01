#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Plot paleo temporal trajectories
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Converts the IAVS trajectory logic into one static manuscript figure using
# the temporal synthesis tables. Missing time slices are inserted explicitly,
# preventing lines from bridging unsupported intervals.
# Workflow contract:
#   Run after paleo temporal synthesis publishes results and density tables.
#   Reads plot-ready tables, preserves unsupported gaps, and opens no stores.
#   Writes one dated figure as PDF, TIFF, and PNG plus its exact CSV data.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output_figures <-
  here::here("Outputs/Figures/Temporal_continents")
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
# 1. Load temporal synthesis -----
#----------------------------------------------------------#

file_temporal_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_temporal_patterns_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
file_temporal_density <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_temporal_density",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )

data_temporal_unit <-
  readr::read_csv(
    file_temporal_unit,
    show_col_types = FALSE
  )
data_temporal_density <-
  readr::read_csv(
    file_temporal_density,
    show_col_types = FALSE
  )

validate_manuscript_plot_data(
  data_plot = data_temporal_unit,
  required_columns = base::c(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "result_type",
    "series",
    "value",
    "availability_status"
  )
)
validate_manuscript_plot_data(
  data_plot = data_temporal_density,
  required_columns = base::c(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "n_samples",
    "n_locations",
    "availability_status"
  )
)


#----------------------------------------------------------#
# 2. Complete trajectories across supported slices -----
#----------------------------------------------------------#

vec_continent_levels <-
  base::c("america", "europe", "asia")
vec_component_levels <-
  base::c("Spatial", "Abiotic", "Associations")
vec_component_labels <-
  base::c(
    Spatial = "Spatial",
    Abiotic = "Climate",
    Associations = "Biotic co-occurrence"
  )

data_temporal_components_observed <-
  data_temporal_unit |>
  dplyr::filter(
    .data$result_type == "variance_component",
    .data$series %in% vec_component_levels
  ) |>
  dplyr::mutate(
    series_label = base::unname(vec_component_labels[.data$series])
  )

data_temporal_components <-
  data_temporal_density |>
  dplyr::distinct(
    .data$continent_id,
    .data$age,
    .data$availability_status
  ) |>
  tidyr::crossing(series = vec_component_levels) |>
  dplyr::left_join(
    data_temporal_components_observed |>
      dplyr::select(
        "continent_id",
        "age",
        "series",
        "value"
      ),
    by = dplyr::join_by(continent_id, age, series),
    multiple = "error"
  ) |>
  dplyr::mutate(
    series_label = base::unname(vec_component_labels[.data$series]),
    continent_id = base::factor(
      .data$continent_id,
      levels = vec_continent_levels
    )
  )

data_temporal_modularity_observed <-
  data_temporal_unit |>
  dplyr::filter(
    .data$result_type == "network_metric",
    .data$series == "modularity Q"
  ) |>
  dplyr::select(
    "continent_id",
    "age",
    modularity_q = "value"
  )
data_temporal_modularity <-
  data_temporal_density |>
  dplyr::distinct(
    .data$continent_id,
    .data$age,
    .data$availability_status
  ) |>
  dplyr::left_join(
    data_temporal_modularity_observed,
    by = dplyr::join_by(continent_id, age),
    multiple = "error"
  ) |>
  dplyr::mutate(
    continent_id = base::factor(
      .data$continent_id,
      levels = vec_continent_levels
    )
  )

data_temporal_density_plot <-
  data_temporal_density |>
  dplyr::mutate(
    continent_id = base::factor(
      .data$continent_id,
      levels = vec_continent_levels
    ),
    density_band = "Samples"
  )

readr::write_csv(
  data_temporal_components,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_temporal_trajectories_components_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_temporal_modularity,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_temporal_trajectories_modularity_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_temporal_density_plot,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_temporal_trajectories_density_{tag_date}.csv"
    )
  )
)


#----------------------------------------------------------#
# 3. Build static trajectory panels -----
#----------------------------------------------------------#

vec_component_colours <-
  build_manuscript_palette("variance_component")
vec_temporal_colours <-
  vec_component_colours[
    base::c("Spatial", "Climate", "Biotic co-occurrence")
  ]

plot_components <-
  data_temporal_components |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$age,
      y = .data$value,
      colour = .data$series_label,
      group = .data$series_label
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$continent_id),
    nrow = 1L
  ) +
  ggplot2::scale_x_reverse() +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 100),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_colour_manual(
    values = vec_temporal_colours,
    name = "Variance component"
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Variance contribution"
  ) +
  build_manuscript_theme(base_size = 8) +
  ggplot2::theme(
    legend.position = "top",
    panel.grid.minor = ggplot2::element_blank()
  ) +
  ggplot2::geom_line(
    linewidth = 0.65,
    na.rm = TRUE
  ) +
  ggplot2::geom_point(
    size = 1.1,
    na.rm = TRUE
  )

plot_modularity <-
  data_temporal_modularity |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$age,
      y = .data$modularity_q
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$continent_id),
    nrow = 1L
  ) +
  ggplot2::scale_x_reverse() +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 1)
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Network modularity Q"
  ) +
  build_manuscript_theme(base_size = 8) +
  ggplot2::theme(legend.position = "none") +
  ggplot2::geom_line(
    colour = "#009E73",
    linewidth = 0.65,
    na.rm = TRUE
  ) +
  ggplot2::geom_point(
    colour = "#009E73",
    size = 1.1,
    na.rm = TRUE
  )

plot_density <-
  data_temporal_density_plot |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$age,
      y = .data$density_band,
      fill = .data$n_samples
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$continent_id),
    nrow = 1L
  ) +
  ggplot2::scale_x_reverse() +
  ggplot2::scale_fill_viridis_c(
    option = "B",
    trans = "sqrt",
    name = "Samples"
  ) +
  ggplot2::scale_shape_manual(
    values = base::c(
      expected_infeasible = 4,
      unexpected_error = 8,
      missing_model = 1
    ),
    breaks = base::c(
      "expected_infeasible",
      "unexpected_error",
      "missing_model"
    ),
    labels = base::c(
      "Expected infeasible",
      "Unexpected model error",
      "Missing model"
    ),
    name = "Model status",
    drop = FALSE
  ) +
  ggplot2::labs(
    x = "Age (cal yr BP)",
    y = NULL
  ) +
  build_manuscript_theme(base_size = 8) +
  ggplot2::theme(
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank(),
    legend.position = "top",
    strip.text = ggplot2::element_blank(),
    strip.background = ggplot2::element_blank()
  ) +
  ggplot2::geom_tile(
    height = 0.85,
    colour = "white",
    linewidth = 0.15
  ) +
  ggplot2::geom_point(
    data = data_temporal_density_plot |>
      dplyr::filter(
        .data$availability_status != "available"
      ),
    mapping = ggplot2::aes(shape = .data$availability_status),
    colour = "grey20",
    size = 1.2,
    stroke = 0.4
  )

fig_temporal <-
  cowplot::plot_grid(
    plot_components,
    plot_modularity,
    plot_density,
    labels = base::c("A", "B", "C"),
    ncol = 1L,
    rel_heights = base::c(1.25, 1, 0.55),
    align = "v"
  ) +
  ggview::canvas(
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = graphical_options[["bg"]]
  )


#----------------------------------------------------------#
# 4. Save manuscript outputs -----
#----------------------------------------------------------#

file_figure_base <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("paleo_temporal_trajectories_{tag_date}")
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_temporal,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved paleo temporal trajectories: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

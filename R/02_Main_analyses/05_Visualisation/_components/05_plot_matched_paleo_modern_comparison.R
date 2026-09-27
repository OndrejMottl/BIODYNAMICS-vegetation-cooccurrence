#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Plot matched paleo-modern comparison
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Visualizes only matched unit-resolution pairs published by stage 04. The
# plot-data contract carries matched and excluded-unit counts so incomplete
# coverage cannot be hidden by the paired display.
# Workflow contract:
#   Run after stage 04 publishes matched, summary, and coverage tables.
#   Reads validated matched units only and never opens analytical stores.
#   Writes one dated figure as PDF, TIFF, and PNG plus its exact CSV data.


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
# 1. Load and validate matched synthesis -----
#----------------------------------------------------------#

file_comparison_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_modern_patterns_comparison_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
file_comparison_coverage <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_modern_patterns_comparison_coverage",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )

data_comparison_unit <-
  readr::read_csv(
    file_comparison_unit,
    show_col_types = FALSE
  )
data_comparison_coverage <-
  readr::read_csv(
    file_comparison_coverage,
    show_col_types = FALSE
  )

data_matched <-
  prepare_matched_paleo_modern_plot_data(
    data_comparison_unit = data_comparison_unit,
    data_comparison_coverage = data_comparison_coverage
  )

data_delta_summary <-
  data_matched |>
  dplyr::group_by(
    .data$scale,
    .data$comparison_id,
    .data$comparison_resolution
  ) |>
  dplyr::summarise(
    median = stats::median(.data$R2_delta_modern_minus_paleo),
    lwr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.025,
      names = FALSE
    ),
    upr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.975,
      names = FALSE
    ),
    n_matched_units = dplyr::first(.data$n_matched_units),
    n_paleo_unmatched = dplyr::first(.data$n_paleo_unmatched),
    n_modern_unmatched = dplyr::first(.data$n_modern_unmatched),
    .groups = "drop"
  )

readr::write_csv(
  data_matched,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_modern_matched_comparison_unit_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_delta_summary,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_modern_matched_comparison_summary_{tag_date}.csv"
    )
  )
)


#----------------------------------------------------------#
# 2. Build paired and difference panels -----
#----------------------------------------------------------#

plot_paired <-
  data_matched |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$R2_Nagelkerke_percentage_paleo,
      y = .data$R2_Nagelkerke_percentage_modern
    )
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data$scale),
    cols = ggplot2::vars(.data$comparison_resolution)
  ) +
  ggplot2::scale_x_continuous(
    limits = base::c(0, 100),
    breaks = base::seq(0, 100, by = 25),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 100),
    breaks = base::seq(0, 100, by = 25),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::labs(
    x = "Paleo association variance",
    y = "Modern association variance"
  ) +
  build_manuscript_theme(base_size = 8) +
  ggplot2::theme(legend.position = "none") +
  ggplot2::geom_abline(
    slope = 1,
    intercept = 0,
    colour = "grey55",
    linewidth = 0.4,
    linetype = 2
  ) +
  ggplot2::geom_point(
    colour = "grey15",
    fill = "white",
    shape = 21,
    size = 1.35,
    stroke = 0.35,
    alpha = 0.7
  )

plot_delta <-
  data_matched |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$comparison_resolution,
      y = .data$R2_delta_modern_minus_paleo
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$scale),
    nrow = 1L
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Modern minus paleo association variance"
  ) +
  build_manuscript_theme(base_size = 8) +
  ggplot2::theme(panel.grid.major.x = ggplot2::element_blank()) +
  ggplot2::geom_hline(
    yintercept = 0,
    colour = "grey45",
    linewidth = 0.4
  ) +
  ggplot2::geom_jitter(
    width = 0.12,
    height = 0,
    colour = "grey55",
    size = 1.1,
    alpha = 0.45
  ) +
  ggplot2::geom_linerange(
    data = data_delta_summary,
    mapping = ggplot2::aes(
      x = .data$comparison_resolution,
      ymin = .data$lwr_95,
      ymax = .data$upr_95
    ),
    colour = "#009E73",
    linewidth = 0.8,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_point(
    data = data_delta_summary,
    mapping = ggplot2::aes(
      x = .data$comparison_resolution,
      y = .data$median
    ),
    colour = "#009E73",
    shape = 95,
    size = 5.5,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_text(
    data = data_delta_summary,
    mapping = ggplot2::aes(
      x = .data$comparison_resolution,
      y = .data$upr_95,
      label = stringr::str_glue(
        "n={n_matched_units}; excluded ",
        "P={n_paleo_unmatched}, M={n_modern_unmatched}"
      )
    ),
    vjust = -0.8,
    size = 2.1,
    colour = "grey25",
    inherit.aes = FALSE
  )

fig_paleo_modern <-
  cowplot::plot_grid(
    plot_paired,
    plot_delta,
    labels = base::c("A", "B"),
    ncol = 1L,
    align = "v",
    rel_heights = base::c(1.45, 1)
  ) +
  ggview::canvas(
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = graphical_options[["bg"]]
  )


#----------------------------------------------------------#
# 3. Save manuscript outputs -----
#----------------------------------------------------------#

file_figure_base <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("paleo_modern_matched_comparison_{tag_date}")
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_paleo_modern,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved paleo-modern comparison: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

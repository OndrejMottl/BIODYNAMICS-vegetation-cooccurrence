#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Visualise paleo-modern spatial comparison
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Creates side-by-side and difference figures for matched
#   paleo-modern biotic co-occurrence components.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_output_figures <-
  here::here("Outputs/Figures/Spatial")

base::dir.create(
  path = path_output_figures,
  showWarnings = FALSE,
  recursive = TRUE
)

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Load comparison unit table -----
#----------------------------------------------------------#

file_comparison_unit <-
  get_latest_dated_file_path(
    file_name_base = "paleo_modern_patterns_comparison_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )

data_comparison_unit <-
  readr::read_csv(
    file = file_comparison_unit,
    show_col_types = FALSE
  )


#----------------------------------------------------------#
# 2. Prepare plot data -----
#----------------------------------------------------------#

vec_scale_levels <-
  c("continental", "regional", "local")

data_biotic_unit <-
  data_comparison_unit |>
  dplyr::filter(
    .data$component == "Associations"
  ) |>
  dplyr::mutate(
    scale = base::factor(
      .data$scale,
      levels = vec_scale_levels
    )
  )

data_side_by_side <-
  data_biotic_unit |>
  dplyr::select(
    scale,
    scale_id,
    comparison_id,
    comparison_resolution,
    R2_paleo = R2_Nagelkerke_percentage_paleo,
    R2_modern = R2_Nagelkerke_percentage_modern
  ) |>
  tidyr::pivot_longer(
    cols = c("R2_paleo", "R2_modern"),
    names_to = "data_source",
    values_to = "R2_Nagelkerke_percentage"
  ) |>
  dplyr::mutate(
    data_source = dplyr::case_when(
      .data$data_source == "R2_paleo" ~ "Paleo",
      .data$data_source == "R2_modern" ~ "Modern",
      .default = .data$data_source
    )
  )

data_side_summary <-
  data_side_by_side |>
  dplyr::group_by(
    .data$scale,
    .data$comparison_id,
    .data$comparison_resolution,
    .data$data_source
  ) |>
  dplyr::summarise(
    mean = base::mean(
      .data$R2_Nagelkerke_percentage,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

data_delta_summary <-
  data_biotic_unit |>
  dplyr::group_by(
    .data$scale,
    .data$comparison_id,
    .data$comparison_resolution
  ) |>
  dplyr::summarise(
    mean = base::mean(
      .data$R2_delta_modern_minus_paleo,
      na.rm = TRUE
    ),
    lwr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.025,
      na.rm = TRUE,
      names = FALSE
    ),
    upr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.975,
      na.rm = TRUE,
      names = FALSE
    ),
    .groups = "drop"
  )


#----------------------------------------------------------#
# 3. Build figures -----
#----------------------------------------------------------#

plot_side_by_side <-
  data_side_summary |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = comparison_resolution,
      y = mean,
      fill = data_source
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(scale),
    nrow = 1
  ) +
  ggplot2::scale_fill_manual(
    values = c("Paleo" = "#7570B3", "Modern" = "#1B9E77"),
    name = "Data source"
  ) +
  ggplot2::labs(
    title = "Biotic co-occurrence component by data source",
    x = NULL,
    y = "Mean component share (%)"
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    legend.position = "top",
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
  ) +
  ggplot2::geom_col(
    position = ggplot2::position_dodge(width = 0.75),
    colour = "white",
    linewidth = 0.2,
    width = 0.7
  )

plot_delta <-
  data_delta_summary |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = comparison_resolution,
      y = mean,
      ymin = lwr_95,
      ymax = upr_95
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(scale),
    nrow = 1
  ) +
  ggplot2::labs(
    title = "Modern minus paleo difference",
    x = NULL,
    y = "Delta in component share (%)"
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
  ) +
  ggplot2::geom_hline(
    yintercept = 0,
    colour = "grey55",
    linewidth = 0.4
  ) +
  ggplot2::geom_pointrange(
    colour = "#1B9E77",
    linewidth = 0.7,
    size = 0.9
  )

fig_paleo_modern <-
  cowplot::plot_grid(
    plot_side_by_side,
    plot_delta,
    labels = c("A", "B"),
    ncol = 1,
    align = "v"
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )


#----------------------------------------------------------#
# 4. Save -----
#----------------------------------------------------------#

file_paleo_modern <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("modern_vs_paleo_comparison_{tag_date}.pdf")
  )

ggview::save_ggplot(
  plot = fig_paleo_modern,
  file = file_paleo_modern,
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

base::message("Saved paleo-modern comparison figure: ", file_paleo_modern)

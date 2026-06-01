#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Visualise paleo variance partitioning
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Creates stacked variance-partitioning, biotic-component
#   spread, and unit-level waffle figures from the latest paleo
#   spatial unit table.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
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

vec_scale_levels <-
  base::c("continental", "regional", "local")

vec_resolution_labels <-
  base::c(
    "genus" = "Genus",
    "family" = "Family",
    "functional_type" = "Functional type"
  )

vec_component_levels <-
  base::c("Biotic co-occurrence", "Climate", "Spatial", "Unexplained")

vec_component_display_labels <-
  base::c(
    "Abiotic" = "Climate"
  )

vec_component_colours <-
  base::c(
    "Biotic co-occurrence" = "#1B9E77",
    "Climate" = "#D95F02",
    "Spatial" = "#7570B3",
    "Unexplained" = "grey85"
  )

vec_waffle_component_colours <-
  base::c(
    "Abiotic" = "#D95F02",
    "Spatial" = "#7570B3",
    "Associations" = "#1B9E77"
  )

vec_continent_shapes <-
  base::c(
    "america" = 0,
    "asia" = 2,
    "europe" = 6
  )


#----------------------------------------------------------#
# 1. Load paleo unit table -----
#----------------------------------------------------------#

file_paleo_unit <-
  get_latest_dated_file_path(
    file_name_base = "paleo_patterns_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )

data_paleo_unit <-
  readr::read_csv(
    file = file_paleo_unit,
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    continent_id = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data/Input/spatial_grid.csv")
    )
  )


#----------------------------------------------------------#
# 2. Prepare plot data -----
#----------------------------------------------------------#

data_paleo_plot <-
  prepare_spatial_variance_plot_data(
    data_unit = data_paleo_unit,
    vec_scale_levels = vec_scale_levels,
    vec_resolution_labels = vec_resolution_labels,
    percentage_source_column = "R2_Nagelkerke_percentage",
    scale_source_to_percentage = FALSE
  ) |>
  dplyr::mutate(
    component_label = dplyr::recode(
      .x = .data$component_label,
      !!!vec_component_display_labels,
      .default = .data$component_label
    )
  )

data_component_stack <-
  summarise_spatial_variance_stack(
    data_plot = data_paleo_plot,
    vec_component_levels = vec_component_levels
  )

data_biotic_summary <-
  summarise_spatial_biotic_component(
    data_plot = data_paleo_plot
  )

data_waffle <-
  prepare_spatial_variance_waffle_data(
    data_plot = data_paleo_plot,
    vec_component_colours = vec_waffle_component_colours
  )


#----------------------------------------------------------#
# 3. Build figures -----
#----------------------------------------------------------#

plot_stack <-
  plot_spatial_variance_stack(
    data_component_stack = data_component_stack,
    plot_title = "Paleo variance partitioning",
    vec_component_colours = vec_component_colours
  )

plot_biotic <-
  plot_spatial_biotic_component(
    data_plot = data_paleo_plot,
    data_biotic_summary = data_biotic_summary,
    plot_title = "Paleo biotic co-occurrence component"
  )

fig_paleo_variance <-
  cowplot::plot_grid(
    plot_stack,
    plot_biotic,
    labels = base::c("A", "B"),
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

fig_paleo_waffle <-
  plot_spatial_variance_waffle(
    data_waffle = data_waffle,
    plot_title = "Paleo mixed variance composition across scales",
    vec_continent_shapes = vec_continent_shapes,
    flag_show_fill_legend = TRUE,
    vec_component_colours = vec_waffle_component_colours,
    fill_legend_style = "triangle"
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

file_paleo_variance <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("paleo_variance_partitioning_{tag_date}.pdf")
  )

file_paleo_waffle <-
  base::file.path(
    path_output_figures,
    stringr::str_glue(
      "paleo_variance_partitioning_waffle_{tag_date}.pdf"
    )
  )

ggview::save_ggplot(
  plot = fig_paleo_variance,
  file = file_paleo_variance,
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

ggview::save_ggplot(
  plot = fig_paleo_waffle,
  file = file_paleo_waffle,
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

base::message("Saved paleo variance figure: ", file_paleo_variance)
base::message("Saved paleo variance waffle: ", file_paleo_waffle)

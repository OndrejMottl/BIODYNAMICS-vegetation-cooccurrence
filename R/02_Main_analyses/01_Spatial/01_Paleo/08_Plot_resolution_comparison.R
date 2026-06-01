#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Plot paleo resolution comparison
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Produces the unit-level waffle plot for paleo Associations
#   variance from the latest paleo spatial unit table. The newer
#   09_Visualise_variance_partitioning.R script also saves this plot
#   alongside the stacked variance-partitioning figure.


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

vec_waffle_component_colours <-
  base::c(
    "Abiotic" = "#D95F02",
    "Spatial" = "#7570B3",
    "Associations" = "#1B9E77"
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
    vec_scale_levels = base::c("continental", "regional", "local"),
    vec_resolution_labels = base::c(
      "genus" = "Genus",
      "family" = "Family",
      "functional_type" = "Functional type"
    ),
    percentage_source_column = "R2_Nagelkerke_percentage",
    scale_source_to_percentage = FALSE
  )

data_waffle <-
  prepare_spatial_variance_waffle_data(
    data_plot = data_paleo_plot,
    vec_component_colours = vec_waffle_component_colours
  )


#----------------------------------------------------------#
# 3. Build and save figure -----
#----------------------------------------------------------#

fig_resolution_comparison <-
  plot_spatial_variance_waffle(
    data_waffle = data_waffle,
    plot_title = "",
    vec_continent_shapes = base::c(
      "america" = 0,
      "asia" = 2,
      "europe" = 6
    ),
    flag_show_fill_legend = TRUE,
    vec_component_colours = vec_waffle_component_colours,
    fill_legend_style = "triangle"
  ) +
  ggview::canvas(
    height = graphical_options[["height"]],
    width = graphical_options[["width"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

ggview::save_ggplot(
  plot = fig_resolution_comparison,
  file = base::file.path(
    path_output_figures,
    stringr::str_glue("Fig_resolution_comparison_{tag_date}.png")
  ),
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

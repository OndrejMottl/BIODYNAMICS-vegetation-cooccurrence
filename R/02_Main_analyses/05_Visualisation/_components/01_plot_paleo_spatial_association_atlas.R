#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Plot paleo spatial association atlas
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds one manuscript atlas from the paleo spatial synthesis table. The
# preparation inventory completes the intended unit-resolution grid so an
# expected-infeasible or missing model cannot be mistaken for a zero effect.
# This script never reads model targets or launches analytical pipelines.
# Workflow contract:
#   Run after paleo spatial synthesis and preparation status publication.
#   Reads plot-ready tables, validates unit coverage, and never reads stores.
#   Writes one dated atlas as PDF, TIFF, and PNG plus its exact CSV data.


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
# 1. Load synthesis and coverage evidence -----
#----------------------------------------------------------#

file_paleo_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "paleo_patterns_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
file_preparation_inventory <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "calibration_unit_inventory.csv"
  )

data_paleo_unit <-
  readr::read_csv(
    file_paleo_unit,
    show_col_types = FALSE
  )
data_spatial_grid <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  )
data_preparation_inventory <-
  readr::read_csv(
    file_preparation_inventory,
    show_col_types = FALSE
  )


#----------------------------------------------------------#
# 2. Prepare and save plot data -----
#----------------------------------------------------------#

vec_resolution_labels <-
  base::c(
    genus = "Genus",
    family = "Family",
    functional_type = "Functional type"
  )
vec_scale_labels <-
  base::c(
    continental = "Continental",
    regional = "Regional",
    local = "Local"
  )
vec_continent_labels <-
  base::c(
    america = "America",
    europe = "Europe",
    asia = "Asia"
  )

data_map <-
  prepare_spatial_association_map_data(
    data_unit = data_paleo_unit,
    data_spatial_grid = data_spatial_grid,
    data_preparation_inventory = data_preparation_inventory,
    resolution_ids = base::names(vec_resolution_labels)
  ) |>
  dplyr::mutate(
    continent_label = base::unname(
      vec_continent_labels[.data$continent_id]
    ),
    scale_label = base::unname(vec_scale_labels[.data$scale]),
    resolution_label = base::unname(
      vec_resolution_labels[.data$resolution_id]
    )
  )

file_plot_data <-
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_spatial_association_atlas_plot_data_{tag_date}.csv"
    )
  )
readr::write_csv(data_map, file_plot_data)


#----------------------------------------------------------#
# 3. Build the atlas -----
#----------------------------------------------------------#

sf_world <-
  rnaturalearth::ne_countries(
    scale = "medium",
    returnclass = "sf"
  )

data_panel_index <-
  tidyr::expand_grid(
    scale_id = base::names(vec_scale_labels),
    continent_id = base::names(vec_continent_labels)
  )

list_map_panels <-
  data_panel_index |>
  purrr::pmap(
    function(scale_id, continent_id) {
      plot_manuscript_spatial_map_panel(
        data_map = data_map,
        sf_world = sf_world,
        continent_id = continent_id,
        scale_id = scale_id,
        resolution_ids = base::names(vec_resolution_labels),
        panel_label = stringr::str_glue(
          "{vec_continent_labels[[continent_id]]} | ",
          "{vec_scale_labels[[scale_id]]}"
        )
      )
    }
  )

index_legend <-
  data_panel_index |>
  dplyr::mutate(index = dplyr::row_number()) |>
  dplyr::filter(
    .data$continent_id == "europe",
    .data$scale_id == "local"
  ) |>
  dplyr::pull(.data$index)
plot_shared_legend <-
  cowplot::get_legend(
    list_map_panels[[index_legend]] +
      ggplot2::theme(legend.position = "bottom")
  )
list_map_panels_without_legend <-
  purrr::map(
    list_map_panels,
    ~ .x + ggplot2::theme(legend.position = "none")
  )

plot_map_grid <-
  cowplot::plot_grid(
    plotlist = list_map_panels_without_legend,
    ncol = 3L,
    align = "hv"
  )
fig_paleo_spatial_atlas <-
  cowplot::plot_grid(
    plot_map_grid,
    plot_shared_legend,
    ncol = 1L,
    rel_heights = base::c(1, 0.14)
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
    stringr::str_glue("paleo_spatial_association_atlas_{tag_date}")
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_paleo_spatial_atlas,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved paleo spatial association atlas: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

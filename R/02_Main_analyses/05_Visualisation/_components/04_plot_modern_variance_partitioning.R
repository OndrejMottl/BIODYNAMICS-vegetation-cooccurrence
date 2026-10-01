#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Plot modern spatial variance partitioning
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Uses the same data grammar, component colours, axes, and panel layout as the
# paleo variance figure so the two periods can be compared directly.
# Workflow contract:
#   Run after modern spatial synthesis publishes unit and summary tables.
#   Reads and validates plot-ready tables without opening target stores.
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
# 1. Load and prepare synthesis data -----
#----------------------------------------------------------#

file_modern_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "modern_patterns_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
data_modern_unit <-
  readr::read_csv(
    file_modern_unit,
    show_col_types = FALSE
  )

data_modern_plot <-
  prepare_spatial_variance_plot_data(
    data_unit = data_modern_unit,
    vec_scale_levels = base::c("continental", "regional", "local"),
    vec_resolution_labels = base::c(
      genus = "Genus",
      family = "Family",
      ft_modern = "Functional type"
    ),
    percentage_source_column = "R2_Nagelkerke_percentage",
    scale_source_to_percentage = FALSE
  ) |>
  dplyr::mutate(
    component_label = dplyr::recode(
      .data$component_label,
      Abiotic = "Climate",
      .default = .data$component_label
    )
  )

data_modern_component_summary <-
  summarise_spatial_variance_stack(
    data_plot = data_modern_plot,
    vec_component_levels = base::c(
      "Biotic co-occurrence",
      "Climate",
      "Spatial",
      "Unexplained"
    )
  )
data_modern_biotic_summary <-
  summarise_spatial_biotic_component(data_modern_plot)

readr::write_csv(
  data_modern_plot,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "modern_variance_partitioning_unit_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_modern_component_summary,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "modern_variance_partitioning_components_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_modern_biotic_summary,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "modern_variance_partitioning_associations_{tag_date}.csv"
    )
  )
)


#----------------------------------------------------------#
# 2. Build and save manuscript figure -----
#----------------------------------------------------------#

fig_modern_variance <-
  plot_manuscript_spatial_variance(
    data_plot = data_modern_plot,
    data_component_summary = data_modern_component_summary,
    data_biotic_summary = data_modern_biotic_summary
  ) +
  ggview::canvas(
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = graphical_options[["bg"]]
  )

file_figure_base <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("modern_variance_partitioning_{tag_date}")
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_modern_variance,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved modern variance partitioning: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

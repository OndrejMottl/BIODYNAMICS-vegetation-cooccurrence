#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Plot functional-type comparison
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Combines the stage 04 Europe trait-space ordination with paired paleo and
# modern functional-type model results. Only the largest functional-type
# centroids are labelled to preserve taxon-level structure and readability.
# Workflow contract:
#   Run after spatial synthesis and the matched comparison are current.
#   Reads plot-ready ordination and matched tables without opening stores.
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
# 1. Load ordination and matched model synthesis -----
#----------------------------------------------------------#

file_ordination_unit <-
  resolve_latest_dated_file_path(
    file_name_base = "functional_type_ordination_unit",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
file_ordination_summary <-
  resolve_latest_dated_file_path(
    file_name_base = "functional_type_ordination_summary",
    path_directory = here::here("Outputs/Tables"),
    file_extension = "csv"
  )
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

data_ordination_unit <-
  readr::read_csv(
    file_ordination_unit,
    show_col_types = FALSE
  )
data_ordination_summary <-
  readr::read_csv(
    file_ordination_summary,
    show_col_types = FALSE
  )
data_matched_all <-
  prepare_matched_paleo_modern_plot_data(
    data_comparison_unit = readr::read_csv(
      file_comparison_unit,
      show_col_types = FALSE
    ),
    data_comparison_coverage = readr::read_csv(
      file_comparison_coverage,
      show_col_types = FALSE
    )
  )
data_functional_type_models <-
  data_matched_all |>
  dplyr::filter(.data$comparison_id == "functional_type")

validate_manuscript_plot_data(
  data_plot = data_ordination_unit,
  required_columns = base::c(
    "taxon_name",
    "functional_type",
    "nmds_1",
    "nmds_2",
    "nmds_stress"
  )
)
validate_manuscript_plot_data(
  data_plot = data_functional_type_models,
  required_columns = base::c(
    "scale",
    "scale_id",
    "R2_Nagelkerke_percentage_paleo",
    "R2_Nagelkerke_percentage_modern"
  )
)


#----------------------------------------------------------#
# 2. Prepare auditable plot tables -----
#----------------------------------------------------------#

data_ordination_centroids <-
  data_ordination_summary |>
  dplyr::mutate(
    functional_type_label = stringr::str_glue(
      "FT {base::as.integer(.data$functional_type)}"
    )
  )
data_ordination_labels <-
  data_ordination_centroids |>
  dplyr::arrange(
    dplyr::desc(.data$n_taxa),
    .data$functional_type
  ) |>
  dplyr::slice_head(n = 4L)
data_ordination_linked <-
  data_ordination_unit |>
  dplyr::mutate(
    functional_type_label = stringr::str_glue(
      "FT {base::as.integer(.data$functional_type)}"
    )
  ) |>
  dplyr::left_join(
    data_ordination_centroids |>
      dplyr::select(
        "functional_type",
        nmds_1_centroid = "nmds_1",
        nmds_2_centroid = "nmds_2"
      ),
    by = dplyr::join_by(functional_type),
    multiple = "error"
  )

data_functional_type_long <-
  data_functional_type_models |>
  dplyr::select(
    "scale",
    "scale_id",
    paleo = "R2_Nagelkerke_percentage_paleo",
    modern = "R2_Nagelkerke_percentage_modern",
    "n_matched_units",
    "n_paleo_unmatched",
    "n_modern_unmatched"
  ) |>
  tidyr::pivot_longer(
    cols = base::c("paleo", "modern"),
    names_to = "data_source",
    values_to = "association_percentage"
  ) |>
  dplyr::mutate(
    data_source = dplyr::recode(
      .data$data_source,
      paleo = "Paleo",
      modern = "Modern"
    ),
    data_source = base::factor(
      .data$data_source,
      levels = base::c("Paleo", "Modern")
    )
  )

data_functional_type_summary <-
  data_functional_type_long |>
  dplyr::group_by(
    .data$scale,
    .data$data_source
  ) |>
  dplyr::summarise(
    median = stats::median(.data$association_percentage),
    lwr_95 = stats::quantile(
      .data$association_percentage,
      probs = 0.025,
      names = FALSE
    ),
    upr_95 = stats::quantile(
      .data$association_percentage,
      probs = 0.975,
      names = FALSE
    ),
    .groups = "drop"
  )

readr::write_csv(
  data_ordination_linked,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "functional_type_comparison_ordination_{tag_date}.csv"
    )
  )
)
readr::write_csv(
  data_functional_type_long,
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "functional_type_comparison_models_{tag_date}.csv"
    )
  )
)


#----------------------------------------------------------#
# 3. Build ordination and model panels -----
#----------------------------------------------------------#

vec_functional_type_levels <-
  data_ordination_linked |>
  dplyr::distinct(
    .data$functional_type,
    .data$functional_type_label
  ) |>
  dplyr::arrange(.data$functional_type) |>
  dplyr::pull(.data$functional_type_label)
vec_functional_type_colours <-
  grDevices::hcl.colors(
    n = base::length(vec_functional_type_levels),
    palette = "Dark 3"
  ) |>
  rlang::set_names(vec_functional_type_levels)
value_nmds_stress <-
  data_ordination_unit |>
  dplyr::pull(.data$nmds_stress) |>
  base::unique() |>
  dplyr::first()

plot_ordination <-
  data_ordination_linked |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$nmds_1,
      y = .data$nmds_2
    )
  ) +
  ggplot2::scale_fill_manual(
    values = vec_functional_type_colours,
    guide = "none"
  ) +
  ggplot2::scale_colour_manual(
    values = vec_functional_type_colours,
    guide = "none"
  ) +
  ggplot2::labs(
    x = stringr::str_glue(
      "NMDS 1 (stress = {base::round(value_nmds_stress, 2)})"
    ),
    y = "NMDS 2"
  ) +
  build_manuscript_theme() +
  ggplot2::theme(
    legend.position = "none",
    panel.grid = ggplot2::element_blank()
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      xend = .data$nmds_1_centroid,
      yend = .data$nmds_2_centroid,
      colour = .data$functional_type_label
    ),
    linewidth = 0.2,
    alpha = 0.18
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(fill = .data$functional_type_label),
    shape = 21,
    size = 1.2,
    colour = "white",
    stroke = 0.2,
    alpha = 0.75
  ) +
  ggplot2::geom_point(
    data = data_ordination_centroids,
    mapping = ggplot2::aes(colour = .data$functional_type_label),
    shape = 15,
    size = 2
  ) +
  ggrepel::geom_text_repel(
    data = data_ordination_labels,
    mapping = ggplot2::aes(
      label = stringr::str_glue(
        "{functional_type_label} (n = {n_taxa})"
      ),
      colour = .data$functional_type_label
    ),
    seed = 900723,
    size = 2.5,
    box.padding = 0.35,
    min.segment.length = 0,
    show.legend = FALSE
  )

plot_model_comparison <-
  data_functional_type_long |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$data_source,
      y = .data$association_percentage,
      group = .data$scale_id
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$scale),
    nrow = 1L
  ) +
  ggplot2::scale_colour_manual(
    values = build_manuscript_palette("data_source"),
    guide = "none"
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 100),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Association variance"
  ) +
  build_manuscript_theme() +
  ggplot2::theme(panel.grid.major.x = ggplot2::element_blank()) +
  ggplot2::geom_line(
    colour = "grey75",
    linewidth = 0.3,
    alpha = 0.6
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(colour = .data$data_source),
    size = 1.2,
    alpha = 0.55
  ) +
  ggplot2::geom_linerange(
    data = data_functional_type_summary,
    mapping = ggplot2::aes(
      x = .data$data_source,
      y = .data$median,
      ymin = .data$lwr_95,
      ymax = .data$upr_95,
      colour = .data$data_source,
      group = .data$data_source
    ),
    inherit.aes = FALSE,
    linewidth = 0.8
  ) +
  ggplot2::geom_point(
    data = data_functional_type_summary,
    mapping = ggplot2::aes(
      x = .data$data_source,
      y = .data$median,
      colour = .data$data_source
    ),
    inherit.aes = FALSE,
    size = 2.2
  )

fig_functional_type <-
  cowplot::plot_grid(
    plot_ordination,
    plot_model_comparison,
    labels = base::c("A", "B"),
    ncol = 1L,
    rel_heights = base::c(1.35, 1),
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
    stringr::str_glue("functional_type_comparison_{tag_date}")
  )
vec_figure_files <-
  save_manuscript_figure(
    plot = fig_functional_type,
    file_base = file_figure_base,
    graphical_options = graphical_options
  )

base::message(
  "Saved functional-type comparison: ",
  stringr::str_c(vec_figure_files, collapse = ", ")
)

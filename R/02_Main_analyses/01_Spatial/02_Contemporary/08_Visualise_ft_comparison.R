#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Visualise functional-type comparison
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares paleo-derived and modern-derived functional-type
#   classifications as a taxon reassignment heatmap, and compares
#   available functional-type biotic model patterns.


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
# 1. Load FT classifications -----
#----------------------------------------------------------#

vec_continents <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(
    .data$scale == "continental"
  ) |>
  dplyr::pull(.data$scale_id)

data_ft_reassignment <-
  vec_continents |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ {
      sel_continent <- .x

      file_paleo_ft <-
        get_functional_type_classification_path(
          continent_id = sel_continent
        )

      file_modern_ft <-
        get_functional_type_classification_path(
          continent_id = sel_continent,
          data_source_prefix = "modern"
        )

      data_paleo_ft <-
        read_functional_type_classification(
          file = file_paleo_ft
        ) |>
        dplyr::rename(
          functional_type_paleo = functional_type
        )

      data_modern_ft <-
        read_functional_type_classification(
          file = file_modern_ft
        ) |>
        dplyr::rename(
          functional_type_modern = functional_type
        )

      data_paleo_ft |>
        dplyr::inner_join(
          y = data_modern_ft,
          by = dplyr::join_by(taxon_name),
          multiple = "error"
        ) |>
        dplyr::mutate(
          continent_id = sel_continent,
          functional_type_paleo = stringr::str_glue(
            "Paleo FT {functional_type_paleo}"
          ),
          functional_type_modern = stringr::str_glue(
            "Modern FT {functional_type_modern}"
          )
        )
    }
  ) |>
  purrr::list_rbind()

if (
  base::nrow(data_ft_reassignment) == 0L
) {
  cli::cli_abort("No matched paleo-modern FT classifications were found.")
}

data_ft_heatmap <-
  data_ft_reassignment |>
  dplyr::count(
    .data$continent_id,
    .data$functional_type_paleo,
    .data$functional_type_modern,
    name = "n_taxa"
  )


#----------------------------------------------------------#
# 2. Load functional-type model comparison -----
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

vec_scale_levels <-
  c("continental", "regional", "local")

data_ft_model_unit <-
  data_comparison_unit |>
  dplyr::filter(
    .data$component == "Associations",
    .data$comparison_id == "functional_type"
  ) |>
  dplyr::mutate(
    scale = base::factor(
      .data$scale,
      levels = vec_scale_levels
    )
  )

if (
  base::nrow(data_ft_model_unit) == 0L
) {
  cli::cli_abort("No functional-type model comparison rows were found.")
}

data_ft_model_summary <-
  data_ft_model_unit |>
  dplyr::select(
    scale,
    scale_id,
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
      .data$data_source == "R2_paleo" ~ "Paleo functional type",
      .data$data_source == "R2_modern" ~ "Modern functional type",
      .default = .data$data_source
    )
  ) |>
  dplyr::group_by(
    .data$scale,
    .data$data_source
  ) |>
  dplyr::summarise(
    mean = base::mean(
      .data$R2_Nagelkerke_percentage,
      na.rm = TRUE
    ),
    lwr_95 = stats::quantile(
      .data$R2_Nagelkerke_percentage,
      probs = 0.025,
      na.rm = TRUE,
      names = FALSE
    ),
    upr_95 = stats::quantile(
      .data$R2_Nagelkerke_percentage,
      probs = 0.975,
      na.rm = TRUE,
      names = FALSE
    ),
    .groups = "drop"
  )


#----------------------------------------------------------#
# 3. Build figures -----
#----------------------------------------------------------#

plot_reassignment <-
  data_ft_heatmap |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = functional_type_modern,
      y = functional_type_paleo,
      fill = n_taxa
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(continent_id),
    scales = "free"
  ) +
  ggplot2::scale_fill_viridis_c(
    name = "Taxa"
  ) +
  ggplot2::labs(
    title = "Taxon reassignment between paleo and modern FT groups",
    x = "Modern functional type",
    y = "Paleo functional type"
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    legend.position = "top",
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  ) +
  ggplot2::geom_tile(
    colour = "white",
    linewidth = 0.2
  )

plot_model_comparison <-
  data_ft_model_summary |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = scale,
      y = mean,
      ymin = lwr_95,
      ymax = upr_95,
      colour = data_source
    )
  ) +
  ggplot2::scale_colour_manual(
    values = c(
      "Paleo functional type" = "#7570B3",
      "Modern functional type" = "#1B9E77"
    ),
    name = "Model result"
  ) +
  ggplot2::labs(
    title = "Functional-type biotic co-occurrence component",
    x = NULL,
    y = "Component share (%)"
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    legend.position = "top"
  ) +
  ggplot2::geom_pointrange(
    position = ggplot2::position_dodge(width = 0.45),
    linewidth = 0.7,
    size = 0.9
  )

fig_ft_comparison <-
  cowplot::plot_grid(
    plot_reassignment,
    plot_model_comparison,
    labels = c("A", "B"),
    ncol = 1,
    rel_heights = c(1.4, 1)
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

file_ft_comparison <-
  base::file.path(
    path_output_figures,
    stringr::str_glue("ft_comparison_{tag_date}.pdf")
  )

ggview::save_ggplot(
  plot = fig_ft_comparison,
  file = file_ft_comparison,
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

base::message("Saved FT comparison figure: ", file_ft_comparison)

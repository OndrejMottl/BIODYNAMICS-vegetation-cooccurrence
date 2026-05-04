#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Plot resolution comparison
#            - waffle plot of ANOVA % Associations
#            - columns = spatial scale
#            - rows    = taxonomic resolution
#            - fill    = R2 Nagelkerke (%) binned in 25-point ranges
#            - each square = 1 dataset
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads the combined ANOVA results tibble saved by
#   07_Analyse_spatial_patterns.R and produces a waffle
#   plot comparing the variance explained by species
#   Associations across spatial scales and taxonomic
#   resolutions.  Each square represents one dataset;
#   fill colour encodes the R² Nagelkerke value binned
#   into four 25-percentage-point ranges.


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


#----------------------------------------------------------#
# 1. Load combined ANOVA results -----
#----------------------------------------------------------#

data_anova_results <-
  RUtilpol::get_latest_file(
    dir = here::here("Outputs/Data"),
    file_name = "data_anova_results"
  )


#----------------------------------------------------------#
# 2. Plot -----
#----------------------------------------------------------#

vec_scale_levels <- c("local", "regional", "continental")

vec_taxonomic_levels <- c("Functional type", "Family", "Genus")

# Build waffle grid manually: sort by R2 within each panel so squares
# transition from dark (low) to light (high), then assign tile positions.
n_waffle_rows <- 5L

data_waffle <-
  data_anova_results |>
  dplyr::filter(component == "Associations") |>
  dplyr::mutate(
    scale = factor(scale, levels = vec_scale_levels),
    taxonomic_scale = factor(
      taxonomic_scale,
      levels = vec_taxonomic_levels
    )
  ) |>
  dplyr::arrange(scale, taxonomic_scale, R2_Nagelkerke_percentage) |>
  dplyr::group_by(scale, taxonomic_scale) |>
  dplyr::mutate(
    idx = dplyr::row_number(),
    tile_col = ((idx - 1L) %/% n_waffle_rows) + 1L,
    tile_row = ((idx - 1L) %% n_waffle_rows) + 1L
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    # Pre-compute the exact viridis-D colour for each R2 value, then darken
    # it so the continent symbol is subtly visible without contrast shock.
    point_colour = colorspace::darken(
      viridisLite::viridis(
        n = 1000L,
        option = "D"
      )[pmax(1L, pmin(1000L, base::round(R2_Nagelkerke_percentage / 100 * 999) + 1L))],
      amount = 0.4
    )
  )

fig_resolution_comparison <-
  data_waffle |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = tile_col,
      y = tile_row,
      fill = R2_Nagelkerke_percentage
    )
  ) +
  ggplot2::geom_tile(
    colour = "white",
    linewidth = 0.33
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      shape = continent_id,
      colour = point_colour
    ),
    fill = NA,
    size = 2,
    stroke = 0.6
  ) +
  ggplot2::scale_colour_identity(guide = "none") +
  ggplot2::scale_shape_manual(
    # Outline-only shapes: 0 = open square, 2 = open triangle up,
    # 6 = open inverted triangle — all driven by 'colour', no fill needed.
    values = c(
      "america" = 0,
      "asia"    = 2,
      "europe"  = 6
    ),
    name = "Continent"
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(taxonomic_scale),
    cols = ggplot2::vars(scale),
    switch = "both"
  ) +
  ggplot2::scale_fill_viridis_c(
    limits = c(0, 100),
    name = expression(R^2 ~ "Nagelkerke (%)"),
    na.value = "grey90",
    option = "D"
  ) +
  ggplot2::coord_equal() +
  ggplot2::labs(
    title = "Variance explained by species associations across scales"
  ) +
  ggplot2::theme_classic() +
  ggplot2::guides(
    fill = ggplot2::guide_colorbar(order = 1),
    shape = ggplot2::guide_legend(order = 2)
  ) +
  ggplot2::theme(
    legend.position = "top",
    legend.box = "vertical",
    legend.box.just = "left",
    strip.background = ggplot2::element_blank(),
    strip.text.y.right = ggplot2::element_text(angle = 0),
    axis.ticks = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank()
  ) +
  ggview::canvas(
    height = graphical_options[["height"]],
    width = graphical_options[["width"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )


#----------------------------------------------------------#
# 3. Save -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = fig_resolution_comparison,
  file = base::file.path(
    path_output_figures,
    stringr::str_glue(
      "Fig_resolution_comparison_{tag_date}.png"
    )
  ),
  width = graphical_options[["width"]],
  height = graphical_options[["height"]],
  units = graphical_options[["units"]],
  dpi = graphical_options[["dpi"]],
  bg = graphical_options[["bg"]]
)

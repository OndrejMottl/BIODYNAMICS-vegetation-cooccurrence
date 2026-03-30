#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Visualise temporal pipeline results: all continents
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads outputs of the time-slice pipeline (pipeline_time.R)
#   for all continental temporal configurations and produces two
#   plots saved to Outputs/Figures/Temporal_continents/.
#
# Plot 1 — plot_temporal_continents.pdf
#   All series on their native y-scale.
#   Columns = continents, ordered west-to-east (America, Europe, Asia)
#   Rows    = 1 row for ANOVA variance components + 1 row per
#             bipartite network metric; facet_grid(panel ~ continent)
#
# Plot 2 — plot_temporal_continents_scaled.pdf
#   All series min-max rescaled to [0, 1] within each continent,
#   plotted in a single row (1 row × 3 continent columns).
#   colour = individual series; shape = data type (ANOVA / network).
#
# Implementation:
#   The two source datasets (ANOVA and network metrics) are merged
#   into a single long-format data frame with shared columns
#   `age`, `continent`, `panel` (row facet), `series` (colour),
#   and `y_value`. Both plots are derived from this unified frame.
#
# Continental configurations are derived from spatial_grid.csv
#   (scale == "continental"), mapped to config names as
#   project_temporal_{scale_id} (e.g. project_temporal_europe).
# Requires that the corresponding Run_temporal_*.R scripts have
#   been executed and all pipeline targets are up to date.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Graphical options are read from the default config because this
#   script produces a single combined output, not per-continent outputs.
graphical_options <-
  get_active_config("graphical")

path_output <-
  here::here("Outputs/Figures/Temporal_continents")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Build continental configuration inventory -----
#----------------------------------------------------------#

data_continents <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(scale == "continental") |>
  dplyr::select(scale_id) |>
  dplyr::mutate(
    config_name = base::paste0("project_temporal_", scale_id),
    store_path = here::here(
      base::paste0(
        "Data/targets/", config_name, "/pipeline_time/"
      )
    ),
    store_exists = fs::dir_exists(store_path),
    # Human-readable label for facet strips.
    continent_label = stringr::str_to_title(scale_id)
  )

vec_available <-
  data_continents |>
  dplyr::filter(store_exists) |>
  dplyr::pull(config_name)

base::message(
  "Continental configurations with available stores: ",
  base::paste(vec_available, collapse = ", ")
)

if (
  base::length(vec_available) == 0L
) {
  base::stop(
    "No temporal target stores found. ",
    "Run at least one 0*_Run_temporal_*.R script first."
  )
}


#----------------------------------------------------------#
# 2. Load data for all available continents -----
#----------------------------------------------------------#

data_anova_all <-
  data_continents |>
  dplyr::filter(store_exists) |>
  dplyr::select(scale_id, config_name, continent_label, store_path) |>
  purrr::pmap(
    .f = function(scale_id, config_name, continent_label, store_path) {
      targets::tar_read(
        name = "data_anova_components_by_age_percentage",
        store = store_path
      ) |>
        dplyr::mutate(continent = continent_label)
    }
  ) |>
  purrr::list_rbind()

# The `age` column produced by pipe_segment_network_summary_age
#   contains target-name strings (e.g. "data_network_metrics_timeslice_500")
#   because pieces are assembled via dplyr::bind_rows(.id = "age").
#   The trailing digits are extracted and cast to numeric.
data_network_all <-
  data_continents |>
  dplyr::filter(store_exists) |>
  dplyr::select(scale_id, config_name, continent_label, store_path) |>
  purrr::pmap(
    .f = function(scale_id, config_name, continent_label, store_path) {
      targets::tar_read(
        name = "data_network_metrics_by_age",
        store = store_path
      ) |>
        dplyr::mutate(
          age = stringr::str_extract(
            string = age,
            pattern = "\\d+$"
          ) |>
            base::as.numeric(),
          continent = continent_label
        )
    }
  ) |>
  purrr::list_rbind()


# Continents ordered west-to-east: America → Europe → Asia.
# This factor is applied to both data frames so facet column
# order respects geographic position on a map.
vec_continent_order <- c("America", "Europe", "Asia")

data_anova_all <-
  data_anova_all |>
  dplyr::mutate(
    continent = base::factor(continent, levels = vec_continent_order)
  )

data_network_all <-
  data_network_all |>
  dplyr::mutate(
    continent = base::factor(continent, levels = vec_continent_order)
  )


#----------------------------------------------------------#
# 3. Merge datasets into a single long-format data frame -----
#----------------------------------------------------------#

# A unified `panel` column drives the row facets:
#   "Variance components" -> ANOVA row (multiple component lines)
#   metric name           -> one row per network metric
# A unified `series` column drives the colour aesthetic.
# A unified `y_value` column holds the plotted quantity.
# free_y in facet_grid handles the different numeric ranges
#   across rows without requiring cowplot assembly.

data_anova_long <-
  data_anova_all |>
  dplyr::transmute(
    age = age,
    continent = continent,
    panel = "Variance components",
    series = component,
    y_value = R2_Nagelkerke_percentage
  )

data_network_long <-
  data_network_all |>
  dplyr::transmute(
    age = age,
    continent = continent,
    panel = metric,
    series = metric,
    y_value = value
  )

# Row order: ANOVA components first, then network metrics
#   (sorted alphabetically so order is stable across pipelines).
vec_panel_order <- c(
  "Variance components",
  data_network_long |>
    dplyr::pull(panel) |>
    base::unique() |>
    base::sort()
)

data_combined <-
  dplyr::bind_rows(
    data_anova_long,
    data_network_long
  ) |>
  dplyr::mutate(
    panel = base::factor(panel, levels = vec_panel_order)
  )


#----------------------------------------------------------#
# 4. Shared ggplot2 layer objects -----
#----------------------------------------------------------#

# Background time-grid lines and the reversed age axis are
#   identical in both plots. Defining them once avoids repeating
#   the same call and keeps both plot definitions in sync.
layer_vline_age <-
  ggplot2::geom_vline(
    xintercept = base::seq(0, 20000, by = 1000),
    colour = "grey95"
  )

scale_x_age <-
  ggplot2::scale_x_continuous(trans = "reverse")


#----------------------------------------------------------#
# 5. Full-scale faceted plot -----
#----------------------------------------------------------#

# facet_grid(panel ~ continent):
#   rows  = panel  (ANOVA row + 1 row per network metric)
#   cols  = continent (ordered west-to-east by factor levels)
#   free_y: each row has its own y-axis scale
# colour = series distinguishes ANOVA components in the top
#   row; in network rows each panel has a single series (the
#   metric itself) so the strip label acts as the legend.
plot_temporal_continents <-
  data_combined |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = age,
      y = y_value,
      colour = series,
      group = series
    )
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(panel),
    cols = ggplot2::vars(continent),
    scales = "free_y"
  ) +
  scale_x_age +
  ggplot2::labs(
    x = "Age (cal yr BP)",
    y = NULL,
    colour = "Series"
  ) +
  ggview::canvas(
    width = graphical_options[["width"]] *
      base::length(vec_continent_order),
    height = graphical_options[["height"]] *
      base::length(vec_panel_order),
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  layer_vline_age +
  ggplot2::geom_line() +
  ggplot2::geom_point(
    size = 0.8
  )

ggview::save_ggplot(
  plot = plot_temporal_continents,
  file = base::file.path(
    path_output,
    "plot_temporal_continents.pdf"
  )
)

base::message("Saved: plot_temporal_continents.pdf")


#----------------------------------------------------------#
# 6. Rescaled overview plot -----
#----------------------------------------------------------#

# All series are min-max rescaled to [0, 1] within each continent
#   so that ANOVA components and network metrics share a common
#   y-axis. The ANOVA row is filtered to the "Associations"
#   component only so it is directly comparable to the network
#   metrics.
# shape = data type distinguishes the two kinds of series;
#   colour = series identifies individual lines.
# One row × continent columns: a compact cross-variable overview.

data_combined_scaled <-
  data_combined |>
  dplyr::filter(
    panel != "Variance components" | series == "Associations"
  ) |>
  dplyr::mutate(
    data_type = dplyr::if_else(
      panel == "Variance components",
      "ANOVA component",
      "Network metric"
    )
  ) |>
  dplyr::group_by(continent, series) |>
  dplyr::mutate(
    y_min = base::min(y_value, na.rm = TRUE),
    y_max = base::max(y_value, na.rm = TRUE),
    y_scaled = dplyr::if_else(
      (y_max - y_min) > 0,
      (y_value - y_min) / (y_max - y_min),
      0
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-c(y_min, y_max))

plot_temporal_continents_scaled <-
  data_combined_scaled |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = age,
      y = y_scaled,
      colour = series,
      shape = data_type,
      group = series
    )
  ) +
  ggplot2::facet_wrap(
    facets = ggplot2::vars(continent),
    nrow = 1L
  ) +
  scale_x_age +
  ggplot2::scale_y_continuous(
    limits = c(0, 1),
    breaks = c(0, 0.5, 1)
  ) +
  ggplot2::labs(
    x = "Age (cal yr BP)",
    y = "Scaled value (min\u2013max within continent)",
    colour = "Series",
    shape = "Data type"
  ) +
  ggview::canvas(
    width = graphical_options[["width"]] *
      base::length(vec_continent_order),
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  layer_vline_age +
  ggplot2::geom_line(
    alpha = 0.7
  ) +
  ggplot2::geom_point(
    size = 1.2
  )

ggview::save_ggplot(
  plot = plot_temporal_continents_scaled,
  file = base::file.path(
    path_output,
    "plot_temporal_continents_scaled.pdf"
  )
)

base::message("Saved: plot_temporal_continents_scaled.pdf")

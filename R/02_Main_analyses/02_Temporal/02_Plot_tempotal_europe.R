#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Visualise temporal pipeline results: Europe
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads outputs of the time-slice pipeline (pipeline_time.R)
#   for the pan-European configuration and saves plots to
#   Outputs/Figures/Temporal_europe/.
# Requires that `01_Run_temporal_europe.R` has been executed
#   and all pipeline targets are up to date.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_temporal_europe")

# Path to the pipeline_time target store for this configuration.
set_store <-
  here::here(
    base::paste0(
      get_active_config("target_store"), "/pipeline_time/"
    )
  )

# Output directory.
path_output <-
  here::here("Outputs/Figures/Temporal_europe")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")

#----------------------------------------------------------#
# 1. ANOVA variance components -----
#----------------------------------------------------------#

data_anova_components <-
  targets::tar_read(
    name = "data_anova_components_by_age_percentage",
    store = set_store
  )

plot_anova <-
  plot_anova_components_by_age(
    data_anova_components = data_anova_components,
    title = "ANOVA variance components by age",
    subtitle = base::paste(
      "project:", Sys.getenv("R_CONFIG_ACTIVE")
    )
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

ggview::save_ggplot(
  plot = plot_anova,
  file = base::file.path(
    path_output,
    "plot_anova_components_by_age.pdf"
  )
)

#----------------------------------------------------------#
# 2. Bipartite network metrics -----
#----------------------------------------------------------#

# The `age` column in `data_network_metrics_by_age` contains
#   target-name strings (e.g. "data_network_metrics_timeslice_500")
#   because the data were assembled via
#   `dplyr::bind_rows(.id = "age")` inside
#   `pipe_segment_network_summary_age`. The trailing digits are
#   extracted and cast to numeric before plotting.
data_network_metrics <-
  targets::tar_read(
    name = "data_network_metrics_by_age",
    store = set_store
  ) |>
  dplyr::mutate(
    age = stringr::str_extract(
      string = age,
      pattern = "\\d+$"
    ) |>
      base::as.numeric()
  )

plot_network <-
  plot_network_metrics_by_age(
    data_network_metrics = data_network_metrics,
    title = "Bipartite network metrics by age",
    subtitle = base::paste(
      "project:", Sys.getenv("R_CONFIG_ACTIVE")
    )
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

ggview::save_ggplot(
  plot = plot_network,
  file = base::file.path(
    path_output,
    "plot_network_metrics_by_age.pdf"
  )
)

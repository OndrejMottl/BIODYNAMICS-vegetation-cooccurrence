#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Extra slide temporal association-modularity figure
#
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

list_oracle_design <-
  load_design_config(
    path = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "design_config.json"
    )
  )

vec_oracle_palette <-
  list_oracle_design |>
  purrr::chuck(
    "config",
    "palette"
  )

vec_font_match <-
  stringr::str_match(
    string = purrr::chuck(
      list_oracle_design,
      "config",
      "typography",
      "body_family"
    ),
    pattern = "'([^']+)'"
  )

font_family <-
  vec_font_match[1, 2]

path_font <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "fonts",
    "VT323-Regular.ttf"
  )

if (
  !base::file.exists(path_font)
) {
  cli::cli_abort(
    c(
      "The VT323 font file is missing.",
      "i" = "Expected path: {.path {path_font}}."
    )
  )
}

try(
  systemfonts::register_font(
    name = font_family,
    plain = path_font
  ),
  silent = TRUE
)

path_output <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "figures",
    "results",
    "extra"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

vec_continent_levels <-
  base::c(
    "America",
    "Europe",
    "Asia"
  )

vec_continent_colours <-
  base::c(
    "America" = vec_oracle_palette[["cyan"]],
    "Europe" = vec_oracle_palette[["amber"]],
    "Asia" = vec_oracle_palette[["purple"]]
  )


#----------------------------------------------------------#
# 1. Load temporal model outputs -----
#----------------------------------------------------------#

data_temporal_inventory <-
  load_continental_rows(
    path_spatial_grid = here::here("Data", "Input", "spatial_grid.csv")
  ) |>
  dplyr::select("scale_id") |>
  dplyr::mutate(
    store_path = here::here(
      stringr::str_glue(
        "Data/targets/paleo_temporal_{scale_id}/pipeline_paleo_temporal"
      )
    ),
    store_exists = fs::dir_exists(.data$store_path),
    continent = stringr::str_to_title(.data$scale_id)
  ) |>
  # dplyr::filter(.data$store_exists) |>
  dplyr::select(
    "scale_id",
    "continent",
    "store_path"
  )

if (
  base::nrow(data_temporal_inventory) == 0L
) {
  cli::cli_abort(
    c(
      "No temporal target stores found.",
      "i" = "Run temporal targets before generating this figure."
    )
  )
}


#----------------------------------------------------------#
# 2. Prepare plot data -----
#----------------------------------------------------------#

data_association_temporal <-
  data_temporal_inventory |>
  purrr::pmap(
    .f = function(scale_id, continent, store_path) {
      targets::tar_read(
        name = "data_anova_components_by_age_percentage",
        store = store_path
      ) |>
        dplyr::mutate(continent = continent)
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::filter(
    .data$component == "Associations",
    base::is.finite(.data$R2_Nagelkerke_percentage)
  ) |>
  dplyr::transmute(
    age = base::as.numeric(.data$age),
    continent = base::factor(
      .data$continent,
      levels = vec_continent_levels
    ),
    association_variance = base::pmax(
      .data$R2_Nagelkerke_percentage,
      0
    )
  )

if (
  base::nrow(data_association_temporal) == 0L
) {
  cli::cli_abort(
    "No finite association variance values were found in temporal stores."
  )
}

data_modularity_temporal <-
  data_temporal_inventory |>
  purrr::pmap(
    .f = function(scale_id, continent, store_path) {
      targets::tar_read(
        name = "data_network_metrics_by_age",
        store = store_path
      ) |>
        dplyr::mutate(
          age = stringr::str_extract(
            string = .data$age,
            pattern = "\\d+$"
          ) |>
            base::as.numeric(),
          continent = continent
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::filter(
    .data$metric == "modularity Q",
    base::is.finite(.data$value)
  ) |>
  dplyr::transmute(
    age = .data$age,
    continent = base::factor(
      .data$continent,
      levels = vec_continent_levels
    ),
    modularity_q = base::pmin(
      base::pmax(.data$value, 0),
      1
    )
  )

if (
  base::nrow(data_modularity_temporal) == 0L
) {
  cli::cli_abort(
    "No finite modularity Q values were found in temporal stores."
  )
}

data_temporal_plot <-
  dplyr::inner_join(
    x = data_association_temporal,
    y = data_modularity_temporal,
    by = dplyr::join_by(
      age,
      continent
    )
  ) |>
  dplyr::mutate(
    age_kyr_bp = .data$age / 1000
  ) |>
  dplyr::arrange(
    .data$continent,
    dplyr::desc(.data$age)
  )

if (
  base::nrow(data_temporal_plot) == 0L
) {
  cli::cli_abort(
    "No shared age points between association and modularity data were found."
  )
}

data_time_labels <-
  data_temporal_plot |>
  dplyr::group_by(.data$continent) |>
  dplyr::slice(
    base::which.max(.data$age),
    base::which.min(.data$age)
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    time_label = stringr::str_glue("{base::round(.data$age_kyr_bp, 1)} kyr")
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

figure_temporal_association_modularity <-
  data_temporal_plot |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$modularity_q,
      y = .data$association_variance
    )
  ) +
  ggplot2::geom_line(
    mapping = ggplot2::aes(
      group = .data$continent,
      colour = .data$continent
    ),
    linewidth = 0.55,
    alpha = 0.7
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      colour = .data$continent,
      fill = .data$age_kyr_bp
    ),
    shape = 21,
    size = 2.2,
    stroke = 0.35,
    alpha = 0.95
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = vec_oracle_palette[["phosphor"]],
    linewidth = 1,
    linetype = "dashed",
    alpha = 0.9
  ) +
  ggrepel::geom_text_repel(
    data = data_time_labels,
    mapping = ggplot2::aes(
      label = .data$time_label
    ),
    inherit.aes = TRUE,
    size = 2.8,
    colour = vec_oracle_palette[["text"]],
    segment.colour = vec_oracle_palette[["border"]],
    segment.size = 0.2,
    box.padding = 0.18,
    point.padding = 0.12,
    seed = 900723,
    max.overlaps = 60,
    show.legend = FALSE
  ) +
  ggplot2::scale_colour_manual(
    values = vec_continent_colours,
    name = NULL
  ) +
  ggplot2::scale_fill_gradient(
    low = vec_oracle_palette[["cyan"]],
    high = vec_oracle_palette[["amber"]],
    name = "Age (kyr BP)",
    breaks = scales::pretty_breaks(n = 5)
  ) +
  ggplot2::scale_x_continuous(
    limits = base::c(0, 1),
    breaks = base::seq(0, 1, by = 0.2),
    expand = ggplot2::expansion(mult = base::c(0.02, 0.02))
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(suffix = "%"),
    expand = ggplot2::expansion(mult = base::c(0.04, 0.08))
  ) +
  ggplot2::labs(
    x = "Network modularity Q",
    y = "Association variance"
  ) +
  ggview::canvas(
    width = 1500,
    height = 820,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  create_oracle_theme(
    base_family = font_family,
    base_size = 12
  ) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.25
    ),
    axis.line = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.32
    ),
    axis.text = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 10
    ),
    axis.title = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 12
    ),
    legend.position = "right",
    legend.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.key = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.text = ggplot2::element_text(
      colour = vec_oracle_palette[["text"]],
      size = 9.5
    ),
    legend.title = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 10.2
    ),
    plot.margin = ggplot2::margin(10, 14, 8, 8)
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_temporal_association_modularity,
  file = base::file.path(
    path_output,
    "slide_extra_02_temporal_association_modularity.png"
  ),
  device = ragg::agg_png
)
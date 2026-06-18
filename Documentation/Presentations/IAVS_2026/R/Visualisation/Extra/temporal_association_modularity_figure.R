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

vec_continent_shapes <-
  base::c(
    "america" = 22,
    "asia" = 24,
    "europe" = 21
  )

vec_continent_ids <-
  base::names(vec_continent_shapes)

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
    continent_id = .data$scale_id,
    continent = stringr::str_to_title(.data$scale_id)
  ) |>
  dplyr::select(
    "scale_id",
    "continent_id",
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
    .f = function(scale_id, continent_id, continent, store_path) {
      targets::tar_read(
        name = "data_anova_components_by_age_percentage",
        store = store_path
      ) |>
        dplyr::mutate(
          continent_id = continent_id,
          continent = continent
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::filter(
    .data$component == "Associations",
    base::is.finite(.data$R2_Nagelkerke_percentage)
  ) |>
  dplyr::mutate(
    age = base::as.numeric(.data$age),
    continent = base::factor(
      .data$continent,
      levels = vec_continent_levels
    ),
    continent_id = base::factor(
      .data$continent_id,
      levels = vec_continent_ids
    ),
    association_variance = base::pmax(
      .data$R2_Nagelkerke_percentage,
      0
    )
  ) |>
  dplyr::select(
    "age",
    "continent",
    "continent_id",
    "association_variance"
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
    .f = function(scale_id, continent_id, continent, store_path) {
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
          continent_id = continent_id,
          continent = continent
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::filter(
    .data$metric == "modularity Q",
    base::is.finite(.data$value)
  ) |>
  dplyr::mutate(
    age = .data$age,
    continent = base::factor(
      .data$continent,
      levels = vec_continent_levels
    ),
    continent_id = base::factor(
      .data$continent_id,
      levels = vec_continent_ids
    ),
    modularity_q = base::pmin(
      base::pmax(.data$value, 0),
      1
    )
  ) |>
  dplyr::select(
    "age",
    "continent",
    "continent_id",
    "modularity_q"
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
      continent_id,
      continent
    )
  ) |>
  dplyr::mutate(
    age_kyr_bp = .data$age / 1000,
    continent = as.character(.data$continent)
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
  ggplot2::scale_fill_gradient(
    low = vec_oracle_palette[["border"]],
    high = vec_oracle_palette[["phosphor"]],
    name = "Age (kyr BP)",
    trans = "reverse",
    breaks = scales::pretty_breaks(n = 5)
  ) +
  ggplot2::scale_x_continuous(
    limits = base::c(0, 0.5),
    breaks = base::seq(0, 0.5, by = 0.1),
    expand = ggplot2::expansion(mult = base::c(0.02, 0.02))
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(suffix = "%"),
    expand = ggplot2::expansion(mult = base::c(0.04, 0.08))
  ) +
  ggplot2::scale_shape_manual(
    values = vec_continent_shapes,
    name = NULL,
    breaks = base::names(vec_continent_shapes),
    labels = base::c(
      "America",
      "Asia",
      "Europe"
    ),
    guide = ggplot2::guide_legend(
      override.aes = base::list(
        fill = NA,
        colour = vec_oracle_palette[["phosphor"]],
        alpha = 1,
        stroke = 0.9
      )
    )
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
    axis.title.x = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 12
    ),
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
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
  ) +
  ggplot2::geom_line(
    mapping = ggplot2::aes(
      group = .data$continent,
    ),
    colour = vec_oracle_palette[["muted"]],
    linewidth = 0.55,
    alpha = 0.7
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      shape = .data$continent_id,
      fill = .data$age_kyr_bp
    ),
    size = 2.2,
    stroke = 0.35,
    alpha = 0.95
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = vec_oracle_palette[["purple"]],
    linewidth = 1,
    linetype = "dashed",
    alpha = 0.9
  ) +
  ggplot2::geom_smooth(
    mapping = ggplot2::aes(
      group = .data$continent
    ),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = vec_oracle_palette[["purple"]],
    linewidth = 0.5,
    linetype = "dotted",
    alpha = 0.5
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

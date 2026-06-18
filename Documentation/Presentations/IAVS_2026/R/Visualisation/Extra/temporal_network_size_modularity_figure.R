#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Extra slide temporal network size-modularity figure
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

font_family <- vec_font_match[1, 2]

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
# 1. Load temporal target inventory -----
#----------------------------------------------------------#

data_temporal_inventory <-
  load_continental_rows(
    path_spatial_grid = here::here("Data", "Input", "spatial_grid.csv")
  ) |>
  dplyr::select(
    "scale_id"
  ) |>
  dplyr::mutate(
    store_path = here::here(
      stringr::str_glue(
        "Data/targets/paleo_temporal_{scale_id}/pipeline_paleo_temporal"
      )
    ),
    store_exists = fs::dir_exists(.data$store_path),
    continent = stringr::str_to_title(.data$scale_id)
  ) |>
  dplyr::filter(
    .data$store_exists
  ) |>
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
  dplyr::mutate(
    modularity_q = base::pmin(
      base::pmax(.data$value, 0),
      1
    )
  ) |>
  dplyr::select(
    "age",
    "continent",
    "modularity_q"
  )

if (
  base::nrow(data_modularity_temporal) == 0L
) {
  cli::cli_abort(
    "No finite modularity Q values were found in temporal stores."
  )
}

data_network_size_temporal <-
  data_modularity_temporal |>
  dplyr::left_join(
    y = data_temporal_inventory,
    by = dplyr::join_by(continent),
    multiple = "all"
  ) |>
  dplyr::mutate(
    target_name = stringr::str_glue("data_model_input_timeslice_{age}")
  ) |>
  dplyr::select(
    "continent",
    "age",
    "store_path",
    "target_name"
  ) |>
  purrr::pmap(
    .f = function(continent, age, store_path, target_name) {
      data_model_input <-
        purrr::possibly(
          .f = targets::tar_read_raw,
          otherwise = NULL
        )(
          name = target_name,
          store = store_path
        )

      if (
        base::is.null(data_model_input)
      ) {
        return(NULL)
      }

      data_community_to_fit <-
        data_model_input |>
        purrr::chuck("data_community_to_fit")

      data_binary_network <-
        data_community_to_fit > 0

      tibble::tibble(
        age = age,
        continent = continent,
        network_samples = base::nrow(data_binary_network),
        network_taxa = base::ncol(data_binary_network),
        network_links = base::sum(data_binary_network, na.rm = TRUE)
      )
    }
  ) |>
  purrr::compact() |>
  purrr::list_rbind()

if (
  base::is.null(data_network_size_temporal) ||
    base::nrow(data_network_size_temporal) == 0L
) {
  cli::cli_abort(
    "No temporal model input matrices were readable for network sizes."
  )
}

data_temporal_plot <-
  dplyr::inner_join(
    x = data_modularity_temporal,
    y = data_network_size_temporal,
    by = dplyr::join_by(
      age,
      continent
    )
  ) |>
  dplyr::filter(
    base::is.finite(.data$network_links),
    .data$network_links > 0,
    base::is.finite(.data$modularity_q)
  ) |>
  dplyr::mutate(
    continent = base::factor(
      .data$continent,
      levels = vec_continent_levels
    ),
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
    "No shared age points between modularity and network-size data."
  )
}

#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

figure_temporal_network_size_modularity <-
  data_temporal_plot |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$network_links,
      y = .data$modularity_q
    )
  ) +
  ggplot2::facet_wrap(
    facets = ggplot2::vars(continent),
    nrow = 1
  ) +
  ggplot2::scale_colour_manual(
    values = vec_continent_colours,
    name = NULL
  ) +
  ggplot2::scale_fill_gradient(
    low = vec_oracle_palette[["surface_alt"]],
    high = vec_oracle_palette[["muted"]],
    name = "Age (kyr BP)",
    trans = "reverse",
    breaks = scales::pretty_breaks(n = 5)
  ) +
  ggplot2::scale_size_continuous(
    range = base::c(1, 3),
    breaks = base::c(
      10,
      30,
      50
    ),
    name = "Taxa"
  ) +
  ggplot2::scale_x_continuous(
    trans = "log10",
    breaks = base::c(
      100,
      350,
      1000,
      3000
    ),
    labels = scales::label_number(
      scale = 0.001,
      suffix = "k",
      accuracy = 0.1
    ),
    expand = ggplot2::expansion(mult = base::c(0.04, 0.08))
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 0.5),
    breaks = base::seq(0, 0.5, by = 0.1),
    expand = ggplot2::expansion(mult = base::c(0.02, 0.02))
  ) +
  ggplot2::guides(
    colour = "none",
    fill = ggplot2::guide_colourbar(
      barheight = grid::unit(2.4, "cm"),
      barwidth = grid::unit(0.45, "cm"),
      title.position = "top"
    ),
    size = ggplot2::guide_legend(
      override.aes = base::list(
        colour = vec_oracle_palette[["phosphor"]],
        fill = vec_oracle_palette[["background"]]
      )
    )
  ) +
  ggplot2::labs(
    x = "Network size (sample-taxon links, log10 scale)",
    y = "Network modularity Q"
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
    axis.text.x = ggplot2::element_text(
      angle = 25,
      hjust = 1,
      vjust = 1
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
    strip.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.25
    ),
    strip.text = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 13,
      face = "bold"
    ),
    panel.spacing.x = grid::unit(0.55, "lines"),
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
      fill = .data$age_kyr_bp,
      size = .data$network_taxa
    ),
    shape = 21,
    stroke = 0.35,
    alpha = 0.95
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = vec_oracle_palette[["phosphor"]],
    linewidth = 1,
    alpha = 0.9
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_temporal_network_size_modularity,
  file = base::file.path(
    path_output,
    "slide_extra_03_temporal_network_size_modularity.png"
  ),
  device = ragg::agg_png
)

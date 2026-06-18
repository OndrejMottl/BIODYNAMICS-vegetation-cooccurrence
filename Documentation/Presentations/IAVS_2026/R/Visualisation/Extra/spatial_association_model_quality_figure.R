#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Extra slide spatial association-model quality figure
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

vec_scale_levels <-
  base::c(
    "continental",
    "regional",
    "local"
  )

vec_scale_labels <-
  base::c(
    "continental" = "Continental",
    "regional" = "Regional",
    "local" = "Local"
  )

vec_resolution_labels <-
  base::c(
    "genus" = "Genus",
    "family" = "Family",
    "functional_type" = "Func. type"
  )

vec_resolution_colours <-
  base::c(
    "Genus" = vec_oracle_palette[["cyan"]],
    "Family" = vec_oracle_palette[["amber"]],
    "Func. type" = vec_oracle_palette[["purple"]]
  )

vec_continent_shapes <-
  base::c(
    "america" = 22,
    "asia" = 24,
    "europe" = 21
  )


#----------------------------------------------------------#
# 1. Load spatial model outputs -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "paleo"
  )

data_spatial_results <-
  read_spatial_model_results(
    store_index = data_store_index,
    resolution_ids = base::names(vec_resolution_labels),
    require_non_empty = TRUE
  ) |>
  dplyr::mutate(
    continent_id = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data", "Input", "spatial_grid.csv")
    )
  )

data_association_variance <-
  data_spatial_results |>
  dplyr::filter(
    .data$component == "Associations",
    base::is.finite(.data$R2_Nagelkerke_percentage)
  ) |>
  dplyr::mutate(
    association_variance = base::pmax(
      .data$R2_Nagelkerke_percentage,
      0
    )
  ) |>
  dplyr::select(
    "data_source",
    "scale",
    "scale_id",
    "continent_id",
    "resolution_id",
    "association_variance",
    "auc_mean"
  )

data_model_quality <-
  data_store_index |>
  dplyr::filter(
    .data$store_exists
  ) |>
  dplyr::select(
    "scale",
    "scale_id",
    "store_path"
  ) |>
  tidyr::crossing(
    resolution_id = base::names(vec_resolution_labels)
  ) |>
  purrr::pmap(
    .f = function(scale, scale_id, store_path, resolution_id) {
      model_evaluation <-
        purrr::possibly(
          .f = targets::tar_read_raw,
          otherwise = NULL
        )(
          name = stringr::str_glue("model_evaluation_{resolution_id}"),
          store = store_path
        )

      if (
        base::is.null(model_evaluation)
      ) {
        return(NULL)
      }

      vec_r2_nagelkerke <-
        purrr::pluck(
          model_evaluation,
          "model",
          "R2-Nagelkerke",
          .default = NA_real_
        ) |>
        base::as.numeric()

      vec_r2_mcfadden <-
        purrr::pluck(
          model_evaluation,
          "model",
          "R2-McFadden",
          .default = NA_real_
        ) |>
        base::as.numeric()

      tibble::tibble(
        scale = scale,
        scale_id = scale_id,
        resolution_id = resolution_id,
        model_r2_nagelkerke = base::mean(
          vec_r2_nagelkerke[base::is.finite(vec_r2_nagelkerke)],
          na.rm = TRUE
        ),
        model_r2_mcfadden = base::mean(
          vec_r2_mcfadden[base::is.finite(vec_r2_mcfadden)],
          na.rm = TRUE
        )
      )
    }
  ) |>
  purrr::compact() |>
  purrr::list_rbind()

if (
  base::is.null(data_model_quality) ||
    base::nrow(data_model_quality) == 0L
) {
  cli::cli_abort(
    "No spatial model evaluation targets were readable."
  )
}


#----------------------------------------------------------#
# 2. Prepare plot data -----
#----------------------------------------------------------#

data_quality_plot <-
  data_association_variance |>
  dplyr::inner_join(
    y = data_model_quality,
    by = dplyr::join_by(
      scale,
      scale_id,
      resolution_id
    ),
    multiple = "error"
  ) |>
  dplyr::filter(
    base::is.finite(.data$model_r2_nagelkerke),
    .data$model_r2_nagelkerke >= 0,
    .data$model_r2_nagelkerke <= 1,
    base::is.finite(.data$association_variance)
  ) |>
  dplyr::mutate(
    scale = base::factor(
      .data$scale,
      levels = vec_scale_levels
    ),
    scale_label = dplyr::recode(
      .x = .data$scale,
      !!!vec_scale_labels
    ),
    scale_label = base::factor(
      .data$scale_label,
      levels = vec_scale_labels
    ),
    resolution_label = dplyr::recode(
      .x = .data$resolution_id,
      !!!vec_resolution_labels
    ),
    resolution_label = base::factor(
      .data$resolution_label,
      levels = vec_resolution_labels
    ),
    continent_label = stringr::str_to_title(.data$continent_id)
  )

if (
  base::nrow(data_quality_plot) == 0L
) {
  cli::cli_abort(
    "No paired association-variance and model-R2 values were found."
  )
}


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

figure_spatial_association_quality <-
  data_quality_plot |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$model_r2_nagelkerke,
      y = .data$association_variance
    )
  ) +
  ggplot2::facet_wrap(
    facets = ggplot2::vars(resolution_label),
    nrow = 1
  ) +
  ggplot2::scale_fill_manual(
    values = vec_resolution_colours,
    name = NULL
  ) +
  ggplot2::scale_shape_manual(
    values = vec_continent_shapes,
    name = NULL
  ) +
  ggplot2::scale_size_manual(
    values = base::c(
      "continental" = 3.8,
      "regional" = 2.8,
      "local" = 1.8
    ),
    breaks = vec_scale_levels,
    labels = vec_scale_labels,
    name = "Spatial scale"
  ) +
  ggplot2::scale_x_continuous(
    limits = base::c(0, 1),
    breaks = base::seq(0, 1, by = 0.25),
    labels = scales::label_percent(accuracy = 1),
    expand = ggplot2::expansion(mult = base::c(0.04, 0.08))
  ) +
  ggplot2::scale_y_continuous(
    breaks = scales::breaks_pretty(n = 5),
    labels = scales::label_number(suffix = "%"),
    expand = ggplot2::expansion(mult = base::c(0.02, 0.04))
  ) +
  ggplot2::guides(
    fill = "none",
    shape = ggplot2::guide_legend(
      override.aes = base::list(
        fill = vec_oracle_palette[["background"]],
        colour = vec_oracle_palette[["phosphor"]],
        size = 3
      )
    )
  ) +
  ggplot2::labs(
    x = "Model R2 (Nagelkerke)",
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
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 12
    ),
    axis.title.x = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 12
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
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = vec_oracle_palette[["phosphor"]],
    linewidth = 0.85,
    linetype = "dashed",
    alpha = 0.9
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      shape = .data$continent_id,
      size = .data$scale
    ),
    colour = vec_oracle_palette[["phosphor"]],
    fill = vec_oracle_palette[["muted"]],
    stroke = 0.18,
    alpha = 0.9
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_spatial_association_quality,
  file = base::file.path(
    path_output,
    "slide_extra_02_spatial_association_model_quality.png"
  ),
  device = ragg::agg_png
)

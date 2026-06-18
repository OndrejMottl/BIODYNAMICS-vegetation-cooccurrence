#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Extra slide climate parameters and AUC figure
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

selected_scale <- "continental"
selected_scale_id <- "europe"
selected_resolution_id <- "genus"

vec_climate_terms <-
  base::c(
    "bio1",
    "bio4",
    "bio15",
    "bio18",
    "bio19",
    "bio1:age",
    "bio4:age",
    "bio15:age",
    "bio18:age",
    "bio19:age"
  )


#----------------------------------------------------------#
# 1. Load model targets -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "paleo"
  ) |>
  dplyr::filter(
    .data$scale == selected_scale,
    .data$scale_id == selected_scale_id,
    .data$store_exists
  )

if (
  base::nrow(data_store_index) != 1L
) {
  cli::cli_abort(
    c(
      "Could not resolve one spatial target store.",
      "i" = stringr::str_glue(
        "Requested scale_id: {selected_scale_id}; scale: {selected_scale}."
      )
    )
  )
}

store_path <-
  data_store_index |>
  dplyr::pull(
    "store_path"
  )

model_jsdm <-
  targets::tar_read_raw(
    name = stringr::str_glue(
      "model_jsdm_selected_{selected_resolution_id}"
    ),
    store = store_path
  )

model_evaluation <-
  targets::tar_read_raw(
    name = stringr::str_glue(
      "model_evaluation_{selected_resolution_id}"
    ),
    store = store_path
  )

data_model_input <-
  targets::tar_read_raw(
    name = stringr::str_glue(
      "data_model_input_{selected_resolution_id}"
    ),
    store = store_path
  )


#----------------------------------------------------------#
# 2. Prepare parameter and AUC data -----
#----------------------------------------------------------#

data_community_matrix <-
  data_model_input |>
  purrr::chuck(
    "data_community_to_fit"
  )

vec_taxa <-
  data_community_matrix |>
  base::colnames()

vec_common_taxa <-
  colSums(data_community_matrix) |>
  sort(decreasing = TRUE) |>
  names() |>
  head(10L)

vec_terms <-
  model_jsdm |>
  purrr::chuck("names")

matrix_coefficients <-
  stats::coef(model_jsdm) |>
  purrr::chuck("env", 1)

matrix_standard_errors <-
  model_jsdm |>
  purrr::chuck("se")

if (
  !base::identical(
    base::dim(matrix_coefficients),
    base::rev(base::dim(matrix_standard_errors))
  )
) {
  cli::cli_abort(
    "Coefficient and standard-error dimensions do not match."
  )
}

data_coefficients <-
  matrix_coefficients |>
  tibble::as_tibble(
    .name_repair = ~vec_terms
  ) |>
  dplyr::mutate(
    taxon = vec_taxa,
    .before = 1
  ) |>
  tidyr::pivot_longer(
    cols = -"taxon",
    names_to = "term",
    values_to = "estimate"
  )

data_standard_errors <-
  matrix_standard_errors |>
  base::t() |>
  tibble::as_tibble(
    .name_repair = ~vec_terms
  ) |>
  dplyr::mutate(
    taxon = vec_taxa,
    .before = 1
  ) |>
  tidyr::pivot_longer(
    cols = -"taxon",
    names_to = "term",
    values_to = "standard_error"
  )

data_auc <-
  model_evaluation |>
  purrr::chuck("species") |>
  dplyr::mutate(
    taxon = .data$species,
    auc = base::as.numeric(.data$AUC)
  ) |>
  dplyr::select(
    "taxon",
    "auc"
  )

data_parameter_plot <-
  data_coefficients |>
  dplyr::inner_join(
    y = data_standard_errors,
    by = dplyr::join_by(
      taxon,
      term
    ),
    multiple = "error"
  ) |>
  dplyr::inner_join(
    y = data_auc,
    by = dplyr::join_by(taxon),
    multiple = "error"
  ) |>
  dplyr::filter(
    .data$term %in% vec_climate_terms,
    base::is.finite(.data$estimate),
    base::is.finite(.data$standard_error),
    .data$standard_error > 0
  ) |>
  dplyr::mutate(
    term_label = stringr::str_replace_all(
      string = .data$term,
      pattern = ":",
      replacement = " x "
    )
  )

if (
  base::nrow(data_parameter_plot) == 0L
) {
  cli::cli_abort(
    "No finite climate parameter estimates were available."
  )
}

vec_taxon_order <-
  data_auc |>
  dplyr::filter(
    .data$taxon %in% data_parameter_plot[["taxon"]],
    .data$taxon %in% vec_common_taxa
  ) |>
  dplyr::arrange(
    .data$auc,
    .data$taxon
  ) |>
  dplyr::pull(
    .data$taxon
  )

data_to_plot_parameter <-
  data_parameter_plot |>
  dplyr::filter(
    .data$taxon %in% vec_common_taxa
  ) |>
  dplyr::mutate(
    taxon = base::factor(
      .data$taxon,
      levels = vec_taxon_order
    ),
    term_complexity = dplyr::case_when(
      stringr::str_detect(
        string = .data$term,
        pattern = ":"
      ) ~ "interaction",
      TRUE ~ "main_effect"
    ),
    term_simple = stringr::str_remove(
      string = .data$term,
      pattern = ":age"
    ),
    term_translated = dplyr::case_when(
      .data$term_simple == "bio1" ~ "MAT",
      .data$term_simple == "bio4" ~ "TempSeason",
      .data$term_simple == "bio15" ~ "PrecipSeason",
      .data$term_simple == "bio18" ~ "PrecWarmQ",
      .data$term_simple == "bio19" ~ "PrecColdQ",
      TRUE ~ .data$term_simple
    ),
    term_simple_label = base::factor(
      .data$term_translated,
      levels = c(
        "MAT",
        "TempSeason",
        "PrecipSeason",
        "PrecWarmQ",
        "PrecColdQ"
      )
    ),
    term_label = base::factor(
      .data$term_label,
      levels = stringr::str_replace_all(
        string = vec_climate_terms,
        pattern = ":",
        replacement = " x "
      )
    )
  )

data_to_plot_auc <-
  data_auc |>
  dplyr::filter(
    .data$taxon %in% vec_common_taxa,
    base::is.finite(.data$auc)
  ) |>
  dplyr::mutate(
    taxon = base::factor(
      .data$taxon,
      levels = vec_taxon_order
    )
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

plot_parameters <-
  data_to_plot_parameter |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$estimate,
      y = .data$taxon,
      group = .data$term_complexity
    )
  ) +
  ggplot2::facet_wrap(
    facets = "term_simple_label",
    nrow = 1,
    strip.position = "top"
  ) +
  ggplot2::labs(
    x = "Model-scale parameter estimate +- SE",
    y = NULL
  ) +
  ggview::canvas(
    width = 1300,
    height = 800,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  create_oracle_theme(
    base_family = font_family,
    base_size = 8.5
  ) +
  ggplot2::scale_shape_manual(
    values = c(
      "main_effect" = 5,
      "interaction" = 9
    ),
    name = "Term complexity",
    labels = c(
      "main_effect" = "Main effect",
      "interaction" = "Interaction with age"
    )
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
    panel.grid = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.1,
      linetype = "dashed"
    ),
    axis.text.x = ggplot2::element_text(
      colour = vec_oracle_palette[["cyan"]],
      angle = 45,
      hjust = 1,
      vjust = 1,
      size = 7.2
    ),
    panel.border = ggplot2::element_rect(
      fill = NA,
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.35
    ),
    axis.text.y = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 5.3
    ),
    legend.position = "bottom",
    legend.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.key = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.title = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 8.4
    ),
    legend.text = ggplot2::element_text(
      colour = vec_oracle_palette[["text"]],
      size = 7.5
    ),
    plot.margin = ggplot2::margin(4, 3, 4, 4)
  ) +
  ggplot2::geom_linerange(
    mapping = ggplot2::aes(
      xmin = .data$estimate - .data$standard_error,
      xmax = .data$estimate + .data$standard_error
    ),
    orientation = "y",
    position = ggplot2::position_dodge(width = 0.6),
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.22,
    alpha = 0.8
  ) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.35,
    alpha = 0.8
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      shape = .data$term_complexity
    ),
    position = ggplot2::position_dodge(width = 0.6),
    colour = vec_oracle_palette[["phosphor"]],
    fill = vec_oracle_palette[["phosphor"]],
    stroke = 0.12
  )

plot_auc <-
  data_to_plot_auc |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$auc,
      y = .data$taxon
    )
  ) +
  ggplot2::scale_x_continuous(
    limits = base::c(0.5, 1),
    breaks = base::c(0.5, 0.75, 1),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::labs(
    x = "AUC",
    y = NULL
  ) +
  ggview::canvas(
    width = 380,
    height = 820,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  create_oracle_theme(
    base_family = font_family,
    base_size = 8.5
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
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.2
    ),
    panel.grid.minor = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 7.5
    ),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 8.5
    ),
    plot.margin = ggplot2::margin(4, 4, 4, 0)
  ) +
  ggplot2::geom_vline(
    xintercept = 0.5,
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.35
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = 0.5,
      xend = .data$auc,
      yend = .data$taxon
    ),
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.22,
    alpha = 0.8
  ) +
  ggplot2::geom_point(
    fill = vec_oracle_palette[["cyan"]],
    colour = vec_oracle_palette[["background"]],
    shape = 21,
    size = 1.5,
    stroke = 0.12,
    alpha = 0.95
  )

figure_spatial_climate_parameters_auc <-
  cowplot::plot_grid(
    plot_parameters,
    plot_auc,
    nrow = 1,
    rel_widths = base::c(1.8, 0.55),
    align = "h",
    axis = "tb"
  ) +
  ggview::canvas(
    width = 1500,
    height = 820,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_spatial_climate_parameters_auc,
  file = base::file.path(
    path_output,
    "slide_extra_04_spatial_climate_parameters_auc.png"
  ),
  device = ragg::agg_png
)

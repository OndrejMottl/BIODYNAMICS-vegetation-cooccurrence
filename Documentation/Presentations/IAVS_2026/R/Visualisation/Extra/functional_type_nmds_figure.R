#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Extra slide functional type NMDS figure
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


#----------------------------------------------------------#
# 1. Load targets -----
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
      "Could not resolve one Europe continental spatial store.",
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

dist_ft_continental <-
  targets::tar_read_raw(
    name = "dist_ft_continental",
    store = store_path
  )

data_ft_classification <-
  targets::tar_read_raw(
    name = "ft_result_continental_unit",
    store = store_path
  ) |>
  dplyr::mutate(
    functional_type = base::as.integer(.data$functional_type)
  )


#----------------------------------------------------------#
# 2. Prepare ordination and labels -----
#----------------------------------------------------------#

if (
  !base::inherits(dist_ft_continental, "dist")
) {
  cli::cli_abort(
    "`dist_ft_continental` must inherit from class {.cls dist}."
  )
}

data_ft_counts <-
  data_ft_classification |>
  dplyr::count(
    .data$functional_type,
    name = "n_taxa"
  )

vec_functional_type_keep <-
  data_ft_counts |>
  dplyr::filter(
    .data$n_taxa > 1L
  ) |>
  dplyr::pull(
    "functional_type"
  )

data_ft_classification_filtered <-
  data_ft_classification |>
  dplyr::filter(
    .data$functional_type %in% vec_functional_type_keep
  )

vec_taxa_keep <-
  data_ft_classification_filtered |>
  dplyr::pull(
    "taxon_name"
  )

dist_ft_continental_filtered <-
  stats::as.dist(
    base::as.matrix(dist_ft_continental)[vec_taxa_keep, vec_taxa_keep]
  )

if (
  base::attr(dist_ft_continental_filtered, "Size") < 3L
) {
  cli::cli_abort(
    "Too few taxa remain after removing singleton functional types."
  )
}

base::set.seed(900723)

nmds_result <-
  vegan::metaMDS(
    comm = dist_ft_continental_filtered,
    k = 2L,
    try = 30L,
    trymax = 120L,
    autotransform = FALSE,
    trace = FALSE,
    pc = TRUE
  )

data_nmds_scores <-
  vegan::scores(
    x = nmds_result,
    display = "sites"
  )

data_nmds <-
  data_nmds_scores |>
  tibble::as_tibble(
    .name_repair = ~base::c("nmds_1", "nmds_2")
  ) |>
  dplyr::mutate(
    taxon_name = base::rownames(data_nmds_scores),
    .before = 1
  ) |>
  dplyr::inner_join(
    y = data_ft_classification_filtered,
    by = dplyr::join_by(taxon_name),
    multiple = "error"
  ) |>
  dplyr::mutate(
    functional_type_label = stringr::str_glue(
      "FT {functional_type}"
    )
  )

if (
  base::nrow(data_nmds) != base::attr(dist_ft_continental_filtered, "Size")
) {
  cli::cli_abort(
    "Some NMDS taxa could not be joined to functional-type labels."
  )
}

data_ft_names <-
  tibble::tribble(
    ~functional_type, ~functional_type_name,
    1L, "mixed forest woody taxa",
    2L, "Acacia tree outlier",
    3L, "large-seeded horse chestnut",
    4L, "ericoid evergreen shrubs",
    5L, "thorny dryland shrubs",
    6L, "broom legumes",
    7L, "large nut trees",
    8L, "mesic broadleaf trees",
    9L, "palms and carob",
    10L, "dwarf palm",
    11L, "tall small-leaved shrubs",
    12L, "leafless xeric shrubs",
    13L, "large-leaved woody climbers",
    14L, "montane evergreen trees",
    15L, "succulent dwarf shrubs",
    16L, "hemiparasitic shrubs"
  )

data_ft_centroids <-
  data_nmds |>
  dplyr::group_by(
    .data$functional_type,
    .data$functional_type_label
  ) |>
  dplyr::summarise(
    nmds_1 = stats::median(.data$nmds_1),
    nmds_2 = stats::median(.data$nmds_2),
    n_taxa = dplyr::n(),
    silhouette_width = stats::median(
      .data$silhouette_width,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::inner_join(
    y = data_ft_names,
    by = dplyr::join_by(functional_type),
    multiple = "error"
  ) |>
  dplyr::mutate(
    label = stringr::str_glue(
      "{functional_type_label}: {functional_type_name}"
    )
  )

if (
  dplyr::n_distinct(data_ft_centroids[["functional_type"]]) !=
    dplyr::n_distinct(data_nmds[["functional_type"]])
) {
  cli::cli_abort(
    "FT centroid labels do not cover every functional type."
  )
}

vec_ft_levels <-
  data_nmds |>
  dplyr::distinct(
    .data$functional_type,
    .data$functional_type_label
  ) |>
  dplyr::arrange(
    .data$functional_type
  ) |>
  dplyr::pull(
    "functional_type_label"
  )

vec_ft_palette_source <-
  grDevices::hcl.colors(
    n = base::length(vec_ft_levels),
    palette = "Dark 3"
  )

vec_ft_palette <-
  vec_ft_palette_source |>
  rlang::set_names(vec_ft_levels)

data_nmds_linked <-
  data_nmds |>
  dplyr::left_join(
    y = data_ft_centroids |>
      dplyr::select(
        "functional_type",
        nmds_1_centroid = "nmds_1",
        nmds_2_centroid = "nmds_2",
        "functional_type_name",
        "n_taxa"
    ),
    by = dplyr::join_by(functional_type),
    relationship = "many-to-one"
  )

if (
  base::any(!base::is.finite(data_nmds_linked[["nmds_1_centroid"]])) ||
    base::any(!base::is.finite(data_nmds_linked[["nmds_2_centroid"]]))
) {
  cli::cli_abort(
    "Some NMDS taxa could not be linked to their FT centroid."
  )
}

data_ft_centroid_labels <-
  data_ft_centroids |>
  dplyr::arrange(
    dplyr::desc(.data$n_taxa),
    .data$functional_type
  ) |>
  dplyr::slice_head(
    n = 4L
  ) |>
  dplyr::mutate(
    centroid_label = stringr::str_glue(
      "{functional_type_label}: {functional_type_name}"
    )
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

plot_ordination <-
  data_nmds_linked |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$nmds_1,
      y = .data$nmds_2
    )
  ) +
  ggplot2::geom_hline(
    yintercept = 0,
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.22,
    alpha = 0.55
  ) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.22,
    alpha = 0.55
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      xend = .data$nmds_1_centroid,
      yend = .data$nmds_2_centroid,
      colour = .data$functional_type_label
    ),
    linewidth = 0.2,
    alpha = 0.2,
    show.legend = FALSE
  ) +
  ggplot2::geom_point(
    mapping = ggplot2::aes(
      fill = .data$functional_type_label
    ),
    colour = vec_oracle_palette[["background"]],
    shape = 21,
    size = 1,
    stroke = 0.12,
    alpha = 0.78
  ) +
  ggplot2::geom_point(
    data = data_ft_centroids,
    mapping = ggplot2::aes(
      color = .data$functional_type_label
    ),
    shape = 15,
    size = 2,
    stroke = 0.5,
    alpha = 1
  ) +
  ggrepel::geom_label_repel(
    data = data_ft_centroid_labels,
    mapping = ggplot2::aes(
      label = .data$centroid_label,
      color = .data$functional_type_label
    ),
    family = font_family,
    #colour = vec_oracle_palette[["text"]],
    fill = vec_oracle_palette[["background"]],
    label.size = 0.18,
    label.r = grid::unit(0.06, "lines"),
    label.padding = grid::unit(0.2, "lines"),
    segment.colour = vec_oracle_palette[["muted"]],
    segment.size = 0.18,
    size = 2,
    box.padding = 0.35,
    point.padding = 0.55,
    min.segment.length = 0,
    max.overlaps = Inf,
    seed = 23,
    show.legend = FALSE
  ) +
  ggplot2::scale_fill_manual(
    values = vec_ft_palette,
    breaks = vec_ft_levels,
    name = "Functional type"
  ) +
  ggplot2::scale_colour_manual(
    values = vec_ft_palette,
    breaks = vec_ft_levels,
    guide = "none"
  ) +
  ggplot2::labs(
    x = stringr::str_glue(
      "NMDS 1 (stress {base::round(nmds_result[['stress']], 2)})"
    ),
    y = "NMDS 2"
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
    base_size = 10.5
  ) +
  ggplot2::coord_cartesian(
    clip = "off"
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
    panel.border = ggplot2::element_rect(
      fill = NA,
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.35
    ),
    panel.grid.major = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.12,
      linetype = "dashed"
    ),
    panel.grid.minor = ggplot2::element_blank(),
    axis.title = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 13
    ),
    axis.text = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 10
    ),
    legend.position = "none",
    plot.margin = ggplot2::margin(8, 8, 8, 12)
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = plot_ordination,
  file = base::file.path(
    path_output,
    "slide_extra_05_functional_type_nmds.png"
  ),
  device = ragg::agg_png
)

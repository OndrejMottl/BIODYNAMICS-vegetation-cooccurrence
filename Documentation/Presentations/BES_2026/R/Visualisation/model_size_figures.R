#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Model-size section figures (association share and
#         the number of taxa in a model)
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Ports the matrix-size analyses of the Round 0 report
#   (Documentation/Reports/Third_report/_Project_status_and_direction.qmd,
#   chunks model-matrix-size, compare-tier-gradient, fit-climate-balance
#   and fit-nested-extent) to the ORACLE slide style. Reads the October
#   2026 fossil-pollen unit table and the 6 November 2026 per-taxon
#   partition diagnostics. Writes four slide PNGs and one summary table
#   with the values quoted in the speaker notes.

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)

base::source(
  here::here(
    "Documentation",
    "Presentations",
    "BES_2026",
    "R",
    "load_bes_functions.R"
  )
)

load_bes_functions()


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

list_oracle_design <-
  load_design_config(
    path = here::here(
      "Documentation",
      "Presentations",
      "BES_2026",
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
    "BES_2026",
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
    "BES_2026",
    "figures",
    "results"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

file_unit_table <-
  here::here(
    "Outputs",
    "Tables",
    "Visualisation",
    "paleo_variance_partitioning_unit_2026-10-23.csv"
  )

path_taxon_partition <-
  here::here(
    "Outputs",
    "Tables",
    "Diagnostics",
    "Taxon_variance_partition"
  )

# Slide canvas shared by all four figures.
list_canvas <-
  base::list(
    width = 1100,
    height = 700,
    units = "px",
    dpi = 300
  )

vec_tier_levels <-
  base::c("local", "regional", "continental")

vec_tier_labels <-
  base::c(
    "continental" = "CONTINENTAL",
    "regional" = "REGIONAL",
    "local" = "LOCAL"
  )

vec_resolution_levels <-
  base::c("genus", "family", "functional_type")

vec_resolution_labels <-
  base::c(
    "genus" = "Genus",
    "family" = "Family",
    "functional_type" = "Functional type"
  )

# The plotted quantity keeps its semantic colour (association = purple,
#   climate = amber, spatial extent = cyan); categories within a figure
#   are shades of that colour plus a shape and a line type, so the figure
#   also reads in greyscale.
vec_colours_resolution_association <-
  base::c(
    "Genus" = vec_oracle_palette[["purple"]],
    "Family" = "#EBD7F8",
    "Functional type" = "#9468C0"
  )

vec_colours_resolution_climate <-
  base::c(
    "Genus" = vec_oracle_palette[["amber"]],
    "Family" = "#F6EBB4",
    "Functional type" = "#B39A2A"
  )

vec_shapes_resolution <-
  base::c(
    "Genus" = 21,
    "Family" = 22,
    "Functional type" = 24
  )

vec_linetypes_resolution <-
  base::c(
    "Genus" = "solid",
    "Family" = "longdash",
    "Functional type" = "dotted"
  )

# The fitted penalty on the association term, by candidate identifier.
#   build_sjsdm_regularization_candidates() orders the grid by lambda_cov
#   first, so candidates 001-004 leave the association term unpenalised.
vec_candidates_unpenalised_cov <-
  base::c(
    "candidate_001",
    "candidate_002",
    "candidate_003",
    "candidate_004"
  )


#----------------------------------------------------------#
# 1. Load data -----
#----------------------------------------------------------#

data_unit_raw <-
  readr::read_csv(
    file = file_unit_table,
    show_col_types = FALSE
  )

data_share_definitions <-
  readr::read_csv(
    file = base::file.path(
      path_taxon_partition,
      "model_share_definitions_2026-11-06.csv"
    ),
    show_col_types = FALSE
  )

data_nested_extent_raw <-
  readr::read_csv(
    file = base::file.path(
      path_taxon_partition,
      "nested_extent_contrasts_2026-11-06.csv"
    ),
    show_col_types = FALSE
  )


#----------------------------------------------------------#
# 2. Prepare data -----
#----------------------------------------------------------#

# One row per fossil-pollen spatial model with the Nagelkerke share of its
#   explained variance that goes to residual association.
data_association_share <-
  data_unit_raw |>
  dplyr::filter(
    .data[["data_source"]] == "paleo",
    .data[["component"]] == "Associations"
  ) |>
  dplyr::mutate(
    association_share = .data[["R2_Nagelkerke_percentage"]],
    log_n_taxa = base::log(.data[["n_taxa"]]),
    scale = forcats::fct(
      x = .data[["scale"]],
      levels = vec_tier_levels
    ),
    resolution_id = forcats::fct(
      x = .data[["resolution_id"]],
      levels = vec_resolution_levels
    ),
    resolution_label = forcats::fct(
      x = base::unname(
        vec_resolution_labels[base::as.character(.data[["resolution_id"]])]
      ),
      levels = base::unname(vec_resolution_labels)
    ),
    flag_unpenalised_cov = .data[["candidate_id"]] %in%
      vec_candidates_unpenalised_cov
  )

# The same models on the deviance scale, from the per-taxon diagnostic.
data_share_deviance <-
  data_share_definitions |>
  dplyr::filter(
    .data[["data_source"]] == "paleo",
    .data[["scale"]] %in% vec_tier_levels,
    .data[["definition"]] == "deviance_clamped"
  ) |>
  dplyr::mutate(
    association_share = 100 * .data[["association_share"]],
    climate_balance = 100 * .data[["climate_balance"]],
    log_n_taxa = base::log(.data[["n_taxa"]]),
    resolution_label = forcats::fct(
      x = base::unname(
        vec_resolution_labels[.data[["resolution_id"]]]
      ),
      levels = base::unname(vec_resolution_labels)
    )
  )


#--------------------------------------------------#
## 2.1. Association share against taxon number -----
#--------------------------------------------------#

mod_share_taxa <-
  stats::lm(
    formula = association_share ~ log_n_taxa,
    data = data_association_share
  )

mod_share_taxa_unpenalised <-
  stats::lm(
    formula = association_share ~ log_n_taxa,
    data = data_association_share |>
      dplyr::filter(.data[["flag_unpenalised_cov"]])
  )

mod_share_taxa_deviance <-
  stats::lm(
    formula = association_share ~ log_n_taxa,
    data = data_share_deviance
  )

# The model with every design factor, used to adjust the tier medians to
#   an equal number of taxa.
mod_share_full <-
  stats::lm(
    formula = association_share ~
      log_n_taxa + resolution_id + scale + continent_id,
    data = data_association_share
  )


#--------------------------------------------------#
## 2.2. Raw against equal-taxon tier values -----
#--------------------------------------------------#

n_taxa_common <-
  data_association_share |>
  dplyr::pull("n_taxa") |>
  stats::median()

data_tier_raw <-
  data_association_share |>
  dplyr::filter(.data[["resolution_id"]] == "genus") |>
  dplyr::group_by(.data[["scale"]]) |>
  dplyr::summarise(
    share = stats::median(.data[["association_share"]]),
    median_n_taxa = stats::median(.data[["n_taxa"]]),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    estimate = "Raw median"
  )

data_tier_newdata <-
  tidyr::expand_grid(
    scale = forcats::fct(
      x = vec_tier_levels,
      levels = vec_tier_levels
    ),
    resolution_id = forcats::fct(
      x = "genus",
      levels = vec_resolution_levels
    ),
    continent_id = data_association_share |>
      dplyr::distinct(.data[["continent_id"]]) |>
      dplyr::pull("continent_id"),
    log_n_taxa = base::log(n_taxa_common)
  )

data_tier_adjusted <-
  data_tier_newdata |>
  dplyr::mutate(
    share = stats::predict(
      object = mod_share_full,
      newdata = data_tier_newdata
    )
  ) |>
  dplyr::group_by(.data[["scale"]]) |>
  dplyr::summarise(
    share = base::mean(.data[["share"]]),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    estimate = "At equal taxon number"
  )

data_tier_gradient <-
  dplyr::bind_rows(
    data_tier_raw,
    data_tier_adjusted
  ) |>
  dplyr::mutate(
    estimate = forcats::fct(
      x = .data[["estimate"]],
      levels = base::c("Raw median", "At equal taxon number")
    ),
    scale_index = base::as.integer(.data[["scale"]])
  )


#--------------------------------------------------#
## 2.3. Climate balance against taxon number -----
#--------------------------------------------------#

mod_balance_taxa <-
  stats::lm(
    formula = climate_balance ~ log_n_taxa,
    data = data_share_deviance
  )


#--------------------------------------------------#
## 2.4. Same genera across nested extents -----
#--------------------------------------------------#

# Each unit against the unit that contains it, on the genera both models
#   hold (deviance scale, shared fractions split equally).
data_nested_extent <-
  data_nested_extent_raw |>
  dplyr::filter(
    .data[["resolution_id"]] == "genus",
    .data[["definition"]] == "equal_split",
    .data[["transition"]] != "3 local to continental",
    base::is.finite(.data[["association_difference_shared"]])
  ) |>
  dplyr::mutate(
    difference = 100 * .data[["association_difference_shared"]],
    size_ratio = base::exp(.data[["log_size_ratio"]]),
    data_source_label = dplyr::case_when(
      .data[["data_source"]] == "paleo" ~ "Fossil pollen",
      .data[["data_source"]] == "modern" ~ "Modern plots"
    ),
    transition_label = dplyr::case_when(
      .data[["transition"]] == "1 local to regional" ~
        "Local to regional",
      .data[["transition"]] == "2 regional to continental" ~
        "Regional to continental"
    ),
    contrast_id = stringr::str_c(
      .data[["data_source"]],
      .data[["transition"]],
      sep = "_"
    )
  )

# Intercept of the difference on the log size ratio: the difference
#   expected when parent and child models hold equally many taxa.
data_nested_extent_coefficients <-
  data_nested_extent |>
  tidyr::nest(
    data_group = -dplyr::all_of(
      base::c("contrast_id", "data_source_label", "transition_label")
    )
  ) |>
  dplyr::mutate(
    n_units = purrr::map_int(
      .x = .data[["data_group"]],
      .f = ~ base::nrow(.x)
    ),
    n_parents = purrr::map_int(
      .x = .data[["data_group"]],
      .f = ~ dplyr::n_distinct(.x[["scale_id_parent"]])
    ),
    log_size_ratio_max = purrr::map_dbl(
      .x = .data[["data_group"]],
      .f = ~ base::max(.x[["log_size_ratio"]])
    ),
    vec_coefficients = purrr::map(
      .x = .data[["data_group"]],
      .f = ~ stats::coef(
        stats::lm(
          formula = difference ~ log_size_ratio,
          data = .x
        )
      )
    ),
    intercept = purrr::map_dbl(
      .x = .data[["vec_coefficients"]],
      .f = ~ .x[[1L]]
    ),
    slope = purrr::map_dbl(
      .x = .data[["vec_coefficients"]],
      .f = ~ .x[[2L]]
    )
  ) |>
  dplyr::select(
    -"data_group",
    -"vec_coefficients"
  )

data_nested_extent_lines <-
  data_nested_extent_coefficients |>
  dplyr::mutate(
    log_size_ratio = purrr::map(
      .x = .data[["log_size_ratio_max"]],
      .f = ~ base::seq(from = 0, to = .x, length.out = 50)
    )
  ) |>
  tidyr::unnest(cols = "log_size_ratio") |>
  dplyr::mutate(
    size_ratio = base::exp(.data[["log_size_ratio"]]),
    difference = .data[["intercept"]] +
      .data[["slope"]] * .data[["log_size_ratio"]]
  )

data_nested_extent_equal_size <-
  data_nested_extent_coefficients |>
  dplyr::mutate(
    size_ratio = 1,
    difference = .data[["intercept"]]
  )


#----------------------------------------------------------#
# 3. Summary values for the speaker notes -----
#----------------------------------------------------------#

data_model_size_summary <-
  dplyr::bind_rows(
    tibble::tibble(
      quantity = base::c(
        "n_models",
        "n_models_unpenalised_cov",
        "r2_log_taxa_nagelkerke",
        "r2_log_taxa_deviance",
        "r2_log_taxa_nagelkerke_unpenalised_cov",
        "slope_log_taxa_nagelkerke",
        "slope_log_taxa_nagelkerke_unpenalised_cov",
        "r2_climate_balance_log_taxa_deviance",
        "n_taxa_common"
      ),
      group = NA_character_,
      value = base::c(
        base::nrow(data_association_share),
        base::sum(data_association_share[["flag_unpenalised_cov"]]),
        base::summary(mod_share_taxa)[["r.squared"]],
        base::summary(mod_share_taxa_deviance)[["r.squared"]],
        base::summary(mod_share_taxa_unpenalised)[["r.squared"]],
        stats::coef(mod_share_taxa)[["log_n_taxa"]],
        stats::coef(mod_share_taxa_unpenalised)[["log_n_taxa"]],
        base::summary(mod_balance_taxa)[["r.squared"]],
        n_taxa_common
      )
    ),
    data_tier_gradient |>
      dplyr::mutate(
        quantity = stringr::str_c(
          "genus_share_",
          base::as.character(.data[["estimate"]])
        ),
        group = base::as.character(.data[["scale"]]),
        value = .data[["share"]]
      ) |>
      dplyr::select("quantity", "group", "value"),
    data_tier_raw |>
      dplyr::mutate(
        quantity = "genus_median_n_taxa",
        group = base::as.character(.data[["scale"]]),
        value = .data[["median_n_taxa"]]
      ) |>
      dplyr::select("quantity", "group", "value"),
    data_nested_extent_coefficients |>
      dplyr::mutate(
        quantity = "nested_difference_at_equal_size",
        group = stringr::str_c(
          .data[["data_source_label"]],
          .data[["transition_label"]],
          sep = ": "
        ),
        value = .data[["intercept"]]
      ) |>
      dplyr::select("quantity", "group", "value")
  )

readr::write_csv(
  x = data_model_size_summary,
  file = base::file.path(path_output, "model_size_summary.csv")
)


#----------------------------------------------------------#
# 4. Shared slide theme -----
#----------------------------------------------------------#

theme_model_size <-
  build_oracle_theme(
    base_family = font_family,
    base_size = 9
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
    panel.grid.major = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.22
    ),
    panel.grid.minor = ggplot2::element_blank(),
    axis.line = ggplot2::element_line(
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.28
    ),
    axis.text = ggplot2::element_text(
      colour = vec_oracle_palette[["muted"]],
      size = 8
    ),
    axis.title.x = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 8.5
    ),
    strip.text = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 9
    ),
    legend.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.key = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    legend.key.width = ggplot2::unit(2.2, "lines"),
    legend.text = ggplot2::element_text(
      colour = vec_oracle_palette[["text"]],
      size = 8
    ),
    plot.margin = ggplot2::margin(6, 10, 4, 4)
  )


#----------------------------------------------------------#
# 5. Figure A: association share against taxa -----
#----------------------------------------------------------#

plot_share_taxa <-
  data_association_share |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["n_taxa"]],
      y = .data[["association_share"]],
      colour = .data[["resolution_label"]],
      fill = .data[["resolution_label"]],
      shape = .data[["resolution_label"]],
      linetype = .data[["resolution_label"]]
    )
  ) +
  ggplot2::scale_x_continuous(
    transform = "log",
    breaks = base::c(3, 5, 10, 20, 50)
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_colour_manual(
    values = vec_colours_resolution_association
  ) +
  ggplot2::scale_fill_manual(
    values = vec_colours_resolution_association
  ) +
  ggplot2::scale_shape_manual(
    values = vec_shapes_resolution
  ) +
  ggplot2::scale_linetype_manual(
    values = vec_linetypes_resolution
  ) +
  ggplot2::labs(
    x = "Taxa in the model (log scale)",
    y = "Association\nshare",
    colour = NULL,
    fill = NULL,
    shape = NULL,
    linetype = NULL
  ) +
  theme_model_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 8.5,
      lineheight = 0.82
    ),
    legend.position = "bottom"
  ) +
  ggview::canvas(
    width = list_canvas[["width"]],
    height = list_canvas[["height"]],
    units = list_canvas[["units"]],
    dpi = list_canvas[["dpi"]],
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::geom_point(
    colour = vec_oracle_palette[["background"]],
    size = 1.6,
    stroke = 0.15,
    alpha = 0.85
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    linewidth = 0.8
  )

ggview::save_ggplot(
  plot = plot_share_taxa,
  file = base::file.path(
    path_output,
    "slide_model_size_a_share_taxa.png"
  ),
  device = ragg::agg_png
)


#----------------------------------------------------------#
# 6. Figure B: climate balance against taxa -----
#----------------------------------------------------------#

plot_climate_balance <-
  data_share_deviance |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["n_taxa"]],
      y = .data[["climate_balance"]],
      colour = .data[["resolution_label"]],
      fill = .data[["resolution_label"]],
      shape = .data[["resolution_label"]],
      linetype = .data[["resolution_label"]]
    )
  ) +
  ggplot2::scale_x_continuous(
    transform = "log",
    breaks = base::c(3, 5, 10, 20, 50)
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(0, 100),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_colour_manual(
    values = vec_colours_resolution_climate
  ) +
  ggplot2::scale_fill_manual(
    values = vec_colours_resolution_climate
  ) +
  ggplot2::scale_shape_manual(
    values = vec_shapes_resolution
  ) +
  ggplot2::scale_linetype_manual(
    values = vec_linetypes_resolution
  ) +
  ggplot2::labs(
    x = "Taxa in the model (log scale)",
    y = "Climate /\n(climate + space)",
    colour = NULL,
    fill = NULL,
    shape = NULL,
    linetype = NULL
  ) +
  theme_model_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["amber"]],
      size = 8.5,
      lineheight = 0.82
    ),
    legend.position = "bottom"
  ) +
  ggview::canvas(
    width = list_canvas[["width"]],
    height = list_canvas[["height"]],
    units = list_canvas[["units"]],
    dpi = list_canvas[["dpi"]],
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::geom_point(
    colour = vec_oracle_palette[["background"]],
    size = 1.6,
    stroke = 0.15,
    alpha = 0.85
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    linewidth = 0.8
  )

ggview::save_ggplot(
  plot = plot_climate_balance,
  file = base::file.path(
    path_output,
    "slide_model_size_b_climate_balance.png"
  ),
  device = ragg::agg_png
)


#----------------------------------------------------------#
# 7. Figure C: raw against equal-taxon tier values -----
#----------------------------------------------------------#

plot_tier_gradient <-
  data_tier_gradient |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["scale_index"]],
      y = .data[["share"]],
      colour = .data[["estimate"]],
      shape = .data[["estimate"]],
      linetype = .data[["estimate"]],
      group = .data[["estimate"]]
    )
  ) +
  ggplot2::scale_x_continuous(
    breaks = base::seq_along(vec_tier_levels),
    labels = base::unname(vec_tier_labels[vec_tier_levels]),
    expand = ggplot2::expansion(mult = 0.12)
  ) +
  ggplot2::scale_y_continuous(
    limits = base::c(15, 45),
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_colour_manual(
    values = base::c(
      "Raw median" = vec_oracle_palette[["muted"]],
      "At equal taxon number" = vec_oracle_palette[["purple"]]
    )
  ) +
  ggplot2::scale_shape_manual(
    values = base::c(
      "Raw median" = 16,
      "At equal taxon number" = 15
    )
  ) +
  ggplot2::scale_linetype_manual(
    values = base::c(
      "Raw median" = "longdash",
      "At equal taxon number" = "solid"
    )
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Association\nshare (genus)",
    colour = NULL,
    shape = NULL,
    linetype = NULL
  ) +
  theme_model_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 8.5,
      lineheight = 0.82
    ),
    axis.text.x = ggplot2::element_text(
      colour = vec_oracle_palette[["cyan"]],
      size = 8.5
    ),
    panel.grid.major.x = ggplot2::element_blank(),
    legend.position = "bottom"
  ) +
  ggview::canvas(
    width = list_canvas[["width"]],
    height = list_canvas[["height"]],
    units = list_canvas[["units"]],
    dpi = list_canvas[["dpi"]],
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::geom_line(
    linewidth = 0.9
  ) +
  ggplot2::geom_point(
    size = 2.6
  )

ggview::save_ggplot(
  plot = plot_tier_gradient,
  file = base::file.path(
    path_output,
    "slide_model_size_c_equal_taxa.png"
  ),
  device = ragg::agg_png
)


#----------------------------------------------------------#
# 8. Figure D: same genera across nested extents -----
#----------------------------------------------------------#

vec_colours_transition <-
  base::c(
    "Local to regional" = vec_oracle_palette[["cyan"]],
    "Regional to continental" = "#B6F1F5"
  )

vec_shapes_transition <-
  base::c(
    "Local to regional" = 21,
    "Regional to continental" = 24
  )

vec_linetypes_transition <-
  base::c(
    "Local to regional" = "solid",
    "Regional to continental" = "longdash"
  )

plot_nested_extent <-
  data_nested_extent |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["size_ratio"]],
      y = .data[["difference"]],
      colour = .data[["transition_label"]],
      fill = .data[["transition_label"]],
      shape = .data[["transition_label"]],
      linetype = .data[["transition_label"]]
    )
  ) +
  ggplot2::facet_wrap(
    facets = ggplot2::vars(.data[["data_source_label"]])
  ) +
  ggplot2::scale_x_continuous(
    transform = "log",
    breaks = base::c(1, 2, 5, 10, 20)
  ) +
  ggplot2::scale_colour_manual(
    values = vec_colours_transition
  ) +
  ggplot2::scale_fill_manual(
    values = vec_colours_transition
  ) +
  ggplot2::scale_shape_manual(
    values = vec_shapes_transition
  ) +
  ggplot2::scale_linetype_manual(
    values = vec_linetypes_transition
  ) +
  ggplot2::labs(
    x = "Taxa: larger model / smaller model (log scale)",
    y = "Larger minus smaller\n(association, pp)",
    colour = NULL,
    fill = NULL,
    shape = NULL,
    linetype = NULL
  ) +
  theme_model_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 8.5,
      lineheight = 0.82
    ),
    legend.position = "bottom"
  ) +
  ggview::canvas(
    width = list_canvas[["width"]],
    height = list_canvas[["height"]],
    units = list_canvas[["units"]],
    dpi = list_canvas[["dpi"]],
    bg = vec_oracle_palette[["background"]]
  ) +
  ggplot2::geom_hline(
    yintercept = 0,
    colour = vec_oracle_palette[["text"]],
    linewidth = 0.3
  ) +
  ggplot2::geom_vline(
    xintercept = 1,
    colour = vec_oracle_palette[["muted"]],
    linetype = "dashed",
    linewidth = 0.3
  ) +
  ggplot2::geom_point(
    colour = vec_oracle_palette[["background"]],
    size = 1.5,
    stroke = 0.15,
    alpha = 0.75
  ) +
  ggplot2::geom_line(
    data = data_nested_extent_lines,
    linewidth = 0.8
  ) +
  ggplot2::geom_point(
    data = data_nested_extent_equal_size,
    fill = vec_oracle_palette[["background"]],
    size = 3,
    stroke = 1
  )

ggview::save_ggplot(
  plot = plot_nested_extent,
  file = base::file.path(
    path_output,
    "slide_model_size_d_nested_extent.png"
  ),
  device = ragg::agg_png
)

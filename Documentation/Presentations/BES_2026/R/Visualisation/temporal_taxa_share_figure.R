#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Model-size section figure: taxa and association share
#         through time
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Ports the chunk plot-taxa-through-time of the Round 0 report to the
#   ORACLE slide style. The association share is the Nagelkerke share of
#   data_anova_components_by_age_percentage, the same measure as the
#   slide 11 trajectories.
# Source, from the first command-line argument:
#   "table" (default): the June 2026 temporal fits, as recorded in
#     model_share_definitions_2026-11-06.csv ("published" definition);
#   "store": the current temporal stores of Europe and North America
#     (cross-validated November 2026 rerun). Northern Asia is left out
#     because almost all of its slices are too small for that workflow.

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

vec_runner_arguments <-
  base::commandArgs(trailingOnly = TRUE)

sel_temporal_source <-
  if (
    base::length(vec_runner_arguments) >= 1L
  ) {
    vec_runner_arguments[[1L]]
  } else {
    "table"
  }

assertthat::assert_that(
  sel_temporal_source %in% base::c("table", "store"),
  msg = "The temporal source must be 'table' or 'store'."
)

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

vec_continent_labels <-
  base::c(
    "america" = "North America",
    "europe" = "Europe",
    "asia" = "Northern Asia"
  )

# Time is phosphor green in the deck; continents are shades of it plus a
#   shape (as on slide 08) and a line type.
vec_colours_continent <-
  base::c(
    "North America" = vec_oracle_palette[["phosphor"]],
    "Europe" = "#E6FFC9",
    "Northern Asia" = vec_oracle_palette[["muted"]]
  )

vec_shapes_continent <-
  base::c(
    "North America" = 22,
    "Europe" = 21,
    "Northern Asia" = 24
  )

vec_linetypes_continent <-
  base::c(
    "North America" = "solid",
    "Europe" = "longdash",
    "Northern Asia" = "dotted"
  )


#----------------------------------------------------------#
# 1. Load data -----
#----------------------------------------------------------#

data_temporal_raw <-
  if (
    sel_temporal_source == "table"
  ) {
    readr::read_csv(
      file = here::here(
        "Outputs",
        "Tables",
        "Diagnostics",
        "Taxon_variance_partition",
        "model_share_definitions_2026-11-06.csv"
      ),
      show_col_types = FALSE
    ) |>
      dplyr::filter(
        .data[["scale"]] == "temporal",
        .data[["definition"]] == "published"
      ) |>
      dplyr::mutate(
        association_share = 100 * .data[["association_share"]]
      ) |>
      dplyr::select(
        "continent_id",
        "age",
        "n_taxa",
        "association_share"
      )
  } else {
    base::c("europe", "america") |>
      purrr::map(
        .f = ~ {
          store_temporal <-
            here::here(
              "Data",
              "targets",
              stringr::str_c("paleo_temporal_", .x),
              "pipeline_paleo_temporal"
            )

          data_shares <-
            targets::tar_read_raw(
              name = "data_anova_components_by_age_percentage",
              store = store_temporal
            ) |>
            dplyr::filter(.data[["component"]] == "Associations") |>
            dplyr::select(
              "age",
              association_share = "R2_Nagelkerke_percentage"
            )

          data_shares |>
            dplyr::mutate(
              continent_id = .x,
              n_taxa = purrr::map_int(
                .x = .data[["age"]],
                .f = ~ base::ncol(
                  targets::tar_read_raw(
                    name = stringr::str_c(
                      "data_community_model_matrix_timeslice_",
                      .x
                    ),
                    store = store_temporal
                  )
                )
              )
            )
        }
      ) |>
      purrr::list_rbind()
  }

data_temporal_shares <-
  data_temporal_raw |>
  dplyr::mutate(
    age_kyr = .data[["age"]] / 1000,
    continent_label = forcats::fct(
      x = base::unname(vec_continent_labels[.data[["continent_id"]]]),
      levels = base::unname(vec_continent_labels)
    )
  ) |>
  dplyr::arrange(
    .data[["continent_label"]],
    .data[["age"]]
  )


#----------------------------------------------------------#
# 2. Shared slide theme -----
#----------------------------------------------------------#

theme_temporal_size <-
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
    plot.margin = ggplot2::margin(6, 10, 9, 4)
  )


#----------------------------------------------------------#
# 3. Make figure -----
#----------------------------------------------------------#

plot_taxa_through_time <-
  data_temporal_shares |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["age_kyr"]],
      y = .data[["n_taxa"]],
      colour = .data[["continent_label"]],
      fill = .data[["continent_label"]],
      shape = .data[["continent_label"]],
      linetype = .data[["continent_label"]]
    )
  ) +
  ggplot2::scale_x_reverse() +
  ggplot2::scale_colour_manual(
    values = vec_colours_continent
  ) +
  ggplot2::scale_fill_manual(
    values = vec_colours_continent
  ) +
  ggplot2::scale_shape_manual(
    values = vec_shapes_continent
  ) +
  ggplot2::scale_linetype_manual(
    values = vec_linetypes_continent
  ) +
  ggplot2::labs(
    x = "Age of the slice (kyr BP)",
    y = "Taxa in\nthe model",
    colour = NULL,
    fill = NULL,
    shape = NULL,
    linetype = NULL
  ) +
  theme_temporal_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["phosphor"]],
      size = 8.5,
      lineheight = 0.82
    ),
    legend.position = "bottom"
  ) +
  ggplot2::geom_line(
    linewidth = 0.7
  ) +
  ggplot2::geom_point(
    colour = vec_oracle_palette[["background"]],
    size = 1.4,
    stroke = 0.15
  )

plot_share_taxa_through_time <-
  data_temporal_shares |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["n_taxa"]],
      y = .data[["association_share"]],
      fill = .data[["continent_label"]],
      shape = .data[["continent_label"]]
    )
  ) +
  ggplot2::scale_x_continuous(
    transform = "log",
    breaks = base::c(5, 10, 20, 50)
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(suffix = "%")
  ) +
  ggplot2::scale_fill_manual(
    values = vec_colours_continent,
    guide = "none"
  ) +
  ggplot2::scale_shape_manual(
    values = vec_shapes_continent,
    guide = "none"
  ) +
  ggplot2::labs(
    x = "Taxa in the model (log scale)",
    y = "Association\nshare"
  ) +
  theme_temporal_size +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(
      colour = vec_oracle_palette[["purple"]],
      size = 8.5,
      lineheight = 0.82
    )
  ) +
  ggplot2::geom_point(
    colour = vec_oracle_palette[["background"]],
    size = 1.8,
    stroke = 0.15,
    alpha = 0.9
  )

plot_legend <-
  cowplot::get_legend(plot_taxa_through_time)

figure_temporal_taxa_share <-
  cowplot::plot_grid(
    cowplot::plot_grid(
      plot_taxa_through_time +
        ggplot2::theme(legend.position = "none"),
      plot_share_taxa_through_time,
      nrow = 1,
      align = "h",
      axis = "tb"
    ),
    plot_legend,
    ncol = 1,
    rel_heights = base::c(1, 0.16)
  ) +
  ggview::canvas(
    width = 1100,
    height = 700,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  )


#----------------------------------------------------------#
# 4. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_temporal_taxa_share,
  file = base::file.path(
    path_output,
    "slide_model_size_e_taxa_through_time.png"
  ),
  device = ragg::agg_png
)

cli::cli_inform(
  "Temporal model-size figure drawn from the {sel_temporal_source} source."
)

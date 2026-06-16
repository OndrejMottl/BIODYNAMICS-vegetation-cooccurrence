#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       VegVault data ingestion schematic figure
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
    "results"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

path_to_vegvault <-
  here::here("Data", "Input", "VegVault.sqlite")

flag_vegvault_present <-
  check_presence_of_vegvault(path_to_vegvault)

if (
  isFALSE(flag_vegvault_present)
) {
  cli::cli_abort(
    c(
      "VegVault database not found at expected path.",
      "i" = "Expected path: {.path {path_to_vegvault}}."
    )
  )
}

format_count <- function(x) {
  res_count <-
    base::format(
      x,
      big.mark = ",",
      scientific = FALSE,
      trim = TRUE
    )

  return(res_count)
}


#----------------------------------------------------------#
# 1. Data for schematic -----
#----------------------------------------------------------#

data_ingestion_streams <-
  tibble::tibble(
    data_type_name = base::c(
      "Modern vegetation",
      "Fossil pollen archives",
      "Palaeoclimate",
      "Functional traits"
    ),
    data_type_label = base::c(
      "PLOTS",
      "POLLEN",
      "CLIMATE",
      "TRAITS"
    ),
    x = 23,
    y = base::c(41, 30, 19, 8),
    colour_name = base::c("cyan", "phosphor", "amber", "purple")
  ) |>
  dplyr::mutate(
    colour = purrr::map_chr(
      .x = colour_name,
      .f = ~ purrr::chuck(vec_oracle_palette, .x)
    ),
    xend = 30,
    yend = 24
  )

data_database_metrics <-
  local({
    con <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_to_vegvault
      )

    # Keep cleanup in the same local frame as the queries. Top-level
    #   on.exit() can close the connection too early when this file is sourced.
    base::on.exit(
      if (
        DBI::dbIsValid(con)
      ) {
        DBI::dbDisconnect(con)
      },
      add = TRUE
    )

    get_vegvault_scalar <- function(sql) {
      res_value <-
        DBI::dbGetQuery(
          conn = con,
          statement = sql
        ) |>
        dplyr::pull(1)

      return(res_value)
    }

    res_metrics <-
      tibble::tibble(
        metric_name = base::c(
          "Datasets",
          "Samples",
          "Taxa",
          "Veg traits",
          "Trait vals",
          "Abiotic vars",
          "Geography",
          "Temporal range"
        ),
        metric_value = base::c(
          format_count(get_vegvault_scalar("select count(*) from Datasets")),
          format_count(get_vegvault_scalar("select count(*) from Samples")),
          format_count(get_vegvault_scalar("select count(*) from Taxa")),
          format_count(get_vegvault_scalar(
            "select count(*) from TraitsDomain"
          )),
          format_count(get_vegvault_scalar("select count(*) from TraitsValue")),
          format_count(get_vegvault_scalar(
            "select count(*) from AbioticVariable"
          )),
          "Global",
          "0-20 ka BP"
        )
      ) |>
      dplyr::mutate(
        x_name = 55,
        x_value = 94,
        y = 41 - (dplyr::row_number() - 1) * 4.7
      )

    res_metrics
  })

data_database_box <-
  tibble::tibble(
    xmin = 30,
    xmax = 50,
    ymin = 16,
    ymax = 32
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_vegvault_ingestion_schematic <-
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = base::c(0, 100),
    ylim = base::c(0, 50),
    expand = FALSE,
    clip = "off"
  ) +
  ggview::canvas(
    width = 750,
    height = 400,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  theme_oracle(base_family = font_family) +
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
    panel.grid.major = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    legend.position = "none",
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  ) +
  ggplot2::scale_colour_manual(
    values = stats::setNames(
      dplyr::pull(data_ingestion_streams, colour),
      dplyr::pull(data_ingestion_streams, data_type_name)
    )
  ) +
  ggplot2::scale_size_identity() +
  # Data stream box
  ggplot2::geom_rect(
    mapping = ggplot2::aes(
      xmin = 3,
      xmax = 25,
      ymin = 4,
      ymax = 45
    ),
    fill = vec_oracle_palette[["surface"]],
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.3,
    alpha = 0.55
  ) +
  # Text box
  ggplot2::geom_rect(
    mapping = ggplot2::aes(
      xmin = 53,
      xmax = 96,
      ymin = 4,
      ymax = 45
    ),
    fill = vec_oracle_palette[["surface"]],
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.3,
    alpha = 0.55
  ) +
  # arows from data types to database
  ggplot2::geom_segment(
    data = data_ingestion_streams,
    mapping = ggplot2::aes(
      x = x,
      xend = xend,
      y = y,
      yend = yend,
      colour = data_type_name
    ),
    linewidth = 0.6,
    alpha = 0.7
  ) +
  # box around data types
  ggplot2::geom_rect(
    data = data_ingestion_streams,
    mapping = ggplot2::aes(
      xmin = 5,
      xmax = 23,
      ymin = y - 3,
      ymax = y + 2.6,
      colour = data_type_name
    ),
    fill = vec_oracle_palette[["surface_alt"]],
    linewidth = 0.3,
    alpha = 0.7
  ) +
  # text labels for data types
  ggplot2::geom_text(
    data = data_ingestion_streams,
    mapping = ggplot2::aes(
      x = 14,
      y = y,
      label = data_type_label,
      colour = data_type_name
    ),
    family = font_family,
    fontface = "bold",
    size = 3
  ) +
  # box around database
  ggplot2::geom_rect(
    data = data_database_box,
    mapping = ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    fill = vec_oracle_palette[["surface_alt"]],
    colour = vec_oracle_palette[["phosphor"]],
    linewidth = 0.55,
    alpha = 0.78
  ) +
  # database label
  ggplot2::annotate(
    geom = "text",
    x = 40,
    y = 25.8,
    label = "VegVault",
    colour = vec_oracle_palette[["phosphor"]],
    family = font_family,
    fontface = "bold",
    size = 3.5
  ) +
  # arrow from database to metrics
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = 50,
      xend = 53,
      y = 24,
      yend = 24
    ),
    colour = vec_oracle_palette[["phosphor"]],
    linewidth = 0.6,
    alpha = 0.82
  ) +
  ggplot2::geom_text(
    data = data_database_metrics,
    mapping = ggplot2::aes(
      x = x_name,
      y = y,
      label = metric_name
    ),
    hjust = 0,
    colour = vec_oracle_palette[["muted"]],
    family = font_family,
    size = 2
  ) +
  ggplot2::geom_text(
    data = data_database_metrics,
    mapping = ggplot2::aes(
      x = x_value,
      y = y,
      label = metric_value
    ),
    hjust = 1,
    colour = vec_oracle_palette[["phosphor"]],
    family = font_family,
    fontface = "bold",
    size = 2
  )


#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_vegvault_ingestion_schematic,
  file = base::file.path(
    path_output,
    "slide_03_ingestion_schematic.png"
  ),
  device = ragg::agg_png
)

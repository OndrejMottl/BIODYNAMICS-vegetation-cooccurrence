#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       VegVault Northern Hemisphere coverage figure
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

systemfonts::register_font(
  name = font_family,
  plain = path_font
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

con <-
  DBI::dbConnect(
    RSQLite::SQLite(),
    path_to_vegvault
  )

base::on.exit(
  DBI::dbDisconnect(con),
  add = TRUE
)

vec_used_project_ids <-
  base::c(
    "project_paleo_temporal_america",
    "project_paleo_temporal_europe",
    "project_paleo_temporal_asia"
  )

data_used_geo_limits <-
  vec_used_project_ids |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ config::get(
      value = "vegvault_data",
      config = .x,
      file = here::here("config.yml")
    )
  ) |>
  purrr::imap(
    .f = ~ tibble::tibble(
      project_id = .y,
      x_min = purrr::chuck(.x, "x_lim", 1),
      x_max = purrr::chuck(.x, "x_lim", 2),
      y_min = purrr::chuck(.x, "y_lim", 1),
      y_max = purrr::chuck(.x, "y_lim", 2)
    )
  ) |>
  purrr::list_rbind()

sel_x_lim <-
  base::range(
    dplyr::pull(data_used_geo_limits, x_min),
    dplyr::pull(data_used_geo_limits, x_max)
  )

sel_y_lim <-
  base::range(
    dplyr::pull(data_used_geo_limits, y_min),
    dplyr::pull(data_used_geo_limits, y_max)
  )


#----------------------------------------------------------#
# 1. Extract sample coverage data -----
#----------------------------------------------------------#

data_vegvault_samples <-
  DBI::dbGetQuery(
    conn = con,
    statement = "
      select
        d.dataset_name,
        s.sample_id,
        s.sample_name,
        s.age,
        d.coord_long,
        d.coord_lat,
        dti.dataset_type
      from Datasets d
      inner join DatasetSample ds
        on d.dataset_id = ds.dataset_id
      inner join Samples s
        on ds.sample_id = s.sample_id
      left join DatasetTypeID dti
        on d.dataset_type_id = dti.dataset_type_id
      where d.coord_long is not null
        and d.coord_lat is not null
        and dti.dataset_type in (
          'vegetation_plot',
          'fossil_pollen_archive'
        )
    "
  ) |>
  tibble::as_tibble() |>
  dplyr::filter(
    purrr::map_lgl(
      .x = base::seq_len(dplyr::n()),
      .f = ~ base::any(
        coord_long[.x] >= dplyr::pull(data_used_geo_limits, x_min) &
          coord_long[.x] <= dplyr::pull(data_used_geo_limits, x_max) &
          coord_lat[.x] >= dplyr::pull(data_used_geo_limits, y_min) &
          coord_lat[.x] <= dplyr::pull(data_used_geo_limits, y_max)
      )
    )
  ) |>
  dplyr::mutate(
    dataset_type = dplyr::case_when(
      dataset_type == "vegetation_plot" ~ "Vegetation plots",
      dataset_type == "fossil_pollen_archive" ~ "Fossil pollen",
      TRUE ~ "Other"
    ),
    coord_long = base::round(coord_long, digits = 4L),
    coord_lat = base::round(coord_lat, digits = 4L)
  )

data_vegetation_plot_samples <-
  data_vegvault_samples |>
  dplyr::filter(
    dataset_type == "Vegetation plots"
  ) |>
  dplyr::distinct(coord_long, coord_lat)

data_fossil_pollen_samples <-
  data_vegvault_samples |>
  dplyr::filter(
    dataset_type == "Fossil pollen"
  ) |>
  dplyr::distinct(coord_long, coord_lat)

data_merge_samples <-
  dplyr::bind_rows(
    data_vegetation_plot_samples,
    data_fossil_pollen_samples
  ) |>
  dplyr::distinct(coord_long, coord_lat)

data_world <-
  ggplot2::map_data(map = "world")

vec_density_colours <-
  base::c(
    vec_oracle_palette[["muted"]],
    vec_oracle_palette[["phosphor"]]
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_northern_hemisphere_coverage <-
  ggplot2::ggplot() +
  ggplot2::coord_map(
    xlim = c(-160, 160),
    ylim = c(50, 65),
    clip = "off",
    projection = "gilbert"
  ) +
  ggplot2::scale_fill_gradientn(
    colours = vec_density_colours,
    trans = "log",
    guide = "none"
  ) +
  ggview::canvas(
    width = 750,
    height = 300,
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
  #ggplot2::geom_vline(
  #  xintercept = seq(-180, 180, by = 10),
  #  colour = vec_oracle_palette[["muted"]],
  #  linewidth = 0.15,
  #  linetype = "dashed"
  #) +
  #ggplot2::geom_hline(
  #  yintercept = seq(-90, 90, by = 5),
  #  colour = vec_oracle_palette[["muted"]],
  #  linewidth = 0.15,
  #  linetype = "dashed"
  #) +
  ggplot2::geom_polygon(
    data = data_world,
    mapping = ggplot2::aes(
      x = long,
      y = lat,
      group = group
    ),
    fill = vec_oracle_palette[["surface_alt"]],
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.12,
    alpha = 0.82
  ) +
  ggplot2::stat_bin_hex(
    data = data_fossil_pollen_samples,
    mapping = ggplot2::aes(
      x = coord_long,
      y = coord_lat,
      fill = ggplot2::after_stat(count)
    ),
    binwidth = c(5, 5),
    alpha = 1
  ) +
  ggplot2::annotate(
    geom = "text",
    x = -120,
    y = 75,
    label = "USED ANALYSIS EXTENT",
    hjust = 0.4,
    vjust = -1,
    colour = vec_oracle_palette[["text"]],
    family = font_family,
    fontface = "bold",
    size = 3.3
  )

#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_northern_hemisphere_coverage,
  file = base::file.path(
    path_output,
    "slide_03_northern_hemisphere_coverage.png"
  ),
  device = ragg::agg_png
)

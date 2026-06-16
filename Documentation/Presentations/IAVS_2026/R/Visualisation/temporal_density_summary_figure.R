#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Temporal core coverage figure
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

selected_age <- 2000
time_step <- 500

vec_project_ids <-
  base::c(
    "project_paleo_temporal_america",
    "project_paleo_temporal_europe",
    "project_paleo_temporal_asia"
  )

vec_continent_labels <-
  base::c(
    "America",
    "Europe",
    "Asia"
  )

vec_continent_colours <-
  base::c(
    "America" = vec_oracle_palette[["cyan"]],
    "Europe" = vec_oracle_palette[["phosphor"]],
    "Asia" = vec_oracle_palette[["amber"]]
  )


#----------------------------------------------------------#
# 1. Extract core age coverage -----
#----------------------------------------------------------#

data_continent_limits <-
  vec_project_ids |>
  rlang::set_names(vec_continent_labels) |>
  purrr::imap(
    .f = ~ {
      list_config <-
        config::get(
          value = "vegvault_data",
          config = .x,
          file = here::here("config.yml")
        )

      tibble::tibble(
        continent = .y,
        x_min = purrr::chuck(list_config, "x_lim", 1),
        x_max = purrr::chuck(list_config, "x_lim", 2),
        y_min = purrr::chuck(list_config, "y_lim", 1),
        y_max = purrr::chuck(list_config, "y_lim", 2),
        age_min = purrr::chuck(list_config, "age_lim", 1),
        age_max = purrr::chuck(list_config, "age_lim", 2)
      )
    }
  ) |>
  purrr::list_rbind()

data_fossil_samples <-
  local({
    con <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_to_vegvault
      )

    base::on.exit(
      if (
        DBI::dbIsValid(con)
      ) {
        DBI::dbDisconnect(con)
      },
      add = TRUE
    )

    res_samples <-
      DBI::dbGetQuery(
        conn = con,
        statement = "
          select
            d.dataset_name,
            s.sample_id,
            s.sample_name,
            s.age,
            d.coord_long,
            d.coord_lat
          from Datasets d
          inner join DatasetSample ds
            on d.dataset_id = ds.dataset_id
          inner join Samples s
            on ds.sample_id = s.sample_id
          left join DatasetTypeID dti
            on d.dataset_type_id = dti.dataset_type_id
          where d.coord_long is not null
            and d.coord_lat is not null
            and s.age is not null
            and dti.dataset_type = 'fossil_pollen_archive'
        "
      ) |>
      tibble::as_tibble()

    res_samples
  })

data_core_coverage <-
  data_fossil_samples |>
  dplyr::cross_join(data_continent_limits) |>
  dplyr::filter(
    coord_long >= x_min,
    coord_long <= x_max,
    coord_lat >= y_min,
    coord_lat <= y_max,
    age >= age_min,
    age <= age_max
  ) |>
  dplyr::group_by(continent, dataset_name) |>
  dplyr::summarise(
    age_start = base::min(age, na.rm = TRUE),
    age_end = base::max(age, na.rm = TRUE),
    sample_count = dplyr::n_distinct(sample_id),
    .groups = "drop"
  ) |>
  dplyr::filter(
    sample_count > 1L
  ) |>
  dplyr::group_by(continent) |>
  dplyr::arrange(age_end, age_start, .by_group = TRUE) |>
  dplyr::mutate(
    core_index = dplyr::row_number()
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    continent = base::factor(
      continent,
      levels = vec_continent_labels
    )
  )

if (
  base::nrow(data_core_coverage) == 0L
) {
  cli::cli_abort("No fossil pollen core coverage rows were extracted.")
}

age_max_plot <-
  data_continent_limits |>
  dplyr::pull(age_max) |>
  base::max(na.rm = TRUE)

vec_age_grid <-
  base::seq(
    from = 0,
    to = age_max_plot,
    by = time_step
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_temporal_density <-
  data_core_coverage |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      y = core_index
    )
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(continent),
    scales = "free_y"
  ) +
  ggplot2::scale_x_reverse(
    limits = base::c(age_max_plot, 0),
    breaks = base::seq(0, age_max_plot, by = 5000)
  ) +
  ggplot2::scale_y_continuous(
    breaks = NULL
  ) +
  ggplot2::scale_colour_manual(
    values = vec_continent_colours,
    guide = "none"
  ) +
  ggplot2::labs(
    x = "Age (cal yr BP)",
    y = "Core ID"
  ) +
  ggview::canvas(
    width = 1000,
    height = 400,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  theme_oracle(base_family = font_family, base_size = 8) +
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
    axis.ticks.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    strip.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["surface_alt"]],
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.25
    ),
    strip.text.y = ggplot2::element_text(
      angle = 0,
      colour = vec_oracle_palette[["phosphor"]],
      family = font_family,
      face = "bold"
    ),
    plot.margin = ggplot2::margin(0, 3, 0, 3)
  ) +
  ggplot2::geom_vline(
    xintercept = vec_age_grid,
    colour = vec_oracle_palette[["border"]],
    linewidth = 0.13,
    alpha = 0.8
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = age_start,
      xend = age_end,
      yend = core_index
    ),
    color = vec_oracle_palette[["phosphor"]],
    linewidth = 0.5,
    alpha = 1,
    lineend = "round"
  ) +
  ggplot2::geom_vline(
    xintercept = selected_age,
    colour = vec_oracle_palette[["red"]],
    linewidth = 0.55,
    alpha = 1
  )


#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_temporal_density,
  file = base::file.path(
    path_output,
    "slide_10_temporal_density.png"
  ),
  device = ragg::agg_png
)

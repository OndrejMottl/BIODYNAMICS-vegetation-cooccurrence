#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Slide 11 temporal trajectory animation helper
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

vec_required_components <-
  base::c(
    "Spatial",
    "Abiotic",
    "Associations"
  )

vec_component_labels <-
  base::c(
    "Spatial" = "Space",
    "Abiotic" = "Abiotic",
    "Associations" = "Associations"
  )

vec_component_colours <-
  base::c(
    "Spatial" = base::unname(vec_oracle_palette[["cyan"]]),
    "Abiotic" = base::unname(vec_oracle_palette[["amber"]]),
    "Associations" = base::unname(vec_oracle_palette[["purple"]])
  )


#----------------------------------------------------------#
# 1. Load temporal results -----
#----------------------------------------------------------#

load_slide_temporal_components <- function() {
  data_continents <-
    load_continental_rows(
      path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
    ) |>
    dplyr::select(scale_id) |>
    dplyr::mutate(
      store_path = here::here(
        stringr::str_glue(
          "Data/targets/paleo_temporal_",
          "{scale_id}/pipeline_paleo_temporal/"
        )
      ),
      store_exists = fs::dir_exists(.data$store_path),
      continent_label = stringr::str_to_title(.data$scale_id)
    )

  data_available_continents <-
    data_continents |>
    dplyr::filter(.data$store_exists) |>
    dplyr::select(
      "scale_id",
      "continent_label",
      "store_path"
    )

  if (
    base::nrow(data_available_continents) == 0L
  ) {
    cli::cli_abort(
      c(
        "No temporal target stores found.",
        "i" = "Run at least one 0*_Run_temporal_*.R script first."
      )
    )
  }

  data_anova_all <-
    data_available_continents |>
    purrr::pmap(
      .f = function(scale_id, continent_label, store_path) {
        targets::tar_read(
          name = "data_anova_components_by_age_percentage",
          store = store_path
        ) |>
          dplyr::mutate(continent = continent_label)
      }
    ) |>
    purrr::list_rbind()

  vec_expected_columns <-
    base::c(
      "age",
      "continent",
      "component",
      "R2_Nagelkerke_percentage"
    )

  assertthat::assert_that(
    base::all(vec_expected_columns %in% base::colnames(data_anova_all)),
    msg = stringr::str_c(
      "The temporal ANOVA target must contain columns: ",
      stringr::str_c(vec_expected_columns, collapse = ", "),
      "."
    )
  )

  vec_continent_order <-
    base::c(
      "America",
      "Europe",
      "Asia"
    )

  res_components <-
    data_anova_all |>
    dplyr::filter(
      .data$component %in% vec_required_components,
      base::is.finite(.data$R2_Nagelkerke_percentage)
    ) |>
    dplyr::mutate(
      age = base::as.numeric(.data$age),
      continent = base::factor(
        .data$continent,
        levels = vec_continent_order
      ),
      component = base::factor(
        .data$component,
        levels = vec_required_components
      ),
      component_percentage = base::pmax(
        .data$R2_Nagelkerke_percentage,
        0
      )
    ) |>
    dplyr::select(
      "age",
      "continent",
      "component",
      "component_percentage"
    ) |>
    dplyr::arrange(
      .data$continent,
      dplyr::desc(.data$age),
      .data$component
    )

  if (
    base::nrow(res_components) == 0L
  ) {
    cli::cli_abort(
      "No finite temporal variance components were found."
    )
  }

  return(res_components)
}

if (
  !base::exists("data_slide_11_temporal_components")
) {
  data_slide_11_temporal_components <-
    load_slide_temporal_components()
}

get_temporal_components_for_continent <- function(continent_label) {
  res_components <-
    data_slide_11_temporal_components |>
    dplyr::filter(
      .data$continent == .env$continent_label
    )

  if (
    base::nrow(res_components) == 0L
  ) {
    cli::cli_abort(
      c(
        "No temporal ANOVA data found for continent.",
        "i" = "Requested continent: {.val {continent_label}}."
      )
    )
  }

  return(res_components)
}


#----------------------------------------------------------#
# 2. Build frames -----
#----------------------------------------------------------#

build_temporal_trajectory_frame <- function(
    data_plot,
    current_age,
    continent_label) {
  data_visible <-
    data_plot |>
    dplyr::filter(
      .data$age >= current_age
    ) |>
    dplyr::mutate(
      age = base::as.numeric(.data$age),
      fill_colour = base::unname(
        vec_component_colours[base::as.character(.data$component)]
      )
    )

  continent_title <-
    dplyr::case_when(
      continent_label == "America" ~ "America",
      TRUE ~ continent_label
    )

  res_plot <-
    data_visible |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$age,
        y = .data$component_percentage,
        fill = .data$fill_colour,
        group = .data$component
      )
    ) +
    ggplot2::scale_x_reverse(
      limits = base::c(20000, 0),
      breaks = base::c(20000, 15000, 10000, 5000, 0),
      labels = base::c("20k", "15k", "10k", "5k", "0"),
      expand = ggplot2::expansion(mult = base::c(0, 0))
    ) +
    ggplot2::scale_y_continuous(
      limits = base::c(0, 105),
      breaks = base::seq(0, 100, by = 25),
      labels = function(x) stringr::str_glue("{x}%"),
      expand = ggplot2::expansion(mult = base::c(0, 0.03))
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(
      title = stringr::str_to_upper(continent_title),
      x = "Age (cal yr BP)",
      y = "Variance (%)",
      fill = NULL
    ) +
    theme_oracle(base_family = font_family, base_size = 10) +
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
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        colour = vec_oracle_palette[["border"]],
        linewidth = 0.14,
        linetype = "dotted"
      ),
      panel.grid.major.y = ggplot2::element_line(
        colour = vec_oracle_palette[["border"]],
        linewidth = 0.18,
        linetype = "dotted"
      ),
      plot.title = ggplot2::element_text(
        colour = vec_oracle_palette[["text"]],
        face = "bold",
        size = 14,
        margin = ggplot2::margin(b = 10)
      ),
      axis.title = ggplot2::element_text(
        colour = vec_oracle_palette[["muted"]],
        size = 9
      ),
      axis.text = ggplot2::element_text(
        colour = vec_oracle_palette[["text"]],
        size = 8
      ),
      axis.ticks = ggplot2::element_line(
        colour = vec_oracle_palette[["border"]],
        linewidth = 0.2
      ),
      legend.position = "none",
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    ) +
    ggview::canvas(
      width = 530,
      height = 720,
      units = "px",
      dpi = 300,
      bg = vec_oracle_palette[["background"]]
    ) +
    ggplot2::geom_area(
      alpha = 0.88,
      colour = vec_oracle_palette[["background"]],
      linewidth = 0.12,
      position = "stack"
    ) +
    ggplot2::geom_vline(
      xintercept = current_age,
      colour = vec_oracle_palette[["phosphor"]],
      linewidth = 0.42,
      linetype = "dashed",
      alpha = 0.82
    )

  return(res_plot)
}

build_temporal_trajectory_legend <- function() {
  data_legend <-
    tibble::tibble(
      component = base::factor(
        vec_required_components,
        levels = vec_required_components
      ),
      label = base::unname(vec_component_labels[vec_required_components]),
      fill_colour = base::unname(
        vec_component_colours[vec_required_components]
      ),
      y = base::rev(base::seq_along(vec_required_components))
    )

  res_plot <-
    ggplot2::ggplot() +
    ggplot2::coord_cartesian(
      xlim = base::c(0, 340),
      ylim = base::c(0, 720),
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_colour_identity() +
    theme_oracle(base_family = font_family, base_size = 10) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(
        fill = vec_oracle_palette[["background"]],
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = vec_oracle_palette[["background"]],
        colour = NA
      ),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "none",
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    ) +
    ggview::canvas(
      width = 380,
      height = 720,
      units = "px",
      dpi = 300,
      bg = vec_oracle_palette[["background"]]
    ) +
    ggplot2::geom_rect(
      mapping = ggplot2::aes(
        xmin = 12,
        xmax = 328,
        ymin = 255,
        ymax = 465
      ),
      fill = vec_oracle_palette[["background"]],
      colour = vec_oracle_palette[["border"]],
      linewidth = 0.5
    ) +
    ggplot2::geom_text(
      mapping = ggplot2::aes(
        x = 36,
        y = 432,
        label = "COMPONENT"
      ),
      hjust = 0,
      colour = vec_oracle_palette[["muted"]],
      family = font_family,
      fontface = "bold",
      size = 3.6
    ) +
    ggplot2::geom_rect(
      data = data_legend,
      mapping = ggplot2::aes(
        xmin = 36,
        xmax = 84,
        ymin = 286 + (.data$y - 1) * 44,
        ymax = 316 + (.data$y - 1) * 44,
        fill = .data$fill_colour
      ),
      colour = vec_oracle_palette[["background"]],
      linewidth = 0.35
    ) +
    ggplot2::geom_text(
      data = data_legend,
      mapping = ggplot2::aes(
        x = 102,
        y = 301 + (.data$y - 1) * 44,
        label = .data$label
      ),
      hjust = 0,
      vjust = 0.5,
      colour = vec_oracle_palette[["text"]],
      family = font_family,
      size = 3.4
    )

  return(res_plot)
}


#----------------------------------------------------------#
# 3. Save animation -----
#----------------------------------------------------------#

save_temporal_trajectory_animation <- function(
    continent_label,
    output_file_name,
    frame_directory_name) {
  data_temporal_components <-
    get_temporal_components_for_continent(
      continent_label = continent_label
    )

  vec_frame_ages <-
    data_temporal_components |>
    dplyr::distinct(.data$age) |>
    dplyr::arrange(dplyr::desc(.data$age)) |>
    dplyr::pull(.data$age)

  path_frame_output <-
    base::file.path(
      path_output,
      "frames",
      frame_directory_name
    )

  base::dir.create(
    path = path_frame_output,
    showWarnings = FALSE,
    recursive = TRUE
  )

  frame_index_width <-
    base::max(
      2L,
      base::nchar(base::length(vec_frame_ages))
    )

  data_frame_paths <-
    tibble::tibble(
      frame_index = base::seq_along(vec_frame_ages),
      age = vec_frame_ages
    ) |>
    dplyr::mutate(
      frame_id = stringr::str_pad(
        string = .data$frame_index,
        width = frame_index_width,
        side = "left",
        pad = "0"
      ),
      frame_path = base::file.path(
        path_frame_output,
        stringr::str_glue(
          "{frame_directory_name}_",
          "{frame_id}_",
          "{base::as.integer(age)}.png"
        )
      )
    ) |>
    dplyr::select(
      "frame_index",
      "age",
      "frame_path"
    )

  purrr::pwalk(
    .l = data_frame_paths,
    .f = function(frame_index, age, frame_path) {
      plot_frame <-
        build_temporal_trajectory_frame(
          data_plot = data_temporal_components,
          current_age = age,
          continent_label = continent_label
        )

      ggview::save_ggplot(
        plot = plot_frame,
        file = frame_path,
        device = ragg::agg_png
      )
    }
  )

  vec_frame_paths <-
    data_frame_paths |>
    dplyr::pull(.data$frame_path)

  list_animation <-
    build_gif_from_frames(
      vec_frame_paths = vec_frame_paths,
      output_path = base::file.path(
        path_output,
        output_file_name
      ),
      fps = 2,
      loop = 0L,
      optimize = TRUE
    )

  if (
    !isTRUE(purrr::chuck(list_animation, "used_magick"))
  ) {
    cli::cli_abort(
      "Could not create GIF because no GIF backend was available."
    )
  }

  res_animation <-
    base::list(
      frame_paths = vec_frame_paths,
      animation_path = purrr::chuck(list_animation, "animation_path"),
      used_magick = purrr::chuck(list_animation, "used_magick")
    )

  return(res_animation)
}

save_temporal_trajectory_legend <- function(output_file_name) {
  plot_legend <-
    build_temporal_trajectory_legend()

  output_path <-
    base::file.path(
      path_output,
      output_file_name
    )

  ggview::save_ggplot(
    plot = plot_legend,
    file = output_path,
    device = ragg::agg_png
  )

  return(output_path)
}


#----------------------------------------------------------#
# 4. Generate slide outputs -----
#----------------------------------------------------------#

list_slide_11_figures <-
  base::list()

list_slide_11_figures[["north_america"]] <-
  save_temporal_trajectory_animation(
    continent_label = "America",
    output_file_name = "slide_11_temporal_trajectory_na.gif",
    frame_directory_name = "slide_11_temporal_trajectory_na"
  )

list_slide_11_figures[["europe"]] <-
  save_temporal_trajectory_animation(
    continent_label = "Europe",
    output_file_name = "slide_11_temporal_trajectory_eu.gif",
    frame_directory_name = "slide_11_temporal_trajectory_eu"
  )

list_slide_11_figures[["asia"]] <-
  save_temporal_trajectory_animation(
    continent_label = "Asia",
    output_file_name = "slide_11_temporal_trajectory_asia.gif",
    frame_directory_name = "slide_11_temporal_trajectory_asia"
  )

list_slide_11_figures[["legend"]] <-
  save_temporal_trajectory_legend(
    output_file_name = "slide_11_temporal_trajectory_legend.png"
  )

#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Slide 08 spatial units map animation
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

path_frame_output <-
  base::file.path(
    path_output,
    "frames",
    "slide_08_spatial_units_map"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_frame_output,
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


#----------------------------------------------------------#
# 1. Spatial units -----
#----------------------------------------------------------#

selected_continent_id <- "america"
selected_regional_id <- "am_r005"
selected_local_id <- "am_r005_l003"

data_spatial_grid <-
  readr::read_csv(
    file = here::here("Data", "Input", "spatial_grid.csv"),
    show_col_types = FALSE
  )

data_selected_units <-
  tibble::tibble(
    frame_index = 1:3,
    scale = base::c(
      "continental",
      "regional",
      "local"
    ),
    scale_label = base::c(
      "continental",
      "regional",
      "local"
    ),
    scale_id = base::c(
      selected_continent_id,
      selected_regional_id,
      selected_local_id
    ),
    scale_colour = base::c(
      vec_oracle_palette[["cyan"]],
      vec_oracle_palette[["amber"]],
      vec_oracle_palette[["purple"]]
    )
  ) |>
  dplyr::left_join(
    y = data_spatial_grid,
    by = dplyr::join_by(scale_id, scale)
  )

if (
  base::any(base::is.na(data_selected_units |> dplyr::pull("x_min")))
) {
  cli::cli_abort("One or more selected spatial IDs are missing from grid.")
}

data_selected_continent <-
  data_spatial_grid |>
  dplyr::filter(
    .data$scale_id == selected_continent_id
  )

x_limits <-
  data_selected_continent |>
  dplyr::select(
    "x_min",
    "x_max"
  ) |>
  unlist()

y_limits <-
  data_selected_continent |>
  dplyr::select(
    "y_min",
    "y_max"
  ) |>
  unlist()

buffer_degrees <- 2

data_world <-
  ggplot2::map_data(map = "world") |>
  dplyr::filter(
    .data$long >= base::min(x_limits) - buffer_degrees,
    .data$long <= base::max(x_limits) + buffer_degrees,
    .data$lat >= base::min(y_limits) - buffer_degrees,
    .data$lat <= base::max(y_limits) + buffer_degrees
  )


#----------------------------------------------------------#
# 2. Extract points -----
#----------------------------------------------------------#

data_fossil_pollen_points <-
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

    DBI::dbGetQuery(
      conn = con,
      statement = "
        select distinct
          d.coord_long,
          d.coord_lat
        from Datasets d
        left join DatasetTypeID dti
          on d.dataset_type_id = dti.dataset_type_id
        where d.coord_long is not null
          and d.coord_lat is not null
          and dti.dataset_type = 'fossil_pollen_archive'
      "
    ) |>
      tibble::as_tibble() |>
      dplyr::mutate(
        coord_long = base::round(.data$coord_long, digits = 4L),
        coord_lat = base::round(.data$coord_lat, digits = 4L)
      )
  })

get_points_in_unit <- function(x_min, x_max, y_min, y_max) {
  res_points <-
    data_fossil_pollen_points |>
    dplyr::filter(
      .data$coord_long >= x_min,
      .data$coord_long <= x_max,
      .data$coord_lat >= y_min,
      .data$coord_lat <= y_max
    )

  return(res_points)
}

data_frame_points <-
  data_selected_units |>
  dplyr::mutate(
    data_points = purrr::pmap(
      .l = dplyr::pick(
        "x_min",
        "x_max",
        "y_min",
        "y_max"
      ),
      .f = get_points_in_unit
    )
  ) |>
  dplyr::select(
    "frame_index",
    "data_points"
  ) |>
  tidyr::unnest(
    cols = "data_points"
  )


#----------------------------------------------------------#
# 3. Build frames -----
#----------------------------------------------------------#
data_frame_paths <-
  data_selected_units |>
  dplyr::mutate(
    frame_path = base::file.path(
      path_frame_output,
      stringr::str_glue(
        "slide_08_spatial_units_map_",
        "{stringr::str_pad(frame_index, width = 2, pad = '0')}_",
        "{scale_label}.png"
      )
    )
  ) |>
  dplyr::select(
    "frame_index",
    "scale_label",
    "frame_path"
  )

purrr::pwalk(
  .l = data_frame_paths,
  .f = function(frame_index, scale_label, frame_path) {
    frame_index_current <-
      frame_index

    data_unit <-
      data_selected_units |>
      dplyr::filter(
        .data$frame_index == .env$frame_index_current
      )

    data_points <-
      data_frame_points |>
      dplyr::filter(
        .data$frame_index == .env$frame_index_current
      )

    plot_frame <-
      build_spatial_unit_frame(
        data_unit = data_unit,
        data_points = data_points,
        scale_label = scale_label,
        data_world = data_world,
        x_limits = x_limits,
        y_limits = y_limits,
        buffer_degrees = buffer_degrees,
        vec_palette = vec_oracle_palette,
        font_family = font_family
      )

    ggview::save_ggplot(
      plot = plot_frame,
      file = frame_path,
      device = ragg::agg_png
    )
  }
)


#----------------------------------------------------------#
# 4. Save animation -----
#----------------------------------------------------------#

vec_frame_paths <-
  data_frame_paths |>
  dplyr::pull(.data$frame_path)

list_spatial_units_animation <-
  build_gif_from_frames(
    vec_frame_paths = vec_frame_paths,
    output_path = base::file.path(
      path_output,
      "slide_08_spatial_units_map.gif"
    ),
    fps = 1,
    loop = 0L,
    optimize = TRUE
  )

if (
  !isTRUE(purrr::chuck(list_spatial_units_animation, "used_magick"))
) {
  cli::cli_abort(
    "Could not create GIF because no GIF backend was available."
  )
}

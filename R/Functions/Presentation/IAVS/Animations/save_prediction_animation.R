#' @title Save Prediction Animation
#' @description
#' Renders one prediction variable across all age slices, saves individual
#' PNG frames, and combines them into a GIF animation.
#' @param data_frame
#' Tibble with columns `age`, `coord_long`, `coord_lat`, and the column
#' named by `value_column`.
#' @param value_column
#' Character scalar. Name of the fill value column.
#' @param subtitle_label
#' Character scalar. Plot subtitle.
#' @param fill_label
#' Character scalar. Legend title.
#' @param fill_limits
#' Numeric vector of length 2. Fill scale limits.
#' @param vec_age_slices
#' Numeric vector of age values, one per animation frame.
#' @param path_output
#' Character scalar. Root output directory for frames and GIF.
#' @param list_prediction_grid
#' Named list with `x_lim` and `y_lim` entries.
#' @param data_world
#' World polygon tibble with columns `long`, `lat`, and `group`.
#' @param grid_resolution
#' Numeric scalar. Tile width and height in degrees.
#' @param time_step
#' Numeric scalar. Half-window in years for matching `data_points` ages
#' to each frame age.
#' @param fill_trans
#' Scale transform passed to `ggplot2::scale_fill_gradientn()`.
#' @param fill_colors
#' Optional character vector of fill gradient colours.
#' @param data_points
#' Optional tibble with `age`, `coord_long`, `coord_lat` for overlaid
#' observation points.
#' @param point_color
#' Character scalar. Colour for observation points.
#' @param metric_label
#' Optional character vector appended as a plot caption.
#' @param frame_directory_name
#' Character scalar. Name of the sub-directory for PNG frames.
#' @param output_file_name
#' Character scalar. Output GIF file name.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' List returned by [build_gif_from_frames()] with `animation_path` and
#' `used_magick` entries.
#' @export
save_prediction_animation <- function(
    data_frame,
    value_column,
    subtitle_label,
    fill_label,
    fill_limits,
    vec_age_slices,
    path_output,
    list_prediction_grid,
    data_world,
    grid_resolution,
    time_step,
    fill_trans = scales::transform_identity(),
    fill_colors = NULL,
    data_points = NULL,
    point_color = "#ff4d4d",
    metric_label = NULL,
    frame_directory_name,
    output_file_name,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.data.frame(data_frame),
    msg = "'data_frame' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(value_column),
    base::length(value_column) == 1L,
    value_column %in% base::colnames(data_frame),
    msg = paste(
      "'value_column' must be a column name present in 'data_frame'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(vec_age_slices),
    base::length(vec_age_slices) >= 1L,
    msg = "'vec_age_slices' must be a non-empty numeric vector."
  )

  assertthat::assert_that(
    base::is.character(path_output),
    base::length(path_output) == 1L,
    base::nchar(path_output) > 0L,
    msg = "'path_output' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.list(list_prediction_grid),
    base::all(
      base::c("x_lim", "y_lim") %in% base::names(list_prediction_grid)
    ),
    msg = paste(
      "'list_prediction_grid' must be a named list with",
      "'x_lim' and 'y_lim' entries."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_world),
    base::all(
      base::c("long", "lat", "group") %in%
        base::colnames(data_world)
    ),
    msg = "'data_world' must contain columns 'long', 'lat', and 'group'."
  )

  assertthat::assert_that(
    base::is.numeric(grid_resolution),
    base::length(grid_resolution) == 1L,
    base::is.finite(grid_resolution),
    grid_resolution > 0,
    msg = paste(
      "'grid_resolution' must be one positive finite numeric value."
    )
  )

  assertthat::assert_that(
    base::is.numeric(time_step),
    base::length(time_step) == 1L,
    base::is.finite(time_step),
    time_step > 0,
    msg = "'time_step' must be one positive finite numeric value."
  )

  assertthat::assert_that(
    base::is.character(frame_directory_name),
    base::length(frame_directory_name) == 1L,
    base::nchar(frame_directory_name) > 0L,
    msg = "'frame_directory_name' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.character(output_file_name),
    base::length(output_file_name) == 1L,
    base::nchar(output_file_name) > 0L,
    msg = "'output_file_name' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.character(font_family),
    base::length(font_family) == 1L,
    msg = "'font_family' must be a single character value."
  )

  if (
    base::is.null(vec_palette)
  ) {
    vec_palette <-
      get_oracle_palette_values()
  }

  if (
    base::is.null(fill_trans)
  ) {
    fill_trans <-
      scales::transform_identity()
  }

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

  vec_stale_frames <-
    base::list.files(
      path = path_frame_output,
      pattern = base::paste0("^", frame_directory_name, "_.*[.]png$"),
      full.names = TRUE
    )

  if (
    base::length(vec_stale_frames) > 0L
  ) {
    base::unlink(x = vec_stale_frames)
  }

  frame_index_width <-
    base::nchar(base::length(vec_age_slices))

  data_frame_paths <-
    tibble::tibble(
      frame_index = base::seq_along(vec_age_slices),
      age = vec_age_slices
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
          "{frame_directory_name}_{frame_id}_",
          "{base::as.integer(age)}.png"
        )
      )
    )

  purrr::pwalk(
    .l = data_frame_paths,
    .f = function(frame_index, age, frame_id, frame_path) {
      plot_frame <-
        if (
          base::is.null(data_points)
        ) {
          build_prediction_frame(
            data_frame = data_frame,
            age_value = age,
            value_column = value_column,
            subtitle_label = subtitle_label,
            fill_label = fill_label,
            fill_limits = fill_limits,
            list_prediction_grid = list_prediction_grid,
            data_world = data_world,
            grid_resolution = grid_resolution,
            fill_trans = fill_trans,
            fill_colors = fill_colors,
            metric_label = metric_label,
            vec_palette = vec_palette,
            font_family = font_family
          )
        } else {
          build_prediction_frame(
            data_frame = data_frame,
            age_value = age,
            value_column = value_column,
            subtitle_label = subtitle_label,
            fill_label = fill_label,
            fill_limits = fill_limits,
            list_prediction_grid = list_prediction_grid,
            data_world = data_world,
            grid_resolution = grid_resolution,
            fill_trans = fill_trans,
            data_points = data_points |>
              dplyr::filter(
                base::abs(.data$age - age) <= (time_step / 2)
              ) |>
              tidyr::drop_na(
                "coord_long",
                "coord_lat"
              ),
            fill_colors = fill_colors,
            point_color = point_color,
            metric_label = metric_label,
            vec_palette = vec_palette,
            font_family = font_family
          )
        }

      ggview::save_ggplot(
        plot = plot_frame,
        file = frame_path,
        device = ragg::agg_png
      )
    }
  )

  res_animation <-
    build_gif_from_frames(
      vec_frame_paths = data_frame_paths |>
        dplyr::pull("frame_path"),
      output_path = base::file.path(
        path_output,
        output_file_name
      ),
      fps = 2,
      loop = 0L,
      optimize = TRUE
    )

  if (
    !isTRUE(purrr::chuck(res_animation, "used_magick"))
  ) {
    cli::cli_abort(
      "Could not create GIF because no GIF backend was available."
    )
  }
}

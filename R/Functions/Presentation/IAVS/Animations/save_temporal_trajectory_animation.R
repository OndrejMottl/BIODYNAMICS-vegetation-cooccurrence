#' @title Save Temporal Trajectory Animation
#' @description
#' Renders and saves one per-continent temporal ANOVA component trajectory
#' animation as a GIF file, writing individual PNG frames and then
#' combining them with [build_gif_from_frames()].
#' @param continent_label
#' Character scalar. Continent name used as the frame title.
#' @param data_temporal_components
#' Tibble with columns `age`, `component`, and `component_percentage`.
#' Should be pre-filtered to the target continent.
#' @param data_temporal_modularity
#' Tibble with columns `age` and `modularity_q`.
#' Should be pre-filtered to the target continent.
#' @param output_file_name
#' Character scalar. Output GIF file name (relative to `path_output`).
#' @param frame_directory_name
#' Character scalar. Name of the sub-directory to write PNG frames into.
#' @param path_output
#' Character scalar. Path to the output directory.
#' @param vec_component_colours
#' Named character vector mapping component names to fill colours.
#' @param colour_modularity
#' Character scalar. Colour for the modularity Q overlay line.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' List returned by [build_gif_from_frames()] with `animation_path` and
#' `used_magick` entries.
#' @export
save_temporal_trajectory_animation <- function(
    continent_label,
    data_temporal_components,
    data_temporal_modularity,
    output_file_name,
    frame_directory_name,
    path_output,
    vec_component_colours,
    colour_modularity,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.character(continent_label),
    base::length(continent_label) == 1L,
    msg = "'continent_label' must be a single character value."
  )

  assertthat::assert_that(
    base::is.data.frame(data_temporal_components),
    base::all(
      base::c("age", "component", "component_percentage") %in%
        base::colnames(data_temporal_components)
    ),
    msg = paste(
      "'data_temporal_components' must contain columns",
      "'age', 'component', and 'component_percentage'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_temporal_modularity),
    base::all(
      base::c("age", "modularity_q") %in%
        base::colnames(data_temporal_modularity)
    ),
    msg = paste(
      "'data_temporal_modularity' must contain columns",
      "'age' and 'modularity_q'."
    )
  )

  assertthat::assert_that(
    base::is.character(output_file_name),
    base::length(output_file_name) == 1L,
    base::nchar(output_file_name) > 0L,
    msg = "'output_file_name' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.character(frame_directory_name),
    base::length(frame_directory_name) == 1L,
    base::nchar(frame_directory_name) > 0L,
    msg = "'frame_directory_name' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.character(path_output),
    base::length(path_output) == 1L,
    base::nchar(path_output) > 0L,
    msg = "'path_output' must be a non-empty character scalar."
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours),
    base::length(vec_component_colours) >= 1L,
    msg = "'vec_component_colours' must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(colour_modularity),
    base::length(colour_modularity) == 1L,
    msg = "'colour_modularity' must be a single character value."
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
          data_modularity = data_temporal_modularity,
          current_age = age,
          continent_label = continent_label,
          vec_component_colours = vec_component_colours,
          colour_modularity = colour_modularity,
          vec_palette = vec_palette,
          font_family = font_family
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

  res_animation <-
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
    !isTRUE(purrr::chuck(res_animation, "used_magick"))
  ) {
    cli::cli_abort(
      "Could not create GIF because no GIF backend was available."
    )
  }

}

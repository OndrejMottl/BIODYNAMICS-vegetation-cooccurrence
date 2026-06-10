#' @title build gif from frames
#' @description IAVS 2026 presentation helper function.
#' @return Object returned by this function.
#' @examples
#' \\dontrun{
#' build_gif_from_frames()
#' }
build_gif_from_frames <- function(
    vec_frame_paths,
    output_path,
    fps = 1.5,
    loop = 0L,
    optimize = TRUE) {
  assertthat::assert_that(
    base::is.character(vec_frame_paths),
    base::length(vec_frame_paths) > 0L,
    msg = "'vec_frame_paths' must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(output_path),
    base::length(output_path) == 1L,
    msg = "'output_path' must be a character scalar."
  )

  if (
    !base::requireNamespace("magick", quietly = TRUE)
  ) {
    cli::cli_warn(
      c(
        "Package {.pkg magick} is not installed.",
        "i" = "Returning first frame path instead of GIF."
      )
    )

    return(
      base::list(
        animation_path = vec_frame_paths[[1]],
        used_magick = FALSE
      )
    )
  }

  base::dir.create(
    path = base::dirname(output_path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  gif_image <-
    magick::image_read(vec_frame_paths) |>
    magick::image_animate(fps = fps, loop = loop)

  flag_can_optimize <-
    base::exists(
      x = "image_optimize",
      envir = base::asNamespace("magick"),
      mode = "function"
    )

  if (
    isTRUE(optimize) &&
      isTRUE(flag_can_optimize)
  ) {
    gif_image <-
      magick::image_optimize(gif_image)
  }

  magick::image_write(
    image = gif_image,
    path = output_path,
    format = "gif"
  )

  return(
    base::list(
      animation_path = base::normalizePath(
        output_path,
        winslash = "/",
        mustWork = FALSE
      ),
      used_magick = TRUE
    )
  )
}


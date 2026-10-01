#' @title Save a Manuscript Figure in Publication Formats
#' @description
#' Saves one plot as vector PDF, submission-resolution TIFF, and review PNG
#' using physical settings derived from the active graphical configuration.
#' @param plot A `ggplot` or compatible assembled plot object.
#' @param file_base Absolute or project-relative output path without extension.
#' @param graphical_options Named graphical configuration list containing
#' `width`, `height`, `units`, `dpi`, and `bg`.
#' @return Named character vector containing the three written file paths.
#' @export
save_manuscript_figure <- function(
    plot,
    file_base,
    graphical_options) {
  assertthat::assert_that(
    base::inherits(plot, base::c("gg", "ggplot", "grob", "gtable")),
    msg = "`plot` must be a ggplot-compatible plot object."
  )
  assertthat::assert_that(
    base::is.character(file_base),
    base::length(file_base) == 1L,
    !base::is.na(file_base),
    base::nzchar(file_base),
    fs::path_ext(file_base) == "",
    msg = "`file_base` must be one path without a file extension."
  )
  config_manuscript <-
    resolve_manuscript_graphical_options(graphical_options)

  path_output <-
    base::dirname(file_base)
  base::dir.create(
    path = path_output,
    recursive = TRUE,
    showWarnings = FALSE
  )

  vec_files <-
    base::c(
      pdf = stringr::str_glue("{file_base}.pdf"),
      tiff = stringr::str_glue("{file_base}.tiff"),
      png = stringr::str_glue("{file_base}.png")
    )

  ggview::save_ggplot(
    plot = plot,
    file = vec_files[["pdf"]],
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = config_manuscript[["bg"]]
  )
  ggview::save_ggplot(
    plot = plot,
    file = vec_files[["tiff"]],
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["submission_dpi"]],
    bg = config_manuscript[["bg"]],
    device = ragg::agg_tiff
  )
  ggview::save_ggplot(
    plot = plot,
    file = vec_files[["png"]],
    width = config_manuscript[["width"]],
    height = config_manuscript[["height"]],
    units = config_manuscript[["units"]],
    dpi = config_manuscript[["review_dpi"]],
    bg = config_manuscript[["bg"]],
    device = ragg::agg_png
  )

  return(vec_files)
}

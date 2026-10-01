#' @title Resolve Manuscript Figure Output Settings
#' @description
#' Converts the shared graphical pixel canvas to fixed physical dimensions.
#' Review PNG files retain the configured resolution and submission TIFF files
#' use twice that resolution without changing their physical dimensions.
#' @param graphical_options Named graphical configuration list containing
#' `width`, `height`, `units`, `dpi`, and `bg`.
#' @return Named list containing physical dimensions, review and submission
#' resolutions, and the background colour.
#' @export
resolve_manuscript_graphical_options <- function(graphical_options) {
  vec_required_settings <-
    base::c("width", "height", "units", "dpi", "bg")
  assertthat::assert_that(
    base::is.list(graphical_options),
    base::all(
      vec_required_settings %in% base::names(graphical_options)
    ),
    msg = "The shared graphical configuration is incomplete."
  )

  unit_input <-
    graphical_options[["units"]]
  assertthat::assert_that(
    unit_input %in% base::c("px", "in", "cm", "mm"),
    msg = "Graphical units must be px, in, cm, or mm."
  )

  dpi_review <-
    base::as.numeric(graphical_options[["dpi"]])
  assertthat::assert_that(
    base::is.finite(dpi_review),
    dpi_review > 0,
    msg = "Graphical DPI must be a positive finite value."
  )

  if (base::identical(unit_input, "px")) {
    width_output <-
      graphical_options[["width"]] / dpi_review
    height_output <-
      graphical_options[["height"]] / dpi_review
    unit_output <-
      "in"
  } else {
    width_output <-
      graphical_options[["width"]]
    height_output <-
      graphical_options[["height"]]
    unit_output <-
      unit_input
  }

  return(
    base::list(
      width = width_output,
      height = height_output,
      units = unit_output,
      review_dpi = dpi_review,
      submission_dpi = dpi_review * 2,
      bg = graphical_options[["bg"]]
    )
  )
}

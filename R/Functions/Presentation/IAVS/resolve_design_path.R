#' @title Resolve path to the design configuration file
#' @description Searches for `design_config.json` in the current directory,
#'   the presentation root, and the standard repository location.
#' @param path Character scalar. File name or path to resolve.
#' @return Character scalar -- absolute path to the found file.
#' @keywords internal
#' @examples
#' \dontrun{
#' resolve_design_path()
#' }
resolve_design_path <- function(path = "design_config.json") {
  assertthat::assert_that(
    base::is.character(path),
    base::length(path) == 1L,
    msg = "'path' must be a character scalar."
  )

  if (
    base::file.exists(path)
  ) {
    return(base::normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  if (
    !base::exists("get_presentation_dir", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "get_presentation_dir.R"
      )
    )
  }

  vec_candidate <-
    base::file.path(get_presentation_dir(), path)

  if (
    base::file.exists(vec_candidate)
  ) {
    return(
      base::normalizePath(vec_candidate, winslash = "/", mustWork = TRUE)
    )
  }

  vec_repo_candidate <-
    here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      path
    )

  if (
    base::file.exists(vec_repo_candidate)
  ) {
    return(
      base::normalizePath(
        vec_repo_candidate,
        winslash = "/",
        mustWork = TRUE
      )
    )
  }

  cli::cli_abort("Cannot find design config: {path}")
}

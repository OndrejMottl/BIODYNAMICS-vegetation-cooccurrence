#' @title Get presentation root directory
#' @description Resolves the root directory of the CSPE 2026 presentation
#'   from `CSPE_PRESENTATION_DIR` or the repository root via `{here}`.
#' @return Character scalar -- absolute path to the presentation root.
#' @keywords internal
#' @examples
#' \dontrun{
#' resolve_cspe_presentation_directory()
#' }
resolve_cspe_presentation_directory <- function() {
  vec_env_dir <-
    base::Sys.getenv("CSPE_PRESENTATION_DIR", unset = NA_character_)

  if (
    !base::is.na(vec_env_dir) && base::nzchar(vec_env_dir)
  ) {
    return(
      base::normalizePath(vec_env_dir, winslash = "/", mustWork = FALSE)
    )
  }

  return(
    here::here(
      "Documentation",
      "Presentations",
      "CSPE_2026"
    )
  )
}

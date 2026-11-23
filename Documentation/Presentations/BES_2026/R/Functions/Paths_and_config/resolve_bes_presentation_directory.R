#' @title Get presentation root directory
#' @description Resolves the root directory of the BES 2026 presentation
#'   from `BES_PRESENTATION_DIR` or the repository root via `{here}`.
#' @return Character scalar -- absolute path to the presentation root.
#' @keywords internal
#' @examples
#' \dontrun{
#' resolve_bes_presentation_directory()
#' }
resolve_bes_presentation_directory <- function() {
  vec_env_dir <-
    base::Sys.getenv("BES_PRESENTATION_DIR", unset = NA_character_)

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
      "BES_2026"
    )
  )
}

#' @title Load design configuration from JSON
#' @description Reads a `design_config.json` file and returns a named
#'   list containing the parsed configuration, resolved file path, and
#'   parent directory.
#' @param path Character scalar. Path to the JSON file.
#' @return A named list with `config`, `config_path`, and `config_dir`.
#' @examples
#' \dontrun{
#' design <- load_design_config()
#' }
load_design_config <- function(path = "design_config.json") {
  assertthat::assert_that(
    base::is.character(path),
    base::length(path) == 1L,
    msg = "'path' must be a character scalar."
  )

  if (
    !base::exists("resolve_design_path", mode = "function")
  ) {
    base::source(
      here::here(
        "R",
        "Functions",
        "Presentation",
        "IAVS",
        "resolve_design_path.R"
      )
    )
  }

  vec_config_path <-
    resolve_design_path(path)

  return(
    base::list(
      config = jsonlite::fromJSON(
        vec_config_path,
        simplifyVector = FALSE
      ),
      config_path = vec_config_path,
      config_dir = base::dirname(vec_config_path)
    )
  )
}

#' @title Load IAVS Presentation Functions
#' @description
#' Sources presentation-local helper files in deterministic path order.
#' @param functions_dir
#' Root directory containing the local IAVS helper files.
#' @param envir
#' Environment receiving the sourced functions.
#' @return
#' Sorted normalized paths to sourced files, invisibly.
load_iavs_functions <- function(
    functions_dir = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "R",
      "Functions"
    ),
    envir = base::globalenv()) {
  assertthat::assert_that(
    base::dir.exists(functions_dir),
    msg = "The IAVS presentation function directory does not exist."
  )

  vec_function_files <-
    base::list.files(
      path = functions_dir,
      pattern = "[.]R$",
      full.names = TRUE,
      recursive = TRUE
    ) |>
    base::normalizePath(
      winslash = "/",
      mustWork = TRUE
    ) |>
    base::sort()

  assertthat::assert_that(
    base::length(vec_function_files) > 0L,
    msg = "No IAVS presentation function files were found."
  )

  for (
    function_file in vec_function_files
  ) {
    base::sys.source(
      file = function_file,
      envir = envir
    )
  }

  return(base::invisible(vec_function_files))
}

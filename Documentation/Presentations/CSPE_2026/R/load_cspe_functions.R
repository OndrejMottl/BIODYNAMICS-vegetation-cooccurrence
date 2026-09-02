#' @title Load CSPE Presentation Functions
#' @description
#' Sources presentation-local helper files in deterministic path order.
#' @param functions_dir
#' Root directory containing the local CSPE helper files.
#' @param envir
#' Environment receiving the sourced functions.
#' @return
#' Sorted normalized paths to sourced files, invisibly.
load_cspe_functions <- function(
    functions_dir = here::here(
      "Documentation",
      "Presentations",
      "CSPE_2026",
      "R",
      "Functions"
    ),
    envir = base::globalenv()) {
  assertthat::assert_that(
    base::dir.exists(functions_dir),
    msg = "The CSPE presentation function directory does not exist."
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
    msg = "No CSPE presentation function files were found."
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

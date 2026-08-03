#' @title Load Trait Corrections
#' @description
#' Loads a trait-corrections CSV file without applying or approving
#' its instructions.
#' @param path_trait_corrections
#' A single character string giving the path to a trait-corrections
#' CSV file.
#' @return
#' A tibble containing the correction instructions stored in
#' `path_trait_corrections`.
#' @seealso [validate_trait_corrections()], [correct_trait_records()],
#'   [write_trait_quality_control_report()]
#' @export
load_trait_corrections <- function(path_trait_corrections) {
  assertthat::assert_that(
    base::is.character(path_trait_corrections),
    msg = "path_trait_corrections must be a character string."
  )

  assertthat::assert_that(
    base::length(path_trait_corrections) == 1L,
    msg = "path_trait_corrections must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::file.exists(path_trait_corrections),
    msg = "path_trait_corrections: file does not exist at the given path."
  )

  data_trait_corrections <-
    readr::read_csv(
      path_trait_corrections,
      show_col_types = FALSE
    )

  return(data_trait_corrections)
}

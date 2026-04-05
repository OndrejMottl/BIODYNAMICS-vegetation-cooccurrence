#' @title Validate Trait Manual Corrections File
#' @description
#' Reads the trait manual corrections CSV file and checks that every
#' row has been reviewed by a human. Acts as a pipeline guard: if any
#' row has a `CHECKED` value that is not `TRUE` (i.e. is `NA`,
#' `FALSE`, or absent), the function calls `cli::cli_abort()` listing
#' the number of unchecked rows so the pipeline stops until a human
#' has signed off the file.
#' @param path_corrections
#' A character scalar giving the file path to
#' `trait_manual_corrections.csv`.
#' @return
#' A tibble of validated corrections (all rows have `CHECKED == TRUE`)
#' when every row is approved. Aborts via `cli::cli_abort()` if any
#' row is not yet validated.
#' @details
#' The expected CSV columns are: `taxon_name`, `trait_domain_name`,
#' `action`, `scale_factor`, `notes`, `CHECKED`. The abort message
#' reports exactly how many rows have not been validated and instructs
#' the user to set `CHECKED = TRUE` after reviewing.
#' @seealso [generate_trait_qc_report()], [apply_trait_corrections()]
#' @export
validate_trait_corrections <- function(path_corrections) {
  assertthat::assert_that(
    base::is.character(path_corrections),
    msg = "path_corrections must be a character string."
  )

  assertthat::assert_that(
    base::length(path_corrections) == 1L,
    msg = "path_corrections must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::file.exists(path_corrections),
    msg = "path_corrections: file does not exist at the given path."
  )

  data_corrections <-
    readr::read_csv(
      path_corrections,
      show_col_types = FALSE
    )

  if (!"CHECKED" %in% base::colnames(data_corrections)) {
    cli::cli_abort(
      "Corrections file is missing the required {.field CHECKED} column."
    )
  }

  vec_not_checked <-
    base::is.na(data_corrections$CHECKED) |
      data_corrections$CHECKED != TRUE

  n_unchecked <-
    base::sum(vec_not_checked)

  if (n_unchecked > 0L) {
    cli::cli_abort(
      c(
        "{n_unchecked} row{?s} have not been validated (CHECKED != TRUE).",
        "i" = "Set {.field CHECKED} = TRUE after reviewing each row."
      )
    )
  }

  data_corrections
}

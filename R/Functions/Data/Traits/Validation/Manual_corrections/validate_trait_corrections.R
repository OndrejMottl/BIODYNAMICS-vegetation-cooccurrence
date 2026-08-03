#' @title Validate Trait Correction Approval
#' @description
#' Checks that every trait-correction row has been reviewed by a
#' human. Acts as a pipeline guard: if any row has a `CHECKED` value
#' that is not `TRUE`, the function calls `cli::cli_abort()` so the
#' pipeline stops until a human has signed off every row.
#' @param data_trait_corrections
#' A data frame loaded by [load_trait_corrections()]. Must contain a
#' logical `CHECKED` column.
#' @return
#' A tibble of validated corrections (all rows have `CHECKED == TRUE`)
#' when every row is approved. Aborts via `cli::cli_abort()` if any
#' row is not yet validated.
#' @details
#' The abort message reports exactly how many rows have not been
#' validated and instructs the user to set `CHECKED = TRUE` after
#' reviewing.
#' @seealso [load_trait_corrections()], [correct_trait_records()],
#'   [write_trait_quality_control_report()]
#' @export
validate_trait_corrections <- function(data_trait_corrections) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_corrections),
    msg = "data_trait_corrections must be a data frame."
  )

  if (
    !"CHECKED" %in% base::colnames(data_trait_corrections)
  ) {
    cli::cli_abort(
      "Corrections file is missing the required {.field CHECKED} column."
    )
  }

  vec_not_checked <-
    base::is.na(data_trait_corrections[["CHECKED"]]) |
      data_trait_corrections[["CHECKED"]] != TRUE

  n_unchecked <-
    base::sum(vec_not_checked)

  if (
    n_unchecked > 0L
  ) {
    cli::cli_abort(
      c(
        "{n_unchecked} row{?s} have not been validated (CHECKED != TRUE).",
        "i" = "Set {.field CHECKED} = TRUE after reviewing each row."
      )
    )
  }

  data_trait_corrections <-
    tibble::as_tibble(data_trait_corrections)

  return(data_trait_corrections)
}

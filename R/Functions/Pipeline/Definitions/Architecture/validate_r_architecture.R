#' @title Validate R Architecture
#' @description
#' Enforces the maintained architecture-findings contract and aborts when any
#' unresolved blocking finding remains.
#' @param data_findings
#' Data frame returned by `diagnose_r_architecture()`.
#' @return
#' The validated findings data frame.
#' @examples
#' validate_r_architecture(
#'   data_findings = tibble::tibble(
#'     finding_id = character(),
#'     finding_type = character(),
#'     current_path = character(),
#'     symbol = character(),
#'     owner_issue = character(),
#'     message = character(),
#'     resolution_status = character(),
#'     exception_id = character()
#'   )
#' )
#' @export
validate_r_architecture <- function(data_findings) {
  vec_required_columns <-
    base::c(
      "finding_id",
      "finding_type",
      "current_path",
      "symbol",
      "owner_issue",
      "message",
      "resolution_status",
      "exception_id"
    )

  assertthat::assert_that(
    base::is.data.frame(data_findings),
    msg = "`data_findings` must be a data frame."
  )
  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_findings)),
    msg = "`data_findings` does not use the maintained schema."
  )
  assertthat::assert_that(
    base::all(
      data_findings[["resolution_status"]] %in%
        base::c("blocking", "excepted")
    ),
    msg = "Architecture resolution status must be blocking or excepted."
  )

  data_blocking_findings <-
    data_findings |>
    dplyr::filter(.data[["resolution_status"]] == "blocking")

  if (
    base::nrow(data_blocking_findings) > 0L
  ) {
    cli::cli_abort(
      message = base::c(
        "R architecture validation found blocking findings.",
        "x" = stringr::str_c(
          data_blocking_findings[["finding_id"]],
          data_blocking_findings[["current_path"]],
          sep = ": ",
          collapse = ", "
        )
      ),
      class = "biodynamics_error_architecture_blocking"
    )
  }

  return(data_findings)
}

#' @title Diagnose R Architecture
#' @description
#' Converts current raw architecture findings into the maintained findings
#' contract after applying explicit repository exceptions.
#' @param data_findings
#' Data frame of current raw architecture findings.
#' @param data_exceptions
#' Data frame using the maintained exception-ledger schema.
#' @return
#' A data frame using the maintained architecture-findings schema.
#' @examples
#' diagnose_r_architecture(
#'   data_findings = tibble::tibble(
#'     finding_type = character(),
#'     current_path = character(),
#'     symbol = character(),
#'     owning_issue = character(),
#'     message = character()
#'   ),
#'   data_exceptions = tibble::tibble(
#'     exception_id = character(),
#'     finding_type = character(),
#'     current_path = character(),
#'     symbol = character(),
#'     owner_issue = character(),
#'     rationale = character(),
#'     expiry_issue = character()
#'   )
#' )
#' @export
diagnose_r_architecture <- function(
    data_findings,
    data_exceptions) {
  res_findings <-
    apply_r_architecture_exceptions(
      data_findings = data_findings,
      data_exceptions = data_exceptions
    )

  return(res_findings)
}

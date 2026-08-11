#' @title Apply R Architecture Exceptions
#' @description
#' Matches explicit architecture exceptions to current findings and assigns
#' each finding a blocking or excepted resolution status.
#' @param data_findings
#' Data frame with finding type, path, symbol, owner, and message columns.
#' @param data_exceptions
#' Data frame using the maintained architecture-exception ledger schema.
#' @return
#' A data frame using the maintained architecture-findings schema.
#' @details
#' Exceptions match on finding type, path, symbol, and owner issue. Duplicate,
#' malformed, or orphaned exceptions are rejected or returned as blocking
#' findings so exceptions cannot silently outlive their owned finding.
#' @examples
#' data_findings <-
#'   tibble::tibble(
#'     finding_type = "function_naming",
#'     current_path = "R/Functions/example.R",
#'     symbol = "example",
#'     owning_issue = "#1",
#'     message = "Review the function name."
#'   )
#' apply_r_architecture_exceptions(
#'   data_findings = data_findings,
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
apply_r_architecture_exceptions <- function(
    data_findings,
    data_exceptions) {
  vec_finding_columns <-
    base::c(
      "finding_type",
      "current_path",
      "symbol",
      "owning_issue",
      "message"
    )

  vec_exception_columns <-
    base::c(
      "exception_id",
      "finding_type",
      "current_path",
      "symbol",
      "owner_issue",
      "rationale",
      "expiry_issue"
    )

  assertthat::assert_that(
    base::is.data.frame(data_findings),
    msg = "`data_findings` must be a data frame."
  )
  assertthat::assert_that(
    base::all(vec_finding_columns %in% base::colnames(data_findings)),
    msg = "`data_findings` does not use the required schema."
  )
  assertthat::assert_that(
    base::is.data.frame(data_exceptions),
    msg = "`data_exceptions` must be a data frame."
  )
  assertthat::assert_that(
    base::all(vec_exception_columns %in% base::colnames(data_exceptions)),
    msg = "`data_exceptions` does not use the required schema."
  )

  vec_required_exception_columns <-
    base::setdiff(vec_exception_columns, "symbol")

  flag_invalid_exception <-
    data_exceptions |>
    dplyr::select(dplyr::all_of(vec_required_exception_columns)) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        .fns = ~ base::is.na(.x) | !base::nzchar(.x)
      )
    ) |>
    base::as.matrix() |>
    base::rowSums() |>
    base::as.logical()

  if (
    base::any(flag_invalid_exception)
  ) {
    cli::cli_abort(
      message = "Architecture exceptions contain missing required values.",
      class = "biodynamics_error_architecture_exception_schema"
    )
  }

  if (
    base::anyDuplicated(data_exceptions[["exception_id"]]) > 0L
  ) {
    cli::cli_abort(
      message = "Architecture exception IDs must be unique.",
      class = "biodynamics_error_architecture_exception_duplicate_id"
    )
  }

  data_findings_prepared <-
    data_findings |>
    dplyr::mutate(
      owner_issue = .data[["owning_issue"]],
      finding_key = stringr::str_c(
        .data[["finding_type"]],
        dplyr::coalesce(.data[["current_path"]], "<NA>"),
        dplyr::coalesce(.data[["symbol"]], "<NA>"),
        dplyr::coalesce(.data[["owning_issue"]], "<NA>"),
        sep = "|"
      )
    )

  data_exceptions_prepared <-
    data_exceptions |>
    dplyr::mutate(
      finding_key = stringr::str_c(
        .data[["finding_type"]],
        dplyr::coalesce(.data[["current_path"]], "<NA>"),
        dplyr::coalesce(.data[["symbol"]], "<NA>"),
        dplyr::coalesce(.data[["owner_issue"]], "<NA>"),
        sep = "|"
      )
    )

  if (
    base::anyDuplicated(data_exceptions_prepared[["finding_key"]]) > 0L
  ) {
    cli::cli_abort(
      message = "Architecture exceptions must target unique findings.",
      class = "biodynamics_error_architecture_exception_duplicate_key"
    )
  }

  vec_exception_indices <-
    base::match(
      data_findings_prepared[["finding_key"]],
      data_exceptions_prepared[["finding_key"]]
    )

  data_matched_findings <-
    data_findings_prepared |>
    dplyr::mutate(
      resolution_status = dplyr::if_else(
        base::is.na(vec_exception_indices),
        "blocking",
        "excepted"
      ),
      exception_id = data_exceptions_prepared[["exception_id"]][
        vec_exception_indices
      ]
    ) |>
    dplyr::select(
      "finding_type",
      "current_path",
      "symbol",
      "owner_issue",
      "message",
      "resolution_status",
      "exception_id"
    )

  vec_matched_exception_ids <-
    data_matched_findings[["exception_id"]] |>
    purrr::discard(base::is.na)

  data_orphaned_exceptions <-
    data_exceptions_prepared |>
    dplyr::filter(
      !.data[["exception_id"]] %in% vec_matched_exception_ids
    ) |>
    dplyr::mutate(
      finding_type = "exception_without_finding",
      message = stringr::str_glue(
        "Exception {.data[['exception_id']]} has no current finding."
      ),
      resolution_status = "blocking"
    ) |>
    dplyr::select(
      "finding_type",
      "current_path",
      "symbol",
      "owner_issue",
      "message",
      "resolution_status",
      "exception_id"
    )

  res_findings <-
    dplyr::bind_rows(
      data_matched_findings,
      data_orphaned_exceptions
    ) |>
    dplyr::arrange(
      .data[["finding_type"]],
      .data[["current_path"]],
      .data[["symbol"]]
    ) |>
    dplyr::mutate(
      finding_id = stringr::str_c(
        "ARCH-FINDING-",
        stringr::str_pad(
          dplyr::row_number(),
          width = 4L,
          pad = "0"
        )
      ),
      .before = 1L
    ) |>
    dplyr::select(
      "finding_id",
      "finding_type",
      "current_path",
      "symbol",
      "owner_issue",
      "message",
      "resolution_status",
      "exception_id"
    )

  return(res_findings)
}

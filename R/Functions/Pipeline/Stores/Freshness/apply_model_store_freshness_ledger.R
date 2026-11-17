#' @title Apply the Model Store Freshness Ledger
#' @description
#' Marks store-freshness findings that a ledger row covers and adds a blocking
#' finding for every ledger row that no longer covers anything.
#' @param data_findings
#' Findings from [diagnose_model_store_freshness()] with an added
#' `store_path_relative` column.
#' @param data_ledger
#' Ledger from [load_model_store_freshness_ledger()].
#' @param vec_inspected_store_paths
#' Relative paths of every store inspected in this run. Ledger rows for other
#' stores are ignored, so a scoped run never reports them as stale.
#' @return
#' `data_findings` with an added `resolution_status` column (`blocking`,
#' `ledger_covered`, or `informational`), followed by one `stale_ledger_row`
#' finding with status `blocking` for each inspected ledger row that matches
#' no blocking finding.
#' @details
#' A ledger row covers a blocking finding when the store paths are equal and
#' its `target_pattern` matches the whole target name. Non-blocking findings
#' are never covered and stay `informational`.
#' @seealso [validate_model_store_freshness()]
#' @examples
#' apply_model_store_freshness_ledger(
#'   data_findings = tibble::tibble(
#'     store_path = "/abs/Data/targets/a/pipeline",
#'     store_path_relative = "Data/targets/a/pipeline",
#'     target_name = "list_jsdm_variance_partition_genus",
#'     finding_type = "outdated",
#'     flag_blocking = TRUE,
#'     detail = NA_character_
#'   ),
#'   data_ledger = tibble::tibble(
#'     store_path = "Data/targets/a/pipeline",
#'     target_pattern = "list_jsdm_variance_partition_.*",
#'     reason = "lambda_cov = 0",
#'     evidence = "equivalence test",
#'     owner = "Ondrej Mottl",
#'     expiry_issue = "#999"
#'   ),
#'   vec_inspected_store_paths = "Data/targets/a/pipeline"
#' )
#' @export
apply_model_store_freshness_ledger <- function(
    data_findings,
    data_ledger,
    vec_inspected_store_paths) {
  vec_finding_columns <-
    base::c(
      "store_path",
      "store_path_relative",
      "target_name",
      "finding_type",
      "flag_blocking",
      "detail"
    )
  vec_ledger_columns <-
    base::c(
      "store_path",
      "target_pattern",
      "reason",
      "evidence",
      "owner",
      "expiry_issue"
    )

  assertthat::assert_that(
    base::is.data.frame(data_findings),
    base::all(vec_finding_columns %in% base::names(data_findings)),
    msg = "`data_findings` does not use the store-freshness findings schema."
  )
  assertthat::assert_that(
    base::is.data.frame(data_ledger),
    base::all(vec_ledger_columns %in% base::names(data_ledger)),
    msg = "`data_ledger` does not use the freshness-ledger schema."
  )
  assertthat::assert_that(
    base::is.character(vec_inspected_store_paths),
    msg = "`vec_inspected_store_paths` must be a character vector."
  )

  data_ledger_inspected <-
    data_ledger |>
    dplyr::filter(.data[["store_path"]] %in% vec_inspected_store_paths) |>
    dplyr::mutate(ledger_row_id = dplyr::row_number())

  data_matches <-
    data_findings |>
    dplyr::mutate(finding_row_id = dplyr::row_number()) |>
    dplyr::filter(.data[["flag_blocking"]]) |>
    dplyr::select("finding_row_id", "store_path_relative", "target_name") |>
    dplyr::inner_join(
      data_ledger_inspected |>
        dplyr::select("ledger_row_id", "store_path", "target_pattern"),
      by = dplyr::join_by(store_path_relative == store_path),
      relationship = "many-to-many"
    ) |>
    dplyr::filter(
      stringr::str_detect(
        string = .data[["target_name"]],
        pattern = stringr::str_c("^(?:", .data[["target_pattern"]], ")$")
      )
    )

  data_findings_resolved <-
    data_findings |>
    dplyr::mutate(
      finding_row_id = dplyr::row_number(),
      resolution_status = dplyr::case_when(
        !.data[["flag_blocking"]] ~ "informational",
        .data[["finding_row_id"]] %in% data_matches[["finding_row_id"]] ~
          "ledger_covered",
        .default = "blocking"
      )
    ) |>
    dplyr::select(-"finding_row_id")

  data_stale <-
    data_ledger_inspected |>
    dplyr::filter(
      !.data[["ledger_row_id"]] %in% data_matches[["ledger_row_id"]]
    ) |>
    dplyr::mutate(
      store_path_relative = .data[["store_path"]],
      store_path = NA_character_,
      target_name = .data[["target_pattern"]],
      finding_type = "stale_ledger_row",
      flag_blocking = TRUE,
      detail = stringr::str_glue(
        "Ledger row matches no outdated target (expires with ",
        "{.data[['expiry_issue']]})."
      ) |>
        base::as.character(),
      resolution_status = "blocking"
    ) |>
    dplyr::select(
      "store_path",
      "store_path_relative",
      "target_name",
      "finding_type",
      "flag_blocking",
      "detail",
      "resolution_status"
    )

  res <-
    dplyr::bind_rows(
      data_findings_resolved,
      data_stale
    )

  return(res)
}

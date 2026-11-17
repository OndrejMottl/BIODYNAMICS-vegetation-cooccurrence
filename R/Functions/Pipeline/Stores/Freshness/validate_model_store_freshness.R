#' @title Validate Model Store Freshness
#' @description
#' Aborts when resolved store-freshness findings still contain a blocking
#' finding: an outdated, never-built, or unexpectedly errored target that no
#' ledger row covers, a changed configuration, or a stale ledger row.
#' @param data_findings_resolved
#' Output of [apply_model_store_freshness_ledger()].
#' @return
#' Invisibly, `data_findings_resolved` when nothing blocks.
#' @seealso [diagnose_model_store_freshness()],
#'   [apply_model_store_freshness_ledger()]
#' @examples
#' validate_model_store_freshness(
#'   data_findings_resolved = tibble::tibble(
#'     store_path_relative = "Data/targets/a/pipeline",
#'     target_name = "always_cued_target",
#'     finding_type = "always_cued_not_evaluated",
#'     resolution_status = "informational"
#'   )
#' )
#' @export
validate_model_store_freshness <- function(data_findings_resolved) {
  assertthat::assert_that(
    base::is.data.frame(data_findings_resolved),
    base::all(
      base::c(
        "store_path_relative",
        "target_name",
        "finding_type",
        "resolution_status"
      ) %in% base::names(data_findings_resolved)
    ),
    msg = "`data_findings_resolved` must come from the freshness ledger."
  )

  data_blocking <-
    data_findings_resolved |>
    dplyr::filter(.data[["resolution_status"]] == "blocking")

  if (
    base::nrow(data_blocking) > 0L
  ) {
    data_blocking_summary <-
      data_blocking |>
      dplyr::count(
        .data[["store_path_relative"]],
        .data[["finding_type"]],
        name = "n_targets"
      )
    vec_summary_lines <-
      stringr::str_glue(
        "{data_blocking_summary[['store_path_relative']]}: ",
        "{data_blocking_summary[['n_targets']]} ",
        "{data_blocking_summary[['finding_type']]}"
      ) |>
      base::as.character() |>
      rlang::set_names("x")

    cli::cli_abort(
      base::c(
        "Published results depend on stores that are not current.",
        vec_summary_lines,
        "i" = stringr::str_c(
          "Rerun the listed targets, or record a deliberate exception in ",
          "the model store freshness ledger."
        )
      ),
      class = "model_store_not_current"
    )
  }

  return(base::invisible(data_findings_resolved))
}

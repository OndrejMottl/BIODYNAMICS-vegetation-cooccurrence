#' @title Combine Selected sjSDM Fold Artifacts
#' @description
#' Combines, deterministically orders, and validates complete out-of-fold
#' coverage across selected-candidate fold results.
#' @param list_fold_results
#' List of fold results from [run_sjsdm_selected_fold()] or the cached builder.
#' @param data_assignments
#' Location-level fold assignment table used to derive expected coverage.
#' @param taxon_names
#' Full ordered response-taxon names.
#' @return
#' Named list with combined predictions and fold diagnostics.
#' @export
combine_sjsdm_selected_fold_artifacts <- function(
    list_fold_results = NULL,
    data_assignments = NULL,
    taxon_names = NULL) {
  assertthat::assert_that(
    base::is.list(list_fold_results),
    base::is.data.frame(data_assignments),
    "row_indices" %in% base::colnames(data_assignments),
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    msg = "Selected-fold combination inputs are incomplete."
  )

  if (
    base::length(list_fold_results) == 0L
  ) {
    return(build_sjsdm_empty_selected_fold_artifacts())
  }

  flag_valid_results <-
    list_fold_results |>
    purrr::map_lgl(
      ~ base::is.list(.x) &&
        base::all(
          base::c("data_predictions", "data_diagnostics") %in%
            base::names(.x)
        ) &&
        base::is.data.frame(.x[["data_predictions"]]) &&
        base::is.data.frame(.x[["data_diagnostics"]])
    ) |>
    base::all()

  assertthat::assert_that(
    flag_valid_results,
    msg = "A selected-fold artifact result is incomplete."
  )

  data_predictions <-
    list_fold_results |>
    purrr::map("data_predictions") |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["row_index"]],
      base::match(.data[["taxon"]], taxon_names)
    )

  data_diagnostics <-
    list_fold_results |>
    purrr::map("data_diagnostics") |>
    purrr::list_rbind() |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  data_coverage <-
    data_predictions |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["row_index"]],
      .data[["taxon"]],
      name = "n_rows"
    )

  n_expected_rows <-
    base::sum(
      purrr::map_int(
        data_assignments[["row_indices"]],
        base::length
      )
    )

  if (
    base::nrow(data_coverage) !=
      n_expected_rows * base::length(taxon_names) ||
      base::any(data_coverage[["n_rows"]] != 1L)
  ) {
    cli::cli_abort(
      "Out-of-fold predictions do not provide complete row coverage."
    )
  }

  res <-
    base::list(
      data_predictions = data_predictions,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

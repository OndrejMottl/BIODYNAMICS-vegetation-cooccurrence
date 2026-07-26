#' @title Make sjSDM Tuning Branch Work Items
#' @description
#' Converts public tuning work items into a branchable table. Empty inputs
#' produce one explicit non-fitting sentinel so `{targets}` does not branch
#' over an empty target.
#' @param data_work_items
#' Work-item table returned by [build_sjsdm_tuning_work_items()]. It may be
#' empty when cross-validation is scientifically inapplicable.
#' @return
#' Work-item tibble with additive `tuning_applicable`. Non-empty inputs retain
#' every row and set the flag to `TRUE`; empty inputs return one typed sentinel
#' row with the flag set to `FALSE`.
#' @examples
#' \dontrun{
#' make_sjsdm_tuning_branch_work_items(
#'   data_work_items = data_sjsdm_tuning_work_items
#' )
#' }
#' @export
make_sjsdm_tuning_branch_work_items <- function(
    data_work_items = NULL) {
  vec_required_columns <-
    base::c(
      "work_item_id",
      "fold_key",
      "repeat_id",
      "fold_id",
      "candidate_id",
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial",
      "tuning_seed"
    )

  assertthat::assert_that(
    base::is.data.frame(data_work_items),
    base::all(
      vec_required_columns %in% base::colnames(data_work_items)
    ),
    msg = "Tuning work-item schema is incomplete."
  )

  if (
    base::nrow(data_work_items) > 0L
  ) {
    res_applicable <-
      data_work_items |>
      dplyr::mutate(tuning_applicable = TRUE)

    return(res_applicable)
  }

  res_sentinel <-
    tibble::tibble(
      work_item_id = "sjsdm_cv_not_applicable",
      fold_key = NA_character_,
      repeat_id = NA_integer_,
      fold_id = NA_integer_,
      candidate_id = NA_character_,
      alpha_cov = NA_real_,
      alpha_coef = NA_real_,
      alpha_spatial = NA_real_,
      lambda_cov = NA_real_,
      lambda_coef = NA_real_,
      lambda_spatial = NA_real_,
      tuning_seed = NA_integer_,
      tuning_applicable = FALSE
    )

  return(res_sentinel)
}

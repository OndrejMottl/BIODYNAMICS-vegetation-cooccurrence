#' @title Build an Empty Unit Regularization Selection
#' @description
#' Constructs the exact typed-empty unit-selection table used when unit-level
#' cross-validation is scientifically inapplicable.
#' @return Typed empty unit regularization-selection tibble.
#' @export
build_sjsdm_empty_unit_regularization_selection <- function() {
  res <-
    tibble::tibble(
      candidate_id = base::character(),
      alpha_cov = base::numeric(),
      alpha_coef = base::numeric(),
      alpha_spatial = base::numeric(),
      lambda_cov = base::numeric(),
      lambda_coef = base::numeric(),
      lambda_spatial = base::numeric(),
      selection_metric = base::character(),
      selection_metric_value = base::numeric(),
      n_repeats = base::integer(),
      candidate_rank = base::integer(),
      cv_strategy = base::character(),
      regularization_source = base::character()
    )

  return(res)
}

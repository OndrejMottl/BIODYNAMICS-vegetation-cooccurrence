#' @title Summarise Fitted AUC
#' @description
#' Summarises finite species-level AUC values from fitted-model evaluation.
#' @param list_jsdm_evaluation_fitted
#' Fitted-model evaluation object, or `NULL`.
#' @return
#' A one-row tibble containing fitted AUC summary statistics.
#' @noRd
.summarise_fitted_auc <- function(list_jsdm_evaluation_fitted) {
  data_default <-
    tibble::tibble(
      fitted_auc_mean = NA_real_,
      fitted_auc_median = NA_real_,
      fitted_auc_n = 0L
    )

  if (
    base::is.null(list_jsdm_evaluation_fitted) ||
      !("data_taxon_metrics" %in% base::names(list_jsdm_evaluation_fitted))
  ) {
    return(data_default)
  }

  data_taxon_metrics <-
    list_jsdm_evaluation_fitted |>
    purrr::chuck("data_taxon_metrics")

  if (
    !base::is.data.frame(data_taxon_metrics) ||
      !("auc" %in% base::colnames(data_taxon_metrics))
  ) {
    return(data_default)
  }

  vec_auc_finite <-
    data_taxon_metrics |>
    dplyr::pull("auc") |>
    base::as.numeric() |>
    purrr::keep(base::is.finite)

  if (
    base::length(vec_auc_finite) == 0L
  ) {
    return(data_default)
  }

  res <-
    tibble::tibble(
      fitted_auc_mean = base::mean(vec_auc_finite),
      fitted_auc_median = stats::median(vec_auc_finite),
      fitted_auc_n = base::length(vec_auc_finite)
    )

  return(res)
}

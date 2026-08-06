#' @title Build an Empty Decomposition Variant Result
#' @description
#' Internal helper that constructs the stable failed-variant result schema.
#' @param route_id
#' Diagnostic route identifier.
#' @param repeat_id
#' Repeated-fold identifier.
#' @param fold_id
#' Fold identifier.
#' @param variant
#' Model variant identifier.
#' @param status
#' Failure status.
#' @param error_message
#' Captured error message.
#' @param warning_text
#' Collapsed warning text.
#' @param diagnostics
#' Optional one-row fold diagnostics.
#' @return
#' One-row failed-variant tibble.
#' @keywords internal
.build_empty_decomposition_variant <- function(
    route_id,
    repeat_id,
    fold_id,
    variant,
    status,
    error_message,
    warning_text = NA_character_,
    diagnostics = NULL) {
  data_diagnostics <-
    if (
      base::is.null(diagnostics)
    ) {
      tibble::tibble(
        n_train_samples = NA_integer_,
        n_test_samples = NA_integer_,
        n_taxa_raw = NA_integer_,
        n_taxa_retained = NA_integer_,
        n_taxa_dropped = NA_integer_
      )
    } else {
      diagnostics
    }

  res <-
    tibble::tibble(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      variant = variant,
      status = status,
      error_message = error_message,
      warning_text = warning_text,
      converged = FALSE,
      linear_trend_slope = NA_real_,
      median_diff = NA_real_,
      epochs_run = NA_integer_,
      early_stopping_triggered = NA,
      loss = NA_real_,
      brier = NA_real_,
      auc = NA_real_,
      auc_macro = NA_real_
    ) |>
    dplyr::bind_cols(data_diagnostics)

  return(res)
}

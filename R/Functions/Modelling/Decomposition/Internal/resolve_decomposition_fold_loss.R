#' @title Resolve One Decomposition Fold Loss
#' @description
#' Internal helper that returns a loss only when one variant row matches.
#' @param data_fold
#' One route-repeat-fold data frame.
#' @param variant_name
#' Variant identifier to look up.
#' @return
#' One numeric loss or `NA_real_` when the match is not unique.
#' @keywords internal
.resolve_decomposition_fold_loss <- function(
    data_fold,
    variant_name) {
  vec_loss <-
    data_fold |>
    dplyr::filter(.data[["variant"]] == .env[["variant_name"]]) |>
    dplyr::pull(loss)

  if (
    base::length(vec_loss) == 1L
  ) {
    return(vec_loss[[1L]])
  }

  return(NA_real_)
}

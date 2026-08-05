#' @title Compute One Fold of Predictive Decomposition Shares
#' @description
#' Internal helper that converts full and reduced model values into the
#' established loss or higher-is-better metric share schema.
#' @param data_fold
#' One repeat-fold data frame containing full and reduced variants.
#' @param value_column
#' Name of the loss or performance column.
#' @param direction
#' Either `"lower"` for loss or `"higher"` for performance.
#' @param metric_name
#' Output metric label used when `direction = "higher"`.
#' @return
#' A three-row tibble containing component shares for one fold.
#' @keywords internal
.compute_predictive_fold_shares <- function(
    data_fold,
    value_column,
    direction = base::c("lower", "higher"),
    metric_name = value_column) {
  direction <-
    base::match.arg(direction)

  repeat_id <-
    data_fold[["repeat_id"]][[1L]]

  fold_id <-
    data_fold[["fold_id"]][[1L]]

  data_ok <-
    data_fold |>
    dplyr::filter(.data[["status"]] == "ok")

  data_full <-
    data_ok |>
    dplyr::filter(.data[["variant"]] == "full")

  value_full <-
    if (
      base::nrow(data_full) == 1L &&
        base::is.finite(data_full[[value_column]][[1L]])
    ) {
      data_full[[value_column]][[1L]]
    } else {
      NA_real_
    }

  data_components <-
    tibble::tibble(
      variant = base::c(
        "no_abiotic",
        "no_spatial",
        "no_associations"
      ),
      component = base::c("Abiotic", "Spatial", "Associations")
    )

  vec_reduced <-
    data_components |>
    dplyr::pull(variant) |>
    purrr::map_dbl(
      .f = function(variant_name) {
        data_variant <-
          data_ok |>
          dplyr::filter(
            .data[["variant"]] == .env[["variant_name"]]
          )

        if (
          base::nrow(data_variant) == 1L &&
            base::is.finite(data_variant[[value_column]][[1L]])
        ) {
          return(data_variant[[value_column]][[1L]])
        }

        return(NA_real_)
      }
    )

  vec_delta <-
    if (
      direction == "lower"
    ) {
      vec_reduced - value_full
    } else {
      value_full - vec_reduced
    }

  vec_delta_clamped <-
    base::pmax(vec_delta, 0)

  flag_defined <-
    base::all(base::is.finite(vec_delta_clamped)) &&
    base::sum(vec_delta_clamped) > 0

  vec_share <-
    if (
      flag_defined
    ) {
      vec_delta_clamped / base::sum(vec_delta_clamped) * 100
    } else {
      base::rep(NA_real_, base::nrow(data_components))
    }

  if (
    direction == "lower"
  ) {
    return(
      tibble::tibble(
        repeat_id = repeat_id,
        fold_id = fold_id,
        component = data_components[["component"]],
        loss_full = value_full,
        loss_reduced = vec_reduced,
        delta_loss = vec_delta,
        delta_loss_clamped = vec_delta_clamped,
        share = vec_share,
        defined = flag_defined
      )
    )
  }

  res <-
    tibble::tibble(
      repeat_id = repeat_id,
      fold_id = fold_id,
      metric_name = metric_name,
      component = data_components[["component"]],
      metric_full = value_full,
      metric_reduced = vec_reduced,
      delta_metric = vec_delta,
      delta_metric_clamped = vec_delta_clamped,
      share = vec_share,
      defined = flag_defined
    )

  return(res)
}

#' @title Compute Predictive Decomposition Shares
#' @description
#' Converts full and reduced predictive losses into fold-level
#' decomposition shares for abiotic predictors, spatial predictors,
#' and species associations.
#' @param data_fold_metrics
#' Data frame with columns `repeat_id`, `fold_id`, `variant`, and
#' `loss`. A `status` column is optional; when present, only rows with
#' status `"ok"` are used.
#' @return
#' A tibble with one row per repeat, fold, and component.
#' @export
compute_predictive_decomposition_shares <- function(data_fold_metrics) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    msg = "`data_fold_metrics` must be a data frame."
  )

  vec_required_cols <-
    c("repeat_id", "fold_id", "variant", "loss")

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(data_fold_metrics)),
    msg = stringr::str_glue(
      "`data_fold_metrics` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  data_metrics <-
    data_fold_metrics |>
    dplyr::mutate(
      status = if (
        "status" %in% base::colnames(data_fold_metrics)
      ) {
        .data$status
      } else {
        "ok"
      }
    )

  data_components <-
    tibble::tibble(
      variant = c("no_abiotic", "no_spatial", "no_associations"),
      component = c("Abiotic", "Spatial", "Associations")
    )

  make_undefined_rows <- function(repeat_id, fold_id) {
    data_components |>
      dplyr::transmute(
        repeat_id = repeat_id,
        fold_id = fold_id,
        component = .data$component,
        loss_full = NA_real_,
        loss_reduced = NA_real_,
        delta_loss = NA_real_,
        delta_loss_clamped = NA_real_,
        share = NA_real_,
        defined = FALSE
      )
  }

  compute_one_fold <- function(data_fold) {
    repeat_id <-
      data_fold |>
      dplyr::pull(.data$repeat_id) |>
      dplyr::first()

    fold_id <-
      data_fold |>
      dplyr::pull(.data$fold_id) |>
      dplyr::first()

    data_ok <-
      data_fold |>
      dplyr::filter(.data$status == "ok")

    data_full <-
      data_ok |>
      dplyr::filter(.data$variant == "full")

    if (
      base::nrow(data_full) != 1L ||
        !base::is.finite(data_full[["loss"]][[1L]])
    ) {
      return(
        make_undefined_rows(
          repeat_id = repeat_id,
          fold_id = fold_id
        )
      )
    }

    loss_full <-
      data_full[["loss"]][[1L]]

    res <-
      data_components |>
      dplyr::mutate(
        loss_full = .env$loss_full,
        loss_reduced = purrr::map_dbl(
          .x = .data$variant,
          .f = ~ {
            variant_name <- .x

            data_variant <-
              data_ok |>
              dplyr::filter(.data$variant == .env$variant_name)

            if (
              base::nrow(data_variant) == 1L &&
                base::is.finite(data_variant[["loss"]][[1L]])
            ) {
              data_variant[["loss"]][[1L]]
            } else {
              NA_real_
            }
          }
        ),
        delta_loss = .data$loss_reduced - .data$loss_full,
        delta_loss_clamped = base::pmax(.data$delta_loss, 0)
      )

    flag_defined <-
      base::all(base::is.finite(res[["delta_loss_clamped"]])) &&
      base::sum(res[["delta_loss_clamped"]]) > 0

    if (
      flag_defined
    ) {
      sum_delta <-
        base::sum(res[["delta_loss_clamped"]])

      res <-
        res |>
        dplyr::mutate(
          share = .data$delta_loss_clamped / .env$sum_delta * 100,
          defined = TRUE
        )
    } else {
      res <-
        res |>
        dplyr::mutate(
          share = NA_real_,
          defined = FALSE
        )
    }

    res <-
      res |>
      dplyr::mutate(
        repeat_id = repeat_id,
        fold_id = fold_id
      ) |>
      dplyr::select(
        repeat_id,
        fold_id,
        component,
        loss_full,
        loss_reduced,
        delta_loss,
        delta_loss_clamped,
        share,
        defined
      )

    return(res)
  }

  res <-
    data_metrics |>
    dplyr::group_by(
      .data$repeat_id,
      .data$fold_id
    ) |>
    dplyr::group_split(
      .keep = TRUE
    ) |>
    purrr::map(
      .f = compute_one_fold
    ) |>
    purrr::list_rbind()

  return(res)
}

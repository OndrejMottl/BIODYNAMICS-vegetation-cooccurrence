#' @title Compute Predictive Performance Decomposition Shares
#' @description
#' Converts full and reduced higher-is-better predictive metrics into
#' fold-level decomposition shares.
#' @param data_fold_metrics
#' Data frame with columns `repeat_id`, `fold_id`, `variant`, and the
#' metric named by `metric_column`. A `status` column is optional; when
#' present, only rows with status `"ok"` are used.
#' @param metric_column
#' Single character string. Name of the higher-is-better metric column.
#' @param metric_name
#' Single character string used in the output. Defaults to
#' `metric_column`.
#' @return
#' A tibble with one row per repeat, fold, and component.
#' @export
compute_predictive_performance_shares <- function(
    data_fold_metrics,
    metric_column,
    metric_name = metric_column) {
  assertthat::assert_that(
    base::is.data.frame(data_fold_metrics),
    msg = "`data_fold_metrics` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(metric_column),
    base::length(metric_column) == 1L,
    base::nchar(metric_column) > 0L,
    msg = "`metric_column` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(metric_name),
    base::length(metric_name) == 1L,
    base::nchar(metric_name) > 0L,
    msg = "`metric_name` must be a single non-empty character string."
  )

  vec_required_cols <-
    c("repeat_id", "fold_id", "variant", metric_column)

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
        metric_name = metric_name,
        component = .data$component,
        metric_full = NA_real_,
        metric_reduced = NA_real_,
        delta_metric = NA_real_,
        delta_metric_clamped = NA_real_,
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
        !base::is.finite(data_full[[metric_column]][[1L]])
    ) {
      return(
        make_undefined_rows(
          repeat_id = repeat_id,
          fold_id = fold_id
        )
      )
    }

    metric_full <-
      data_full[[metric_column]][[1L]]

    res <-
      data_components |>
      dplyr::mutate(
        metric_full = .env$metric_full,
        metric_reduced = purrr::map_dbl(
          .x = .data$variant,
          .f = ~ {
            variant_name <- .x

            data_variant <-
              data_ok |>
              dplyr::filter(.data$variant == .env$variant_name)

            if (
              base::nrow(data_variant) == 1L &&
                base::is.finite(data_variant[[metric_column]][[1L]])
            ) {
              data_variant[[metric_column]][[1L]]
            } else {
              NA_real_
            }
          }
        ),
        delta_metric = .data$metric_full - .data$metric_reduced,
        delta_metric_clamped = base::pmax(.data$delta_metric, 0)
      )

    flag_defined <-
      base::all(base::is.finite(res[["delta_metric_clamped"]])) &&
      base::sum(res[["delta_metric_clamped"]]) > 0

    if (
      flag_defined
    ) {
      sum_delta <-
        base::sum(res[["delta_metric_clamped"]])

      res <-
        res |>
        dplyr::mutate(
          share = .data$delta_metric_clamped / .env$sum_delta * 100,
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
        fold_id = fold_id,
        metric_name = metric_name
      ) |>
      dplyr::select(
        repeat_id,
        fold_id,
        metric_name,
        component,
        metric_full,
        metric_reduced,
        delta_metric,
        delta_metric_clamped,
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

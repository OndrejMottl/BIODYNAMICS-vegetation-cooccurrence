#' @title Summarize Decomposition Diagnostic Routes
#' @description
#' Computes fold-level shares and route-level summaries from variant
#' metrics produced by `run_decomposition_route_cv()`.
#' @param variant_metrics
#' Data frame with route, fold, variant, status, and loss columns.
#' @return
#' Named list with `data_fold_shares` and `data_route_summary`.
#' @export
summarize_decomposition_routes <- function(variant_metrics = NULL) {
  assertthat::assert_that(
    base::is.data.frame(variant_metrics),
    msg = "`variant_metrics` must be a data frame."
  )

  vec_required_columns <-
    c("route_id", "repeat_id", "fold_id", "variant", "status", "loss")

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(variant_metrics)),
    msg = "`variant_metrics` is missing required columns."
  )

  data_fold_shares <-
    variant_metrics |>
    dplyr::group_by(.data$route_id) |>
    dplyr::group_split() |>
    purrr::map(
      .f = ~ {
        route_id <-
          .x[["route_id"]][[1L]]

        .x |>
          compute_predictive_decomposition_shares() |>
          dplyr::mutate(
            route_id = route_id,
            .before = 1L
          )
      }
    ) |>
    purrr::list_rbind()

  data_share_summary <-
    data_fold_shares |>
    dplyr::group_by(.data$route_id) |>
    dplyr::group_split() |>
    purrr::map(
      .f = ~ {
        route_id <-
          .x[["route_id"]][[1L]]

        .x |>
          summarize_predictive_decomposition() |>
          dplyr::mutate(
            route_id = route_id,
            .before = 1L
          )
      }
    ) |>
    purrr::list_rbind()

  data_fold_status <-
    variant_metrics |>
    dplyr::group_by(
      .data$route_id,
      .data$repeat_id,
      .data$fold_id
    ) |>
    dplyr::group_split() |>
    purrr::map(
      .f = ~ {
        data_fold <-
          .x

        get_loss <- function(variant_name) {
          vec_loss <-
            data_fold |>
            dplyr::filter(.data$variant == .env$variant_name) |>
            dplyr::pull(.data$loss)

          if (
            base::length(vec_loss) == 1L
          ) {
            vec_loss[[1L]]
          } else {
            NA_real_
          }
        }

        full_loss <-
          get_loss(variant_name = "full")

        no_abiotic_loss <-
          get_loss(variant_name = "no_abiotic")

        no_spatial_loss <-
          get_loss(variant_name = "no_spatial")

        no_associations_loss <-
          get_loss(variant_name = "no_associations")

        all_variants_ok <-
          base::all(data_fold[["status"]] == "ok") &&
          base::nrow(data_fold) == 4L

        all_losses_finite <-
          base::all(
            base::is.finite(
              c(
                full_loss,
                no_abiotic_loss,
                no_spatial_loss,
                no_associations_loss
              )
            )
          )

        tibble::tibble(
          route_id = data_fold[["route_id"]][[1L]],
          repeat_id = data_fold[["repeat_id"]][[1L]],
          fold_id = data_fold[["fold_id"]][[1L]],
          all_variants_ok = all_variants_ok,
          all_losses_finite = all_losses_finite,
          full_loss = full_loss,
          no_abiotic_loss = no_abiotic_loss,
          no_spatial_loss = no_spatial_loss,
          no_associations_loss = no_associations_loss,
          fold_model_defined = all_variants_ok && all_losses_finite,
          full_beats_no_abiotic = full_loss < no_abiotic_loss,
          full_beats_no_spatial = full_loss < no_spatial_loss,
          full_beats_no_associations = full_loss <
            no_associations_loss
        )
      }
    ) |>
    purrr::list_rbind()

  data_route_status <-
    data_fold_status |>
    dplyr::group_by(.data$route_id) |>
    dplyr::summarise(
      n_folds = dplyr::n(),
      n_converged_folds = base::sum(
        .data$fold_model_defined,
        na.rm = TRUE
      ),
      proportion_full_beats_no_abiotic = base::mean(
        .data$full_beats_no_abiotic,
        na.rm = TRUE
      ),
      proportion_full_beats_no_spatial = base::mean(
        .data$full_beats_no_spatial,
        na.rm = TRUE
      ),
      proportion_full_beats_no_associations = base::mean(
        .data$full_beats_no_associations,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      proportion_converged_folds = .data$n_converged_folds /
        .data$n_folds
    )

  data_route_summary <-
    data_share_summary |>
    dplyr::left_join(
      data_route_status,
      by = dplyr::join_by(route_id)
    )

  res <-
    base::list(
      data_fold_shares = data_fold_shares,
      data_route_summary = data_route_summary
    )

  return(res)
}

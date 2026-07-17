#' @title Compute sjSDM Predictive Loss Shares
#' @description
#' Normalizes positive repeat-level log-loss effects across removed components.
#' @param data_repeat_effects
#' Repeat table returned by [summarise_sjsdm_decomposition_effects()].
#' @return
#' A named list containing repeat-level shares and descriptive share summaries.
#' @details
#' Negative effects are retained in `mean_delta_full_advantage` but contribute
#' zero to normalized shares. Shares are undefined when no component has a
#' positive effect. These are relative predictive-loss shares, not ecological
#' variance fractions, and component overlap prevents causal interpretation.
#' @examples
#' \dontrun{
#' compute_sjsdm_decomposition_loss_shares(data_repeat_effects)
#' }
#' @export
compute_sjsdm_decomposition_loss_shares <- function(
    data_repeat_effects = NULL) {
  vec_required_columns <-
    base::c(
      "scope",
      "reduced_variant",
      "component",
      "metric_id",
      "repeat_id",
      "mean_delta_full_advantage"
    )

  assertthat::assert_that(
    base::is.data.frame(data_repeat_effects),
    base::all(
      vec_required_columns %in% base::colnames(data_repeat_effects)
    ),
    msg = "data_repeat_effects must contain the repeat-effect contract."
  )

  data_loss_effects <-
    data_repeat_effects |>
    dplyr::filter(
      .data[["metric_id"]] == "log_loss",
      base::is.finite(.data[["mean_delta_full_advantage"]])
    ) |>
    dplyr::mutate(
      positive_delta = base::pmax(
        .data[["mean_delta_full_advantage"]],
        0
      )
    )

  assertthat::assert_that(
    base::nrow(data_loss_effects) > 0L,
    msg = "At least one finite repeat-level log-loss effect is required."
  )

  data_repeat_shares <-
    data_loss_effects |>
    dplyr::group_by(
      .data[["scope"]],
      .data[["repeat_id"]]
    ) |>
    dplyr::mutate(
      sum_positive_delta = base::sum(.data[["positive_delta"]]),
      defined = .data[["sum_positive_delta"]] > 0,
      share_percent = dplyr::if_else(
        .data[["defined"]],
        .data[["positive_delta"]] /
          .data[["sum_positive_delta"]] * 100,
        NA_real_
      )
    ) |>
    dplyr::ungroup()

  data_share_summary <-
    data_repeat_shares |>
    dplyr::filter(.data[["defined"]]) |>
    dplyr::group_by(
      .data[["scope"]],
      .data[["reduced_variant"]],
      .data[["component"]]
    ) |>
    dplyr::summarise(
      lwr_95 = stats::quantile(
        .data[["share_percent"]],
        probs = 0.025,
        names = FALSE
      ),
      upr_95 = stats::quantile(
        .data[["share_percent"]],
        probs = 0.975,
        names = FALSE
      ),
      n_repeats = dplyr::n(),
      mean_share_percent = base::mean(.data[["share_percent"]]),
      .groups = "drop"
    )

  res <-
    base::list(
      data_repeat_shares = data_repeat_shares,
      data_share_summary = data_share_summary
    )

  return(res)
}

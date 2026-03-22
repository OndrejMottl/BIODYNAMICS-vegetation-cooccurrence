#' @title Check sjSDM Model Convergence
#' @description
#' Assesses whether a fitted sjSDM model has converged by analysing
#' the training loss history stored in the model object.
#' @param mod_jsdm
#' A fitted sjSDM model object. Must be of class 'sjSDM'.
#' @return
#' A list with four elements:
#' - `linear_trend_slope`: Absolute slope of a linear trend fitted
#'   to the final 10% of loss values. Values < 0.01 indicate
#'   convergence.
#' - `median_diff`: Absolute difference between the median of the
#'   first and last 25% of the tail loss. Values < 1 indicate
#'   convergence.
#' - `convergence_plot`: A ggplot2 object showing the full loss
#'   history with a 20-epoch rolling median smoother.
#' - `note`: A character string summarising the thresholds.
#' @details
#' The function uses the `history` component of the fitted sjSDM
#' model, which stores the per-epoch negative log-likelihood values
#' produced during gradient descent.
#'
#' Two diagnostic metrics are computed on the tail (final 10% of
#' epochs):
#'
#' 1. **Linear trend slope** — A near-zero slope means the loss is
#'    no longer decreasing, indicating convergence. The recommended
#'    threshold is < 0.01.
#' 2. **Median difference** — A robust comparison of the first
#'    versus last quarter of the tail using medians (insensitive to
#'    spikes). The recommended threshold is < 1.
#' @seealso [fit_jsdm_model()], [evaluate_jsdm()]
#' @export
check_convergence_jsdm <- function(mod_jsdm = NULL) {
  assertthat::assert_that(
    inherits(mod_jsdm, "sjSDM"),
    msg = "mod_jsdm must be of class 'sjSDM'"
  )

  loss_history <- mod_jsdm$history

  assertthat::assert_that(
    is.numeric(loss_history),
    length(loss_history) >= 10L,
    msg = paste(
      "mod_jsdm$history must be a numeric vector of length >= 10.",
      "Did you fit the model with enough iterations?"
    )
  )

  n <- length(loss_history)

  tail_loss <- loss_history[round(n * 0.9):n]

  # 1. Linear trend slope on the tail (should be ≈ 0 if converged)
  linear_trend_slope <-
    lm(tail_loss ~ seq_along(tail_loss))$coefficients[2] |>
    abs() |>
    as.numeric() |>
    round(2)

  # 2. Compare median of first vs last quarter of the tail
  # (robust to spikes, unlike range)
  q <- length(tail_loss)

  median_diff <-
    (
      median(tail_loss[1:round(q * 0.25)]) -
        median(tail_loss[round(q * 0.75):q])
    ) |>
    abs() |>
    as.numeric() |>
    round(2)

  # 3. Rolling smoother to visualise the trend without noise
  loss_smooth <-
    stats::filter(loss_history, rep(1 / 20, 20), sides = 2)

  p_convergence <-
    dplyr::tibble(
      epoch = seq_along(loss_history),
      loss = loss_history,
      loss_smooth = as.numeric(loss_smooth)
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(x = epoch)
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = loss),
      color = "grey80",
      linewidth = 0.5
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = loss_smooth),
      color = "red",
      linewidth = 1
    ) +
    ggplot2::labs(
      x = "Epoch",
      y = "Loss",
      title = "Model Convergence: Loss History"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5)
    )

  return(
    list(
      linear_trend_slope = linear_trend_slope,
      median_diff = median_diff,
      convergence_plot = p_convergence,
      note = paste(
        "Linear trend slope on tail should be < 0.01.",
        "Median difference in tail should be < 1."
      )
    )
  )
}

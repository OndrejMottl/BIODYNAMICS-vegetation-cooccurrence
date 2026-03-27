#' @title Check sjSDM Model Convergence
#' @description
#' Assesses whether a fitted sjSDM model has converged by analysing
#' the training loss history stored in the model object.
#' @param mod_jsdm
#' A fitted sjSDM model object. Must be of class 'sjSDM'.
#' @return
#' A list with six elements:
#' - `linear_trend_slope`: Absolute slope of a linear trend fitted
#'   to the final 10% of loss values. Values < 0.01 indicate
#'   convergence.
#' - `median_diff`: Absolute difference between the median of the
#'   first and last 25% of the tail loss. Values < 1 indicate
#'   convergence.
#' - `convergence_plot`: A ggplot2 object showing the full loss
#'   history with a 20-epoch rolling median smoother. A dashed
#'   orange vertical line marks the last epoch run when early
#'   stopping was triggered.
#' - `note`: A character string summarising the thresholds.
#' - `epochs_run`: Integer. The number of epochs actually run
#'   before early stopping halted training (or the full budget
#'   when early stopping was not triggered).
#' - `early_stopping_triggered`: Logical. `TRUE` when the model
#'   stopped before exhausting its epoch budget (i.e. trailing
#'   zeros were detected in `mod_jsdm$history`).
#' @details
#' The function uses the `history` component of the fitted sjSDM
#' model, which stores the per-epoch negative log-likelihood values
#' produced during gradient descent.
#'
#' sjSDM pre-allocates `history` to the full epoch budget. When
#' early stopping fires, the remaining trailing entries are zero.
#' This function detects those trailing zeros, truncates the vector
#' to only the epochs that were actually run, and sets
#' `early_stopping_triggered = TRUE`.
#'
#' Two diagnostic metrics are computed on the tail (final 10% of
#' epochs actually run):
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
    msg = paste(
      "mod_jsdm$history must be a numeric vector of length >= 10.",
      "Did you fit the model with enough iterations?"
    )
  )

  # Strip trailing zeros left by early stopping.
  # sjSDM pre-allocates history to the full epoch budget; epochs not
  # reached remain 0. Metrics must be computed on real epochs only.
  n_budget <- base::length(loss_history)
  vec_nonzero_idx <- base::which(loss_history != 0)
  last_epoch <-
    if (base::length(vec_nonzero_idx) == 0L) {
      0L
    } else {
      base::max(vec_nonzero_idx)
    }
  early_stopping_triggered <- last_epoch < n_budget
  loss_history <- loss_history[base::seq_len(last_epoch)]

  assertthat::assert_that(
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
    stats::coef(
      stats::lm(tail_loss ~ seq_along(tail_loss))
    )[2] |>
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

  # Mark the early-stopping point with a dashed orange line
  if (early_stopping_triggered) {
    p_convergence <-
      p_convergence +
      ggplot2::geom_vline(
        xintercept = last_epoch,
        linetype = "dashed",
        color = "orange"
      )
  }

  return(
    list(
      linear_trend_slope = linear_trend_slope,
      median_diff = median_diff,
      convergence_plot = p_convergence,
      note = paste(
        "Linear trend slope on tail should be < 0.01.",
        "Median difference in tail should be < 1."
      ),
      epochs_run = base::as.integer(last_epoch),
      early_stopping_triggered = early_stopping_triggered
    )
  )
}

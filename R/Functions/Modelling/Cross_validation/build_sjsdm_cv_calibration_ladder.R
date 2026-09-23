#' @title Build the sjSDM CV Calibration Budget Ladder
#' @description
#' Constructs the fixed iteration ladder at the configured screening sampling
#' followed by the maximum-iteration sampling ladder used only when iteration
#' calibration fails.
#' @param iteration_sampling
#' Positive integer sampling budget used for the iteration-screening rungs.
#' @return
#' Tibble with deterministic budget order, phase, iterations, and sampling.
#' @examples
#' build_sjsdm_cv_calibration_ladder()
#' @export
build_sjsdm_cv_calibration_ladder <- function(
    iteration_sampling = 100L) {
  assertthat::assert_that(
    base::is.numeric(iteration_sampling),
    base::length(iteration_sampling) == 1L,
    base::is.finite(iteration_sampling),
    iteration_sampling > 0L,
    iteration_sampling == base::as.integer(iteration_sampling),
    msg = "iteration_sampling must be one positive integer."
  )

  vec_iterations <-
    base::as.integer(500L * 2L^(0:7))
  vec_sampling_escalation <-
    base::c(400L, 800L, 1600L, 3200L, 6400L, 8000L)

  res <-
    dplyr::bind_rows(
      tibble::tibble(
        calibration_phase = "iteration",
        n_iter = vec_iterations,
        n_sampling = base::as.integer(iteration_sampling)
      ),
      tibble::tibble(
        calibration_phase = "sampling",
        n_iter = 64000L,
        n_sampling = vec_sampling_escalation
      )
    ) |>
    dplyr::mutate(
      budget_order = dplyr::row_number(),
      .before = 1L
    )

  return(res)
}

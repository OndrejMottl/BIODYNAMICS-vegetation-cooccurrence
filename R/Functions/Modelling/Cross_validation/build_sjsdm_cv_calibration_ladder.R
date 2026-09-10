#' @title Build the sjSDM CV Calibration Budget Ladder
#' @description
#' Constructs the fixed iteration ladder at sampling 200 followed by the
#' maximum-iteration sampling ladder used only when iteration calibration fails.
#' @return
#' Tibble with deterministic budget order, phase, iterations, and sampling.
#' @examples
#' build_sjsdm_cv_calibration_ladder()
#' @export
build_sjsdm_cv_calibration_ladder <- function() {
  vec_iterations <-
    base::as.integer(500L * 2L^(0:7))
  vec_sampling_escalation <-
    base::c(400L, 800L, 1600L, 3200L, 6400L, 8000L)

  res <-
    dplyr::bind_rows(
      tibble::tibble(
        calibration_phase = "iteration",
        n_iter = vec_iterations,
        n_sampling = 200L
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

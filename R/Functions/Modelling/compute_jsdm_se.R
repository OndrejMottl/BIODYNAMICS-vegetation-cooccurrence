#' @title Compute Standard Errors for a Fitted sjSDM Model
#' @description
#' Post-hoc calculation of standard errors for a fitted sjSDM
#' model using `sjSDM::getSe()`. This is intentionally separated
#' from `fit_jsdm_model()` so that the GPU-based model fitting
#' step and the CPU-based SE computation step can be run
#' independently, allowing the SE step to exploit all available
#' CPU cores without being constrained by the GPU device setting.
#' @param mod_jsdm
#' An object of class `sjSDM` returned by `fit_jsdm_model()` or
#' `sjSDM::sjSDM()`. Must not be `NULL`.
#' @param parallel
#' Number of CPU cores to use for the data loader during SE
#' computation. Passed to the `parallel` argument of
#' `sjSDM::getSe()`. Default is `0L` (no parallelisation).
#' Use `config.model_fitting$n_cores` from the project
#' configuration to exploit all available cores.
#' @param step_size
#' Batch size for stochastic gradient descent used during SE
#' computation. Passed to `sjSDM::getSe()`. Default is `NULL`,
#' which lets sjSDM choose automatically.
#' @return
#' The input `mod_jsdm` object with its `$se` field populated
#' with the computed standard errors.
#' @details
#' `sjSDM::getSe()` uses CPU for SE computation regardless of the
#' device used for model fitting. Separating SE computation into
#' its own pipeline target therefore allows the caller to pass
#' the full number of available CPU cores via `parallel` without
#' conflict with the GPU device setting used during fitting.
#'
#' If SE computation fails, the function raises an error with
#' an informative message.
#' @seealso
#' `sjSDM::getSe`, `fit_jsdm_model`
#' @export
compute_jsdm_se <- function(
    mod_jsdm = NULL,
    parallel = 0L,
    step_size = NULL) {
  assertthat::assert_that(
    inherits(mod_jsdm, "sjSDM"),
    msg = paste0(
      "`mod_jsdm` must be an object of class 'sjSDM'.",
      " Use `fit_jsdm_model()` to produce one."
    )
  )

  assertthat::assert_that(
    is.numeric(parallel),
    length(parallel) == 1L,
    parallel >= 0L,
    msg = paste0(
      "`parallel` must be a single non-negative numeric value"
    )
  )

  assertthat::assert_that(
    is.null(step_size) ||
      (is.numeric(step_size) && length(step_size) == 1L &&
        step_size > 0L),
    msg = paste0(
      "`step_size` must be NULL or a single positive numeric value"
    )
  )

  mod_with_se <-
    sjSDM::getSe(
      object = mod_jsdm,
      step_size = step_size,
      parallel = as.integer(parallel)
    )

  return(mod_with_se)
}

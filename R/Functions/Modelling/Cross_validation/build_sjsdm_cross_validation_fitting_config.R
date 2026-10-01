#' @title Build an sjSDM Cross-Validation Fitting Configuration
#' @description
#' Combines structural model settings with an independent, validated CV fit
#' budget while excluding final-only ANOVA settings.
#' @param config_model_fitting
#' Full-data model-fitting configuration.
#' @param config_fit_budget
#' CV budget containing `n_iter_initial`, `n_iter_max`, `n_sampling`,
#' `n_step_size`, and `n_early_stopping`. When `calibration_status` is
#' supplied for a production profile, it must equal `"calibrated"`.
#' @return
#' A fitting-compatible CV configuration. `n_iter` begins at
#' `n_iter_initial`; both iteration bounds are retained for escalation.
#' @examples
#' \dontrun{
#' build_sjsdm_cross_validation_fitting_config(
#'   config_model_fitting = config_model_fitting,
#'   config_fit_budget = config_cross_validation$fit_budget
#' )
#' }
#' @export
build_sjsdm_cross_validation_fitting_config <- function(
    config_model_fitting = NULL,
    config_fit_budget = NULL) {
  vec_budget_names <-
    base::c(
      "n_iter_initial",
      "n_iter_max",
      "n_sampling",
      "n_step_size",
      "n_early_stopping"
    )

  assertthat::assert_that(
    base::is.list(config_model_fitting),
    base::is.list(config_fit_budget),
    base::all(vec_budget_names %in% base::names(config_fit_budget)),
    msg = "CV fit configuration and budget must be complete lists."
  )

  calibration_status <-
    config_fit_budget[["calibration_status"]]
  if (
    !base::is.null(calibration_status)
  ) {
    assertthat::assert_that(
      base::identical(calibration_status, "calibrated"),
      msg = paste(
        "Production CV fitting is blocked because its fit budget is not",
        "calibrated. First run stage 01 preparation:",
        "R/02_Main_analyses/01_Preparation/01_run_preparation.R. Then run",
        "R/02_Main_analyses/02_Model_calibration/",
        "01_run_model_calibration.R to regenerate config.yml, then rerun",
        "R/02_Main_analyses/03_Model_fitting/01_run_model_fitting.R.",
        "Cached preprocessing will be reused; final-model",
        "budgets are not used as CV fallbacks."
      )
    )
  }

  for (
    param_id in base::c("n_iter_initial", "n_iter_max", "n_sampling")
  ) {
    value <-
      config_fit_budget[[param_id]]

    assertthat::assert_that(
      base::is.numeric(value),
      base::length(value) == 1L,
      base::is.finite(value),
      value > 0L,
      value == base::as.integer(value),
      msg = stringr::str_glue(
        "CV {param_id} must be one positive finite integer."
      )
    )
  }

  assertthat::assert_that(
    config_fit_budget[["n_iter_max"]] >=
      config_fit_budget[["n_iter_initial"]],
    msg = "CV n_iter_max must be at least n_iter_initial."
  )

  for (
    param_id in base::c("n_step_size", "n_early_stopping")
  ) {
    value <-
      config_fit_budget[[param_id]]

    if (
      !base::is.null(value)
    ) {
      assertthat::assert_that(
        base::is.numeric(value),
        base::length(value) == 1L,
        base::is.finite(value),
        value == base::as.integer(value),
        value >= 0L,
        msg = stringr::str_glue(
          "CV {param_id} must be NULL or one non-negative integer."
        )
      )
    }
  }

  config_cv_fitting <-
    config_model_fitting[base::setdiff(
      base::names(config_model_fitting),
      base::c(
        "n_iter",
        "n_sampling",
        "n_step_size",
        "n_early_stopping",
        "n_samples_anova"
      )
    )]

  config_cv_fitting[["n_iter"]] <-
    base::as.integer(config_fit_budget[["n_iter_initial"]])
  config_cv_fitting[["n_iter_initial"]] <-
    base::as.integer(config_fit_budget[["n_iter_initial"]])
  config_cv_fitting[["n_iter_max"]] <-
    base::as.integer(config_fit_budget[["n_iter_max"]])
  config_cv_fitting[["n_sampling"]] <-
    base::as.integer(config_fit_budget[["n_sampling"]])
  config_cv_fitting["n_step_size"] <-
    base::list(config_fit_budget[["n_step_size"]])
  config_cv_fitting["n_early_stopping"] <-
    base::list(config_fit_budget[["n_early_stopping"]])

  return(config_cv_fitting)
}

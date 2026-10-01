#' @title Fit an sjSDM Cross-Validation Candidate to Convergence
#' @description
#' Fits one candidate-fold from its initial CV iteration budget and retries a
#' successful non-converged fit with doubled iterations up to the exact maximum.
#' @param data_train_input,candidate,sel_abiotic_formula
#' Candidate fitting inputs passed to
#' [fit_sjsdm_regularization_candidate()].
#' @param config_sjsdm_cv_fitting
#' Validated CV fitting configuration containing initial and maximum budgets.
#' @param seed
#' Deterministic seed reused unchanged for every attempt.
#' @param repeat_id,fold_id
#' Integer CV identifiers persisted in attempt provenance.
#' @param device,biotic
#' Fitting device and optional biotic structure passed to the candidate fitter.
#' @param fit_function,convergence_function
#' Injectable fitting and convergence functions.
#' @return
#' An `sjsdm_cv_fit_result` list containing the last model, final status,
#' convergence fields, actual budget, and an attempt-level table.
#' @examples
#' \dontrun{
#' fit_sjsdm_cross_validation_candidate(
#'   data_train_input = data_train_input,
#'   candidate = data_candidate,
#'   sel_abiotic_formula = formula_jsdm_environment,
#'   config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
#'   repeat_id = 1L,
#'   fold_id = 1L
#' )
#' }
#' @export
fit_sjsdm_cross_validation_candidate <- function(
    data_train_input = NULL,
    candidate = NULL,
    sel_abiotic_formula = NULL,
    config_sjsdm_cv_fitting = NULL,
    seed = 900723L,
    repeat_id = NA_integer_,
    fold_id = NA_integer_,
    device = "cpu",
    biotic = NULL,
    fit_function = fit_sjsdm_regularization_candidate,
    convergence_function = diagnose_jsdm_convergence) {
  vec_budget_names <-
    base::c(
      "n_iter_initial",
      "n_iter_max",
      "n_sampling",
      "n_step_size",
      "n_early_stopping"
    )

  assertthat::assert_that(
    base::is.list(config_sjsdm_cv_fitting),
    base::all(
      vec_budget_names %in% base::names(config_sjsdm_cv_fitting)
    ),
    base::is.function(fit_function),
    base::is.function(convergence_function),
    msg = "CV fitting inputs are incomplete."
  )

  n_iter_initial <-
    config_sjsdm_cv_fitting[["n_iter_initial"]]
  n_iter_max <-
    config_sjsdm_cv_fitting[["n_iter_max"]]

  assertthat::assert_that(
    base::is.numeric(n_iter_initial),
    base::length(n_iter_initial) == 1L,
    base::is.finite(n_iter_initial),
    n_iter_initial > 0L,
    n_iter_initial == base::as.integer(n_iter_initial),
    base::is.numeric(n_iter_max),
    base::length(n_iter_max) == 1L,
    base::is.finite(n_iter_max),
    n_iter_max >= n_iter_initial,
    n_iter_max == base::as.integer(n_iter_max),
    msg = "CV iteration budgets must be positive ordered integers."
  )

  n_iter_budget <-
    base::as.integer(n_iter_initial)
  attempt <-
    0L
  list_attempts <-
    base::list()
  mod_fit <-
    NULL

  repeat {
    attempt <-
      attempt + 1L
    config_attempt <-
      config_sjsdm_cv_fitting
    config_attempt[["n_iter"]] <-
      n_iter_budget
    fit_started <-
      base::proc.time()[["elapsed"]]
    mod_attempt <-
      base::tryCatch(
        fit_function(
          data_train_input = data_train_input,
          candidate = candidate,
          sel_abiotic_formula = sel_abiotic_formula,
          config_model_fitting = config_attempt,
          seed = base::as.integer(seed),
          device = device,
          biotic = biotic
        ),
        error = base::identity
      )
    runtime_seconds <-
      base::proc.time()[["elapsed"]] - fit_started

    if (
      base::inherits(mod_attempt, "error")
    ) {
      list_attempts[[attempt]] <-
        tibble::tibble(
          candidate_id = candidate[["candidate_id"]][[1L]],
          repeat_id = base::as.integer(repeat_id),
          fold_id = base::as.integer(fold_id),
          attempt = attempt,
          n_iter_budget = n_iter_budget,
          n_sampling = base::as.integer(
            config_attempt[["n_sampling"]]
          ),
          epochs_run = NA_integer_,
          linear_trend_slope = NA_real_,
          median_diff = NA_real_,
          converged = FALSE,
          early_stopping_triggered = NA,
          runtime_seconds = runtime_seconds,
          fit_seed = base::as.integer(seed),
          fit_status = "fit_error",
          error_message = base::conditionMessage(mod_attempt)
        )

      return(
        structure(
          base::list(
            mod_fit = NULL,
            data_attempts = purrr::list_rbind(list_attempts),
            fit_status = "fit_error",
            error_message = base::conditionMessage(mod_attempt),
            converged = FALSE,
            actual_n_iter = n_iter_budget,
            actual_n_sampling = base::as.integer(
              config_attempt[["n_sampling"]]
            )
          ),
          class = base::c("sjsdm_cv_fit_result", "list")
        )
      )
    }

    list_convergence <-
      base::tryCatch(
        convergence_function(mod_attempt),
        error = base::identity
      )

    if (
      base::inherits(list_convergence, "error")
    ) {
      fit_status <-
        "convergence_error"
      error_message <-
        base::conditionMessage(list_convergence)
      linear_trend_slope <-
        NA_real_
      median_diff <-
        NA_real_
      epochs_run <-
        NA_integer_
      early_stopping_triggered <-
        NA
      converged <-
        FALSE
    } else {
      fit_status <-
        "ok"
      error_message <-
        NA_character_
      linear_trend_slope <-
        base::as.numeric(
          list_convergence[["linear_trend_slope"]]
        )
      median_diff <-
        base::as.numeric(list_convergence[["median_diff"]])
      epochs_run <-
        base::as.integer(list_convergence[["epochs_run"]])
      early_stopping_triggered <-
        base::isTRUE(
          list_convergence[["early_stopping_triggered"]]
        )
      converged <-
        base::is.finite(linear_trend_slope) &&
        base::is.finite(median_diff) &&
        linear_trend_slope < 0.01 &&
        median_diff < 1
    }

    list_attempts[[attempt]] <-
      tibble::tibble(
        candidate_id = candidate[["candidate_id"]][[1L]],
        repeat_id = base::as.integer(repeat_id),
        fold_id = base::as.integer(fold_id),
        attempt = attempt,
        n_iter_budget = n_iter_budget,
        n_sampling = base::as.integer(
          config_attempt[["n_sampling"]]
        ),
        epochs_run = epochs_run,
        linear_trend_slope = linear_trend_slope,
        median_diff = median_diff,
        converged = converged,
        early_stopping_triggered = early_stopping_triggered,
        runtime_seconds = runtime_seconds,
        fit_seed = base::as.integer(seed),
        fit_status = fit_status,
        error_message = error_message
      )

    if (
      fit_status == "convergence_error" || converged
    ) {
      final_status <-
        fit_status
      break
    }

    if (
      n_iter_budget >= n_iter_max
    ) {
      final_status <-
        "non_converged"
      error_message <-
        "CV fit did not converge at n_iter_max."
      break
    }

    mod_attempt <-
      NULL
    base::invisible(base::gc())
    n_iter_budget <-
      base::min(
        base::as.integer(n_iter_budget * 2L),
        base::as.integer(n_iter_max)
      )
  }

  mod_fit <-
    mod_attempt

  return(
    structure(
      base::list(
        mod_fit = mod_fit,
        data_attempts = purrr::list_rbind(list_attempts),
        fit_status = final_status,
        error_message = error_message,
        converged = converged,
        actual_n_iter = n_iter_budget,
        actual_n_sampling = base::as.integer(
          config_sjsdm_cv_fitting[["n_sampling"]]
        ),
        linear_trend_slope = linear_trend_slope,
        median_diff = median_diff,
        epochs_run = epochs_run,
        early_stopping_triggered = early_stopping_triggered
      ),
      class = base::c("sjsdm_cv_fit_result", "list")
    )
  )
}

#' @title Fit One Predictive Decomposition Variant
#' @description
#' Internal helper that fits, diagnoses, predicts, and evaluates one model
#' variant for one diagnostic fold.
#' @param data_fold_input
#' Prepared train and test inputs for one fold.
#' @param route_id
#' Diagnostic route identifier.
#' @param repeat_id
#' Repeated-fold identifier.
#' @param fold_id
#' Fold identifier.
#' @param variant_name
#' Model variant identifier.
#' @param list_variant
#' Variant-specific spatial and biotic settings.
#' @param age_formula_mode
#' Environmental age-formula mode.
#' @param config_model_fitting
#' Model-fitting configuration.
#' @param fit_config
#' Optional fitting overrides.
#' @param fit_fn
#' Injected model-fitting function.
#' @param predict_fn
#' Injected prediction function.
#' @param convergence_fn
#' Injected convergence diagnostic function.
#' @return
#' One-row variant metric and diagnostic tibble.
#' @keywords internal
.fit_decomposition_variant <- function(
    data_fold_input,
    route_id,
    repeat_id,
    fold_id,
    variant_name,
    list_variant,
    age_formula_mode,
    config_model_fitting,
    fit_config,
    fit_fn,
    predict_fn,
    convergence_fn) {
  vec_warnings <-
    base::character()

  data_train_input <-
    data_fold_input |>
    purrr::chuck("data_train_input")

  data_test_input <-
    data_fold_input |>
    purrr::chuck("data_test_input")

  data_diagnostics <-
    data_fold_input |>
    purrr::chuck("data_diagnostics")

  data_observed <-
    data_fold_input |>
    purrr::chuck("data_test_observed")

  data_train_variant <-
    data_train_input

  data_test_abiotic <-
    data_test_input |>
    purrr::chuck("data_abiotic_to_fit")

  if (
    variant_name == "no_abiotic"
  ) {
    data_train_abiotic <-
      data_train_input |>
      purrr::chuck("data_abiotic_to_fit")

    data_train_variant[["data_abiotic_to_fit"]] <-
      base::data.frame(
        abiotic_constant = base::rep(
          x = 1,
          times = base::nrow(data_train_abiotic)
        )
      )

    base::rownames(data_train_variant[["data_abiotic_to_fit"]]) <-
      base::rownames(data_train_abiotic)

    data_test_abiotic <-
      base::data.frame(
        abiotic_constant = base::rep(
          x = 1,
          times = base::nrow(data_test_abiotic)
        )
      )

    base::rownames(data_test_abiotic) <-
      data_test_input |>
      purrr::chuck("data_abiotic_to_fit") |>
      base::rownames()

    formula_abiotic <-
      stats::as.formula("~ 0 + abiotic_constant")
  } else {
    formula_abiotic <-
      build_decomposition_environment_formula(
        data = data_train_variant |>
          purrr::chuck("data_abiotic_to_fit"),
        age_formula_mode = age_formula_mode
      )
  }

  list_fit_arguments <-
    base::list(
      data_to_fit = data_train_variant,
      sel_abiotic_formula = formula_abiotic,
      sel_spatial_formula = stats::as.formula("~ 0 + ."),
      spatial_method = purrr::chuck(list_variant, "spatial_method"),
      error_family = purrr::chuck(
        config_model_fitting,
        "error_family"
      ),
      device = purrr::pluck(fit_config, "device", .default = NULL),
      parallel = purrr::pluck(fit_config, "parallel", .default = NULL),
      compute_se = FALSE,
      biotic = purrr::pluck(list_variant, "biotic", .default = NULL),
      iter = purrr::pluck(fit_config, "iter", .default = NULL),
      n_early_stopping = purrr::pluck(
        fit_config,
        "n_early_stopping",
        .default = NULL
      ),
      sampling = purrr::pluck(
        fit_config,
        "sampling",
        .default = NULL
      ),
      step_size = purrr::pluck(
        fit_config,
        "step_size",
        .default = NULL
      ),
      verbose = FALSE
    ) |>
    purrr::discard(.p = base::is.null)

  mod_fit <-
    tryCatch(
      expr = {
        base::withCallingHandlers(
          base::do.call(
            what = fit_fn,
            args = list_fit_arguments
          ),
          warning = function(warning_condition) {
            vec_warnings <<-
              base::c(
                vec_warnings,
                base::conditionMessage(warning_condition)
              )

            base::invokeRestart("muffleWarning")
          }
        )
      },
      error = function(error_condition) {
        error_condition
      }
    )

  warning_text <-
    if (
      base::length(vec_warnings) == 0L
    ) {
      NA_character_
    } else {
      stringr::str_c(base::unique(vec_warnings), collapse = " | ")
    }

  if (
    base::inherits(mod_fit, "error")
  ) {
    return(
      .build_empty_decomposition_variant(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        variant = variant_name,
        status = "error",
        error_message = base::conditionMessage(mod_fit),
        warning_text = warning_text,
        diagnostics = data_diagnostics
      )
    )
  }

  list_convergence <-
    tryCatch(
      expr = convergence_fn(mod_fit),
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(list_convergence, "error")
  ) {
    return(
      .build_empty_decomposition_variant(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        variant = variant_name,
        status = "convergence_error",
        error_message = base::conditionMessage(list_convergence),
        warning_text = warning_text,
        diagnostics = data_diagnostics
      )
    )
  }

  flag_converged <-
    purrr::chuck(list_convergence, "linear_trend_slope") < 0.01 &&
    purrr::chuck(list_convergence, "median_diff") < 1

  data_spatial_test <-
    if (
      purrr::chuck(list_variant, "spatial_method") == "none"
    ) {
      NULL
    } else {
      data_test_input |>
        purrr::chuck("data_spatial_to_fit")
    }

  data_predicted <-
    tryCatch(
      expr = {
        predict_fn(
          object = mod_fit,
          newdata = data_test_abiotic,
          SP = data_spatial_test,
          type = "raw"
        )
      },
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(data_predicted, "error")
  ) {
    return(
      .build_empty_decomposition_variant(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        variant = variant_name,
        status = "prediction_error",
        error_message = base::conditionMessage(data_predicted),
        warning_text = warning_text,
        diagnostics = data_diagnostics
      )
    )
  }

  data_metrics <-
    compute_decomposition_prediction_metrics(
      data_observed = data_observed,
      data_predicted = base::as.matrix(data_predicted)
    )

  status_value <-
    if (
      base::isTRUE(flag_converged)
    ) {
      "ok"
    } else {
      "not_converged"
    }

  res <-
    tibble::tibble(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      variant = variant_name,
      status = status_value,
      error_message = NA_character_,
      warning_text = warning_text,
      converged = flag_converged,
      linear_trend_slope = purrr::chuck(
        list_convergence,
        "linear_trend_slope"
      ),
      median_diff = purrr::chuck(list_convergence, "median_diff"),
      epochs_run = purrr::chuck(list_convergence, "epochs_run"),
      early_stopping_triggered = purrr::chuck(
        list_convergence,
        "early_stopping_triggered"
      )
    ) |>
    dplyr::bind_cols(data_metrics) |>
    dplyr::bind_cols(data_diagnostics)

  return(res)
}

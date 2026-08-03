#' @title Run Decomposition Route Cross-Validation
#' @description
#' Fits full and reduced models for one diagnostic route and returns
#' fold-level held-out metrics and convergence diagnostics.
#' @param route
#' One-row route data frame or named list.
#' @param inputs
#' List returned by `load_decomposition_diagnostic_inputs()`.
#' @param cv_indices
#' Repeated fold test-index list from `make_repeated_cv_indices()`.
#' @param fit_config
#' Optional list of fitting overrides.
#' @param fit_fn
#' Model fitting function. Defaults to `fit_jsdm_model()`.
#' @param predict_fn
#' Prediction function. Defaults to `stats::predict()`.
#' @param convergence_fn
#' Convergence function. Defaults to `check_convergence_jsdm()`.
#' @param verbose
#' Logical. If `TRUE`, progress messages are printed.
#' @return
#' Tibble with one row per route, repeat, fold, and variant.
#' @export
run_decomposition_route_cv <- function(
    route = NULL,
    inputs = NULL,
    cv_indices = NULL,
    fit_config = base::list(),
    fit_fn = fit_jsdm_model,
    predict_fn = stats::predict,
    convergence_fn = check_convergence_jsdm,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(route) || base::is.list(route),
    msg = "`route` must be a one-row data frame or named list."
  )

  assertthat::assert_that(
    base::is.list(inputs),
    msg = "`inputs` must be a list."
  )

  assertthat::assert_that(
    base::is.list(cv_indices),
    base::length(cv_indices) > 0L,
    msg = "`cv_indices` must be a non-empty list."
  )

  assertthat::assert_that(
    base::is.list(fit_config),
    msg = "`fit_config` must be a list."
  )

  route_id <-
    route[["route_id"]][[1L]]

  use_age <-
    route[["use_age"]][[1L]]

  age_formula_mode <-
    if (
      "age_formula_mode" %in% base::names(route)
    ) {
      route[["age_formula_mode"]][[1L]]
    } else if (
      base::isTRUE(use_age)
    ) {
      "interaction"
    } else {
      "none"
    }

  config_model_fitting <-
    inputs |>
    purrr::chuck("config_model_fitting")

  data_route_sample_ids <-
    get_decomposition_route_sample_ids(
      route = route,
      inputs = inputs
    )

  vec_sample_ids <-
    data_route_sample_ids |>
    dplyr::pull(.data$.row_name)

  list_variants <-
    base::list(
      full = base::list(
        component = "full",
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct()
      ),
      no_abiotic = base::list(
        component = "Abiotic",
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct()
      ),
      no_spatial = base::list(
        component = "Spatial",
        spatial_method = "none",
        biotic = sjSDM::bioticStruct()
      ),
      no_associations = base::list(
        component = "Associations",
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct(diag = TRUE)
      )
    )

  make_empty_variant <- function(
      repeat_id,
      fold_id,
      variant,
      status,
      error_message,
      warning_text = NA_character_,
      diagnostics = NULL) {
    data_diagnostics <-
      if (
        base::is.null(diagnostics)
      ) {
        tibble::tibble(
          n_train_samples = NA_integer_,
          n_test_samples = NA_integer_,
          n_taxa_raw = NA_integer_,
          n_taxa_retained = NA_integer_,
          n_taxa_dropped = NA_integer_
        )
      } else {
        diagnostics
      }

    tibble::tibble(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      variant = variant,
      status = status,
      error_message = error_message,
      warning_text = warning_text,
      converged = FALSE,
      linear_trend_slope = NA_real_,
      median_diff = NA_real_,
      epochs_run = NA_integer_,
      early_stopping_triggered = NA,
      loss = NA_real_,
      brier = NA_real_,
      auc = NA_real_,
      auc_macro = NA_real_
    ) |>
      dplyr::bind_cols(data_diagnostics)
  }

  fit_one_variant <- function(
      data_fold_input,
      repeat_id,
      fold_id,
      variant_name,
      list_variant) {
    vec_warnings <- base::character()

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
      data_train_variant[["data_abiotic_to_fit"]] <-
        base::data.frame(
          abiotic_constant = base::rep(
            x = 1,
            times = base::nrow(
              data_train_input[["data_abiotic_to_fit"]]
            )
          )
        )

      base::rownames(data_train_variant[["data_abiotic_to_fit"]]) <-
        base::rownames(data_train_input[["data_abiotic_to_fit"]])

      data_test_abiotic <-
        base::data.frame(
          abiotic_constant = base::rep(
            x = 1,
            times = base::nrow(data_test_abiotic)
          )
        )

      base::rownames(data_test_abiotic) <-
        base::rownames(data_test_input[["data_abiotic_to_fit"]])

      formula_abiotic <-
        stats::as.formula("~ 0 + abiotic_constant")
    } else {
      formula_abiotic <-
        make_decomposition_env_formula(
          data = data_train_variant[["data_abiotic_to_fit"]],
          age_formula_mode = age_formula_mode
        )
    }

    list_fit_arguments <-
      base::list(
        data_to_fit = data_train_variant,
        sel_abiotic_formula = formula_abiotic,
        sel_spatial_formula = stats::as.formula("~ 0 + ."),
        spatial_method = list_variant[["spatial_method"]],
        error_family = config_model_fitting[["error_family"]],
        device = fit_config[["device"]],
        parallel = fit_config[["parallel"]],
        compute_se = FALSE,
        biotic = list_variant[["biotic"]],
        iter = fit_config[["iter"]],
        n_early_stopping = fit_config[["n_early_stopping"]],
        sampling = fit_config[["sampling"]],
        step_size = fit_config[["step_size"]],
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
              vec_warnings <<- base::c(
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
        make_empty_variant(
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
        make_empty_variant(
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
      list_convergence[["linear_trend_slope"]] < 0.01 &&
      list_convergence[["median_diff"]] < 1

    data_spatial_test <-
      if (
        list_variant[["spatial_method"]] == "none"
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
        make_empty_variant(
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

    tibble::tibble(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      variant = variant_name,
      status = status_value,
      error_message = NA_character_,
      warning_text = warning_text,
      converged = flag_converged,
      linear_trend_slope = list_convergence[["linear_trend_slope"]],
      median_diff = list_convergence[["median_diff"]],
      epochs_run = list_convergence[["epochs_run"]],
      early_stopping_triggered = list_convergence[[
        "early_stopping_triggered"
      ]]
    ) |>
      dplyr::bind_cols(data_metrics) |>
      dplyr::bind_cols(data_diagnostics)
  }

  res <-
    base::seq_along(cv_indices) |>
    purrr::map(
      .f = ~ {
        repeat_id <-
          .x

        cv_indices[[repeat_id]] |>
          purrr::imap(
            .f = ~ {
              vec_test_indices <-
                .x

              fold_id <-
                .y

              vec_test_ids <-
                vec_sample_ids[vec_test_indices]

              vec_train_ids <-
                vec_sample_ids[-vec_test_indices]

              if (
                base::isTRUE(verbose)
              ) {
                cli::cli_inform(
                  stringr::str_glue(
                    "Running {route_id}, repeat {repeat_id}, {fold_id}."
                  )
                )
              }

              data_fold_input <-
                tryCatch(
                  expr = prepare_decomposition_fold_input(
                    route = route,
                    inputs = inputs,
                    train_ids = vec_train_ids,
                    test_ids = vec_test_ids
                  ),
                  error = function(error_condition) {
                    error_condition
                  }
                )

              if (
                base::inherits(data_fold_input, "error")
              ) {
                return(
                  base::names(list_variants) |>
                    purrr::map(
                      .f = ~ make_empty_variant(
                        repeat_id = repeat_id,
                        fold_id = fold_id,
                        variant = .x,
                        status = "fold_prepare_error",
                        error_message = base::conditionMessage(
                          data_fold_input
                        )
                      )
                    ) |>
                    purrr::list_rbind()
                )
              }

              list_variants |>
                purrr::imap(
                  .f = ~ fit_one_variant(
                    data_fold_input = data_fold_input,
                    repeat_id = repeat_id,
                    fold_id = fold_id,
                    variant_name = .y,
                    list_variant = .x
                  )
                ) |>
                purrr::list_rbind()
            }
          ) |>
          purrr::list_rbind()
      }
    ) |>
    purrr::list_rbind()

  return(res)
}

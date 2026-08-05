#' @title Run Predictive Decomposition Diagnostic Folds
#' @description
#' Fits full and reduced models for one diagnostic route and returns
#' fold-level held-out metrics and convergence diagnostics.
#' @param route
#' One-row route data frame or named list.
#' @param inputs
#' List returned by `load_decomposition_diagnostic_inputs()`.
#' @param cv_indices
#' Repeated fold test-index list from
#' `build_repeated_diagnostic_fold_indices()`.
#' @param fit_config
#' Optional list of fitting overrides.
#' @param fit_fn
#' Model fitting function. Defaults to `fit_jsdm_model()`.
#' @param predict_fn
#' Prediction function. Defaults to `stats::predict()`.
#' @param convergence_fn
#' Convergence function. Defaults to `diagnose_jsdm_convergence()`.
#' @param verbose
#' Logical. If `TRUE`, progress messages are printed.
#' @return
#' Tibble with one row per route, repeat, fold, and variant.
#' @export
run_decomposition_diagnostic_folds <- function(
    route = NULL,
    inputs = NULL,
    cv_indices = NULL,
    fit_config = base::list(),
    fit_fn = fit_jsdm_model,
    predict_fn = stats::predict,
    convergence_fn = diagnose_jsdm_convergence,
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
    select_decomposition_route_samples(
      route = route,
      inputs = inputs
    )

  vec_sample_ids <-
    dplyr::pull(data_route_sample_ids, ".row_name")

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
                      .f = ~ .build_empty_decomposition_variant(
                        route_id = route_id,
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
                  .f = ~ .fit_decomposition_variant(
                    data_fold_input = data_fold_input,
                    route_id = route_id,
                    repeat_id = repeat_id,
                    fold_id = fold_id,
                    variant_name = .y,
                    list_variant = .x,
                    age_formula_mode = age_formula_mode,
                    config_model_fitting = config_model_fitting,
                    fit_config = fit_config,
                    fit_fn = fit_fn,
                    predict_fn = predict_fn,
                    convergence_fn = convergence_fn
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

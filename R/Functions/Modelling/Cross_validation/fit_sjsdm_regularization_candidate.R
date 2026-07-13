#' @title Fit One sjSDM Regularization Candidate
#' @description
#' Fits one prepared training fold with regularization parameters from a
#' deterministic candidate table.
#' @param data_train_input
#' Fold-local training input returned by
#' [prepare_sjsdm_cross_validation_fold()].
#' @param candidate
#' One-row candidate table containing `candidate_id` and the six sjSDM
#' regularization parameters.
#' @param sel_abiotic_formula
#' Abiotic model formula passed to [fit_jsdm_model()].
#' @param config_model_fitting
#' Active model-fitting configuration list.
#' @param seed
#' Deterministic integer seed for the candidate fit.
#' @param device
#' Device passed to [fit_jsdm_model()]. Defaults to `"cpu"`.
#' @param fit_function
#' Injectable fit function. Defaults to [fit_jsdm_model()].
#' @return
#' Fitted model object returned by `fit_function`.
#' @details
#' The adapter keeps regularization forwarding in one tested place so tuning
#' and selected-candidate reruns use identical fitting arguments.
#' @export
fit_sjsdm_regularization_candidate <- function(
    data_train_input = NULL,
    candidate = NULL,
    sel_abiotic_formula = NULL,
    config_model_fitting = NULL,
    seed = 900723L,
    device = "cpu",
    fit_function = fit_jsdm_model) {
  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  assertthat::assert_that(
    base::is.data.frame(candidate),
    base::nrow(candidate) == 1L,
    base::all(
      base::c("candidate_id", vec_parameter_columns) %in%
        base::colnames(candidate)
    ),
    msg = "candidate must contain one complete regularization row."
  )

  assertthat::assert_that(
    base::is.list(config_model_fitting),
    base::is.function(fit_function),
    msg = "Model configuration must be a list and fit_function callable."
  )

  assertthat::assert_that(
    base::inherits(sel_abiotic_formula, "formula"),
    msg = "sel_abiotic_formula must be a formula."
  )

  assertthat::assert_that(
    base::is.numeric(seed),
    base::length(seed) == 1L,
    base::is.finite(seed),
    seed >= 0L,
    seed == base::as.integer(seed),
    msg = "seed must be a single non-negative integer."
  )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(candidate[vec_parameter_columns], base::is.numeric)
    ),
    base::all(
      base::is.finite(base::as.matrix(candidate[vec_parameter_columns]))
    ),
    msg = "candidate regularization parameters must be finite numbers."
  )

  spatial_method <-
    if (
      config_model_fitting[["use_spatial"]] |>
      base::isTRUE()
    ) {
      "linear"
    } else {
      "none"
    }

  res <-
    fit_function(
      data_to_fit = data_train_input,
      abiotic_method = "linear",
      sel_abiotic_formula = sel_abiotic_formula,
      spatial_method = spatial_method,
      sel_spatial_formula = stats::as.formula("~ 0 + ."),
      error_family = config_model_fitting[["error_family"]],
      device = device,
      parallel = config_model_fitting[["n_cores"]],
      sampling = config_model_fitting[["n_sampling"]],
      iter = config_model_fitting[["n_iter"]],
      step_size = config_model_fitting[["n_step_size"]],
      n_early_stopping = config_model_fitting[["n_early_stopping"]],
      seed = base::as.integer(seed),
      verbose = FALSE,
      compute_se = FALSE,
      alpha_cov = candidate[["alpha_cov"]][[1L]],
      alpha_coef = candidate[["alpha_coef"]][[1L]],
      alpha_spatial = candidate[["alpha_spatial"]][[1L]],
      lambda_cov = candidate[["lambda_cov"]][[1L]],
      lambda_coef = candidate[["lambda_coef"]][[1L]],
      lambda_spatial = candidate[["lambda_spatial"]][[1L]]
    )

  return(res)
}

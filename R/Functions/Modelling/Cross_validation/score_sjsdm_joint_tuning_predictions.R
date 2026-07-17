#' @title Score Joint sjSDM Tuning Predictions
#' @description
#' Calculates the held-out joint sjSDM negative log likelihood and probability
#' diagnostics used by regularization tuning.
#' @param object
#' Fitted `sjSDM` object containing the model likelihood callback, formulas,
#' and fit settings.
#' @param data_test_input
#' Fold-local test input containing `data_abiotic_to_fit` and, for spatial
#' models, `data_spatial_to_fit`.
#' @param data_observed,data_predicted
#' Aligned binary observations and marginal predicted probabilities.
#' @param epsilon
#' Probability clipping tolerance passed to
#' [score_sjsdm_tuning_predictions()].
#' @param n_likelihood_draws
#' Positive integer number of stochastic likelihood evaluations to average.
#' Defaults to `20L`, matching `sjSDM::sjSDM_cv()`.
#' @param score_seed
#' Non-negative integer used for deterministic stochastic likelihood draws.
#' @return
#' One-row tibble with retained taxa, response-value count, total joint
#' negative log likelihood, joint loss per response, and macro AUC.
#' @details
#' Test design matrices are reconstructed from the fitted model formulas.
#' Likelihood sampling and batch size are read from the fitted model settings.
#' The caller's R and available PyTorch random-number states are restored.
#' @examples
#' \dontrun{
#' score_sjsdm_joint_tuning_predictions(
#'   object = mod_fit,
#'   data_test_input = list_test_input,
#'   data_observed = data_test_observed,
#'   data_predicted = data_test_predicted
#' )
#' }
#' @export
score_sjsdm_joint_tuning_predictions <- function(
    object = NULL,
    data_test_input = NULL,
    data_observed = NULL,
    data_predicted = NULL,
    epsilon = 1e-6,
    n_likelihood_draws = 20L,
    score_seed = 900723L) {
  assertthat::assert_that(
    base::inherits(object, "sjSDM"),
    msg = "`object` must inherit from `sjSDM`."
  )

  assertthat::assert_that(
    base::is.list(data_test_input),
    "data_abiotic_to_fit" %in% base::names(data_test_input),
    base::is.data.frame(data_test_input[["data_abiotic_to_fit"]]),
    msg = "`data_test_input` must contain abiotic test data."
  )

  flag_valid_draws <-
    base::is.numeric(n_likelihood_draws) &&
    base::length(n_likelihood_draws) == 1L &&
    base::is.finite(n_likelihood_draws) &&
    n_likelihood_draws >= 1L &&
    n_likelihood_draws == base::as.integer(n_likelihood_draws)

  assertthat::assert_that(
    flag_valid_draws,
    msg = "`n_likelihood_draws` must be a positive integer."
  )

  flag_valid_score_seed <-
    base::is.numeric(score_seed) &&
    base::length(score_seed) == 1L &&
    base::is.finite(score_seed) &&
    score_seed >= 0L &&
    score_seed <= .Machine[["integer.max"]] &&
    score_seed == base::as.integer(score_seed)

  assertthat::assert_that(
    flag_valid_score_seed,
    msg = "`score_seed` must be a single non-negative integer."
  )

  score_seed <-
    base::as.integer(score_seed)

  flag_had_r_seed <-
    base::exists(
      x = ".Random.seed",
      envir = base::globalenv(),
      inherits = FALSE
    )

  if (
    flag_had_r_seed
  ) {
    old_r_seed <-
      base::get(
        x = ".Random.seed",
        envir = base::globalenv(),
        inherits = FALSE
      )
  } else {
    old_r_seed <- NULL
  }

  base::on.exit(
    expr = {
      if (
        flag_had_r_seed
      ) {
        base::assign(
          x = ".Random.seed",
          value = old_r_seed,
          envir = base::globalenv()
        )
      } else if (
        base::exists(
          x = ".Random.seed",
          envir = base::globalenv(),
          inherits = FALSE
        )
      ) {
        base::rm(
          list = ".Random.seed",
          envir = base::globalenv()
        )
      }
    },
    add = TRUE
  )

  torch_module <-
    tryCatch(
      expr = reticulate::import(
        module = "torch",
        convert = FALSE,
        delay_load = FALSE
      ),
      error = function(error_condition) {
        NULL
      }
    )

  if (
    !base::is.null(torch_module)
  ) {
    old_torch_cpu_state <-
      torch_module$get_rng_state()

    flag_cuda_available <-
      torch_module$cuda$is_available() |>
      reticulate::py_to_r() |>
      base::isTRUE()

    if (
      flag_cuda_available
    ) {
      old_torch_cuda_states <-
        torch_module$cuda$get_rng_state_all()
    } else {
      old_torch_cuda_states <- NULL
    }

    base::on.exit(
      expr = {
        torch_module$set_rng_state(old_torch_cpu_state)

        if (
          flag_cuda_available
        ) {
          torch_module$cuda$set_rng_state_all(old_torch_cuda_states)
        }
      },
      add = TRUE
    )

    torch_module$manual_seed(score_seed)
  }

  base::set.seed(score_seed)

  data_probability_metrics <-
    score_sjsdm_tuning_predictions(
      data_observed = data_observed,
      data_predicted = data_predicted,
      epsilon = epsilon
    )

  formula_abiotic <-
    object[["formula"]]

  assertthat::assert_that(
    base::inherits(formula_abiotic, "formula"),
    msg = "The fitted model must contain an abiotic formula."
  )

  data_abiotic_matrix <-
    stats::model.matrix(
      object = formula_abiotic,
      data = data_test_input[["data_abiotic_to_fit"]]
    )

  flag_spatial <-
    base::inherits(object, "spatial")

  if (
    flag_spatial
  ) {
    assertthat::assert_that(
      "data_spatial_to_fit" %in% base::names(data_test_input),
      base::is.data.frame(data_test_input[["data_spatial_to_fit"]]),
      msg = "Spatial models require spatial test data."
    )

    formula_spatial <-
      object[["spatial"]][["formula"]]

    assertthat::assert_that(
      base::inherits(formula_spatial, "formula"),
      msg = "The fitted spatial model must contain a spatial formula."
    )

    data_spatial_matrix <-
      stats::model.matrix(
        object = formula_spatial,
        data = data_test_input[["data_spatial_to_fit"]]
      )
  } else {
    data_spatial_matrix <- NULL
  }

  list_settings <-
    object[["settings"]]

  step_size <-
    list_settings[["step_size"]]

  sampling <-
    list_settings[["sampling"]]

  assertthat::assert_that(
    base::is.numeric(step_size),
    base::length(step_size) == 1L,
    base::is.finite(step_size),
    step_size >= 1L,
    msg = "The fitted model must contain a positive `step_size`."
  )

  assertthat::assert_that(
    base::is.numeric(sampling),
    base::length(sampling) == 1L,
    base::is.finite(sampling),
    sampling >= 1L,
    msg = "The fitted model must contain a positive `sampling` value."
  )

  batch_size <-
    base::as.integer(step_size)

  if (
    batch_size > base::nrow(data_abiotic_matrix)
  ) {
    batch_size <- 1L
  }

  likelihood_function <-
    object[["model"]][["logLik"]]

  assertthat::assert_that(
    base::is.function(likelihood_function),
    msg = "The fitted model must expose a likelihood function."
  )

  negative_log_likelihood_draws <-
    base::seq_len(base::as.integer(n_likelihood_draws)) |>
    purrr::map_dbl(
      .f = ~ {
        likelihood_raw <-
          base::do.call(
            what = likelihood_function,
            args = base::list(
              data_abiotic_matrix,
              data_observed,
              SP = data_spatial_matrix,
              batch_size = batch_size,
              sampling = base::as.integer(sampling)
            )
          )

        likelihood_converted <-
          if (
            base::inherits(likelihood_raw, "python.builtin.object")
          ) {
            reticulate::py_to_r(likelihood_raw)
          } else {
            likelihood_raw
          }

        likelihood_value <-
          likelihood_converted[[1L]] |>
          base::as.numeric()

        assertthat::assert_that(
          base::length(likelihood_value) == 1L,
          base::is.finite(likelihood_value),
          msg = "The sjSDM likelihood must return one finite value."
        )

        return(likelihood_value)
      }
    )

  joint_negative_log_likelihood_test <-
    base::mean(negative_log_likelihood_draws)

  res <-
    data_probability_metrics |>
    dplyr::mutate(
      negative_log_likelihood_test =
        .env[["joint_negative_log_likelihood_test"]],
      negative_log_likelihood_per_response =
        .env[["joint_negative_log_likelihood_test"]] /
        .data[["n_response_values"]]
    )

  return(res)
}

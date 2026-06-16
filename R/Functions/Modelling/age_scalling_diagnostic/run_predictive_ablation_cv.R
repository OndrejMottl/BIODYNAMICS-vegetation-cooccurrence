#' @title Run Predictive Ablation Cross-Validation
#' @description
#' Runs full, no-abiotic, no-spatial, and no-associations sjSDM
#' cross-validation variants and returns fold-level predictive metrics.
#' @param data_model_input
#' Model input list with `data_community_to_fit`,
#' `data_abiotic_to_fit`, and `data_spatial_to_fit`.
#' @param cv_indices
#' Repeated fold lists from `make_repeated_cv_indices()`.
#' @param config_model_fitting
#' Optional fitting configuration list. Used for `error_family`,
#' `use_age_in_formula`, `n_iter`, `n_sampling`, and `n_step_size`.
#' @param iter
#' Optional epoch count overriding `config_model_fitting$n_iter`.
#' @param sampling
#' Optional Monte Carlo sampling count overriding
#' `config_model_fitting$n_sampling`.
#' @param step_size
#' Optional batch size overriding `config_model_fitting$n_step_size`.
#' @param device
#' Device passed to `sjSDM::sjSDM_cv()`. Default is `"gpu"`.
#' @param n_cores
#' Optional number of cores for `sjSDM::sjSDM_cv()`. Default `NULL`
#' keeps the smoke run sequential.
#' @param tune
#' Tuning strategy passed to `sjSDM::sjSDM_cv()`. Default is `"grid"`.
#' @param tune_steps
#' Number of random tuning steps when `tune = "random"`.
#' @param selection_metric
#' Single character string. Metric used to select one tuning row per
#' fold and variant. One of `"loss"`, `"auc_test"`, or
#' `"auc_macro_test"`.
#' @param alpha_cov,alpha_coef,alpha_spatial
#' Alpha tuning values passed to `sjSDM::sjSDM_cv()`.
#' @param lambda_cov,lambda_coef,lambda_spatial
#' Lambda tuning values passed to `sjSDM::sjSDM_cv()`.
#' @param cv_fn
#' Cross-validation function. Defaults to `sjSDM::sjSDM_cv()` and is
#' injectable for unit tests.
#' @param seed
#' Single integer seed passed to sjSDM fitting.
#' @param verbose
#' Logical. If `TRUE`, progress messages are printed via `cli`.
#' @return
#' A tibble with fold-level metrics for every repeat and variant.
#' @export
run_predictive_ablation_cv <- function(
    data_model_input,
    cv_indices,
    config_model_fitting = NULL,
    iter = NULL,
    sampling = NULL,
    step_size = NULL,
    device = "gpu",
    n_cores = NULL,
    tune = "grid",
    tune_steps = 20L,
    selection_metric = "loss",
    alpha_cov = 0.5,
    alpha_coef = 0.5,
    alpha_spatial = 0.5,
    lambda_cov = 0,
    lambda_coef = 0,
    lambda_spatial = 0,
    cv_fn = sjSDM::sjSDM_cv,
    seed = 900723L,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.list(data_model_input),
    msg = "`data_model_input` must be a list."
  )

  assertthat::assert_that(
    base::is.list(cv_indices),
    base::length(cv_indices) > 0L,
    msg = "`cv_indices` must be a non-empty repeated fold list."
  )

  assertthat::assert_that(
    base::is.function(cv_fn),
    msg = "`cv_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.character(tune),
    base::length(tune) == 1L,
    tune %in% c("grid", "random"),
    msg = "`tune` must be either 'grid' or 'random'."
  )

  assertthat::assert_that(
    base::is.character(selection_metric),
    base::length(selection_metric) == 1L,
    selection_metric %in% c("loss", "auc_test", "auc_macro_test"),
    msg = paste0(
      "`selection_metric` must be one of 'loss', 'auc_test',",
      " or 'auc_macro_test'."
    )
  )

  assertthat::assert_that(
    assertthat::is.flag(verbose),
    msg = "`verbose` must be a single logical value."
  )

  vec_required_input <-
    c(
      "data_community_to_fit",
      "data_abiotic_to_fit",
      "data_spatial_to_fit"
    )

  assertthat::assert_that(
    base::all(vec_required_input %in% base::names(data_model_input)),
    msg = stringr::str_glue(
      "`data_model_input` must contain columns: ",
      "{stringr::str_c(vec_required_input, collapse = ', ')}."
    )
  )

  data_community <-
    data_model_input |>
    purrr::chuck("data_community_to_fit")

  data_abiotic <-
    data_model_input |>
    purrr::chuck("data_abiotic_to_fit")

  data_spatial <-
    data_model_input |>
    purrr::chuck("data_spatial_to_fit")

  assertthat::assert_that(
    base::is.matrix(data_community),
    msg = "`data_community_to_fit` must be a matrix."
  )

  assertthat::assert_that(
    base::is.data.frame(data_abiotic),
    msg = "`data_abiotic_to_fit` must be a data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_spatial),
    msg = "`data_spatial_to_fit` must be a data frame."
  )

  use_age_in_formula <-
    if (
      base::is.null(config_model_fitting) ||
        base::is.null(config_model_fitting[["use_age_in_formula"]])
    ) {
      TRUE
    } else {
      config_model_fitting[["use_age_in_formula"]]
    }

  error_family_name <-
    if (
      base::is.null(config_model_fitting) ||
        base::is.null(config_model_fitting[["error_family"]])
    ) {
      "binomial"
    } else {
      config_model_fitting[["error_family"]]
    }

  iter_value <-
    if (
      !base::is.null(iter)
    ) {
      iter
    } else if (
      !base::is.null(config_model_fitting) &&
        !base::is.null(config_model_fitting[["n_iter"]])
    ) {
      config_model_fitting[["n_iter"]]
    } else {
      25L
    }

  sampling_value <-
    if (
      !base::is.null(sampling)
    ) {
      sampling
    } else if (
      !base::is.null(config_model_fitting) &&
        !base::is.null(config_model_fitting[["n_sampling"]])
    ) {
      config_model_fitting[["n_sampling"]]
    } else {
      100L
    }

  step_size_value <-
    if (
      !base::is.null(step_size)
    ) {
      step_size
    } else if (
      !base::is.null(config_model_fitting) &&
        !base::is.null(config_model_fitting[["n_step_size"]])
    ) {
      config_model_fitting[["n_step_size"]]
    } else {
      NULL
    }

  family_value <-
    if (
      error_family_name == "binomial"
    ) {
      stats::binomial("probit")
    } else if (
      error_family_name == "gaussian"
    ) {
      stats::gaussian()
    } else {
      cli::cli_abort(
        "`error_family` must be either 'binomial' or 'gaussian'."
      )
    }

  data_abiotic_constant <-
    base::data.frame(
      abiotic_constant = base::rep(
        x = 1,
        times = base::nrow(data_abiotic)
      )
    )

  rownames(data_abiotic_constant) <-
    rownames(data_abiotic)

  env_full <-
    do.call(
      sjSDM::linear,
      list(
        data = data_abiotic,
        formula = make_env_formula(
          data = data_abiotic,
          use_age = use_age_in_formula
        )
      )
    )

  env_no_abiotic <-
    do.call(
      sjSDM::linear,
      list(
        data = data_abiotic_constant,
        formula = stats::as.formula("~ 0 + abiotic_constant")
      )
    )

  spatial_full <-
    do.call(
      sjSDM::linear,
      list(
        data = data_spatial,
        formula = stats::as.formula("~ 0 + .")
      )
    )

  list_variants <-
    base::list(
      full = base::list(
        env = env_full,
        spatial = spatial_full,
        biotic = sjSDM::bioticStruct()
      ),
      no_abiotic = base::list(
        env = env_no_abiotic,
        spatial = spatial_full,
        biotic = sjSDM::bioticStruct()
      ),
      no_spatial = base::list(
        env = env_full,
        spatial = NULL,
        biotic = sjSDM::bioticStruct()
      ),
      no_associations = base::list(
        env = env_full,
        spatial = spatial_full,
        biotic = sjSDM::bioticStruct(diag = TRUE)
      )
    )

  empty_variant_metrics <- function(
      repeat_id,
      variant_name,
      status,
      error_message) {
    tibble::tibble(
      repeat_id = repeat_id,
      fold_id = base::seq_along(cv_indices[[repeat_id]]),
      variant = variant_name,
      selection_metric = selection_metric,
      tune_step = NA_integer_,
      alpha_cov = NA_real_,
      alpha_coef = NA_real_,
      alpha_spatial = NA_real_,
      lambda_cov = NA_real_,
      lambda_coef = NA_real_,
      lambda_spatial = NA_real_,
      ll_test = NA_real_,
      loss = NA_real_,
      auc_test = NA_real_,
      auc_macro_test = NA_real_,
      pred_log_loss = NA_real_,
      pred_brier = NA_real_,
      status = status,
      error_message = error_message
    )
  }

  compute_prediction_metrics <- function(res_cv, tune_step, fold_id) {
    res_empty <-
      tibble::tibble(
        pred_log_loss = NA_real_,
        pred_brier = NA_real_
      )

    list_tune_results <-
      purrr::pluck(res_cv, "tune_results", .default = NULL)

    if (
      base::is.null(list_tune_results) ||
        base::length(list_tune_results) < tune_step
    ) {
      return(res_empty)
    }

    data_fold_result <-
      purrr::pluck(
        list_tune_results,
        tune_step,
        fold_id,
        .default = NULL
      )

    if (
      base::is.null(data_fold_result) ||
        base::is.null(data_fold_result[["pred_test"]]) ||
        base::is.null(data_fold_result[["indices"]])
    ) {
      return(res_empty)
    }

    vec_indices <-
      data_fold_result[["indices"]]

    pred_test <-
      data_fold_result[["pred_test"]]

    if (
      base::length(vec_indices) == 0L
    ) {
      return(res_empty)
    }

    data_observed <-
      data_community[vec_indices, , drop = FALSE]

    if (
      !base::all(base::dim(data_observed) == base::dim(pred_test))
    ) {
      return(res_empty)
    }

    pred_clipped <-
      base::pmin(
        base::pmax(pred_test, 1e-6),
        1 - 1e-6
      )

    pred_log_loss <-
      -base::mean(
        data_observed * base::log(pred_clipped) +
          (1 - data_observed) * base::log(1 - pred_clipped)
      )

    pred_brier <-
      base::mean((data_observed - pred_clipped)^2)

    res <-
      tibble::tibble(
        pred_log_loss = pred_log_loss,
        pred_brier = pred_brier
      )

    return(res)
  }

  run_one_variant <- function(variant_name, list_variant, repeat_id) {
    if (
      base::isTRUE(verbose)
    ) {
      cli::cli_inform(
        stringr::str_glue(
          "Running {variant_name}, repeat {repeat_id}."
        )
      )
    }

    res_cv <-
      tryCatch(
        expr = {
          cv_fn(
            Y = data_community,
            env = list_variant[["env"]],
            biotic = list_variant[["biotic"]],
            spatial = list_variant[["spatial"]],
            tune = tune,
            CV = cv_indices[[repeat_id]],
            tune_steps = tune_steps,
            alpha_cov = alpha_cov,
            alpha_coef = alpha_coef,
            alpha_spatial = alpha_spatial,
            lambda_cov = lambda_cov,
            lambda_coef = lambda_coef,
            lambda_spatial = lambda_spatial,
            device = device,
            n_cores = n_cores,
            sampling = sampling_value,
            iter = iter_value,
            step_size = step_size_value,
            family = family_value,
            seed = seed
          )
        },
        error = function(e) {
          e
        }
      )

    if (
      base::inherits(res_cv, "error")
    ) {
      return(
        empty_variant_metrics(
          repeat_id = repeat_id,
          status = "error",
          error_message = base::conditionMessage(res_cv)
        )
      )
    }

    data_summary <-
      res_cv |>
      purrr::chuck("summary") |>
      tibble::as_tibble()

    if (
      !("iter" %in% base::colnames(data_summary))
    ) {
      data_summary <-
        data_summary |>
        dplyr::group_by(.data$CV_set) |>
        dplyr::mutate(iter = dplyr::row_number()) |>
        dplyr::ungroup()
    }

    vec_required_summary <-
      c("iter", "CV_set", "ll_test", "AUC_test", "AUC_macro_test")

    if (
      !base::all(vec_required_summary %in% base::colnames(data_summary))
    ) {
      return(
        empty_variant_metrics(
          repeat_id = repeat_id,
          status = "error",
          error_message = "CV summary did not contain required columns."
        )
      )
    }

    data_selected <-
      data_summary |>
      dplyr::mutate(
        loss = base::as.numeric(.data$ll_test),
        auc_test = base::as.numeric(.data$AUC_test),
        auc_macro_test = base::as.numeric(.data$AUC_macro_test),
        selection_value = if (
          selection_metric == "loss"
        ) {
          .data$loss
        } else if (
          selection_metric == "auc_test"
        ) {
          -.data$auc_test
        } else {
          -.data$auc_macro_test
        }
      ) |>
      dplyr::group_by(.data$CV_set) |>
      dplyr::arrange(
        .data$selection_value,
        .by_group = TRUE
      ) |>
      dplyr::slice(1L) |>
      dplyr::ungroup()

    data_tune_folds <-
      data_selected |>
      dplyr::mutate(
        tune_step = base::as.integer(.data$iter),
        fold_id = base::as.integer(.data$CV_set)
      ) |>
      dplyr::select(
        dplyr::all_of(
          base::c("tune_step", "fold_id")
        )
      )

    data_prediction_metrics <-
      purrr::map2(
        .x = dplyr::pull(data_tune_folds, tune_step),
        .y = dplyr::pull(data_tune_folds, fold_id),
        .f = ~ compute_prediction_metrics(
          res_cv = res_cv,
          tune_step = .x,
          fold_id = .y
        )
      ) |>
      purrr::list_rbind()

    data_selected |>
      dplyr::mutate(
        alpha_cov = if (
          "alpha_cov" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$alpha_cov)
        } else {
          NA_real_
        },
        alpha_coef = if (
          "alpha_coef" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$alpha_coef)
        } else {
          NA_real_
        },
        alpha_spatial = if (
          "alpha_spatial" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$alpha_spatial)
        } else {
          NA_real_
        },
        lambda_cov = if (
          "lambda_cov" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$lambda_cov)
        } else {
          NA_real_
        },
        lambda_coef = if (
          "lambda_coef" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$lambda_coef)
        } else {
          NA_real_
        },
        lambda_spatial = if (
          "lambda_spatial" %in% base::colnames(data_selected)
        ) {
          base::as.numeric(.data$lambda_spatial)
        } else {
          NA_real_
        }
      ) |>
      dplyr::bind_cols(data_prediction_metrics) |>
      dplyr::transmute(
        repeat_id = repeat_id,
        fold_id = base::as.integer(.data$CV_set),
        variant = variant_name,
        selection_metric = selection_metric,
        tune_step = base::as.integer(.data$iter),
        alpha_cov = .data$alpha_cov,
        alpha_coef = .data$alpha_coef,
        alpha_spatial = .data$alpha_spatial,
        lambda_cov = .data$lambda_cov,
        lambda_coef = .data$lambda_coef,
        lambda_spatial = .data$lambda_spatial,
        ll_test = base::as.numeric(.data$ll_test),
        # sjSDM_cv names this column `ll_test`, but sjSDM.tune()
        #   minimizes it; treat it as a predictive loss/deviance.
        loss = base::as.numeric(.data$ll_test),
        auc_test = base::as.numeric(.data$AUC_test),
        auc_macro_test = base::as.numeric(.data$AUC_macro_test),
        pred_log_loss = .data$pred_log_loss,
        pred_brier = .data$pred_brier,
        status = "ok",
        error_message = NA_character_
      )
  }

  res <-
    base::seq_along(cv_indices) |>
    purrr::map(
      .f = ~ {
        repeat_id <- .x

        list_variants |>
          purrr::imap(
            .f = ~ run_one_variant(
              variant_name = .y,
              list_variant = .x,
              repeat_id = repeat_id
            )
          ) |>
          purrr::list_rbind()
      }
    ) |>
    purrr::list_rbind()

  return(res)
}

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Asia decomposition method comparison diagnostic
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares train-model ANOVA shares with held-out predictive
#   ablation shares for scaled-age interaction models.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_continental")

base::suppressWarnings(
  base::suppressMessages(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

store_path <-
  here::here(
    "Data/targets/paleo_spatial_continental/asia",
    "pipeline_paleo_spatial_resolution"
  )

path_temp <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "asia_method_comparison"
  )

path_reports <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "asia_method_comparison"
  )

path_checkpoints <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_checkpoints"
  )

path_checkpoint_variant_metrics <-
  base::file.path(path_checkpoints, "variant_metrics")

path_checkpoint_anova_shares <-
  base::file.path(path_checkpoints, "anova_shares")

path_checkpoint_predictive_shares <-
  base::file.path(path_checkpoints, "predictive_shares")

purrr::walk(
  .x = c(
    path_temp,
    path_reports,
    path_checkpoint_variant_metrics,
    path_checkpoint_anova_shares,
    path_checkpoint_predictive_shares
  ),
  .f = ~ base::dir.create(
    path = .x,
    showWarnings = FALSE,
    recursive = TRUE
  )
)


#----------------------------------------------------------#
# 1. Run settings -----
#----------------------------------------------------------#

n_folds <- 3L
n_repeats <- 1L
seed_cv <- 900723L
n_samples_anova <- 200L

iter_override <- 500L
sampling_override <- 200L
step_size_override <- NULL
n_early_stopping_override <- NULL
device_override <- "gpu"


#----------------------------------------------------------#
# 2. Load upstream targets -----
#----------------------------------------------------------#

diagnostic_inputs <-
  load_decomposition_diagnostic_inputs(
    store_path = store_path,
    resolution_id = "genus"
  )

config_model_fitting <-
  diagnostic_inputs |>
  purrr::chuck("config_model_fitting")

fit_config <-
  base::list(
    device = device_override,
    parallel = 0L,
    iter = if (
      base::is.null(iter_override)
    ) {
      config_model_fitting[["n_iter"]]
    } else {
      iter_override
    },
    sampling = if (
      base::is.null(sampling_override)
    ) {
      config_model_fitting[["n_sampling"]]
    } else {
      sampling_override
    },
    step_size = if (
      base::is.null(step_size_override)
    ) {
      config_model_fitting[["n_step_size"]]
    } else {
      step_size_override
    },
    n_early_stopping = if (
      base::is.null(n_early_stopping_override)
    ) {
      n_early_stopping_override
    } else {
      n_early_stopping_override
    }
  )

data_routes <-
  tibble::tibble(
    route_id = "pooled_spatiotemporal_age_z_interaction",
    sample_mode = "pooled",
    spatial_mode = "spatiotemporal",
    use_age = TRUE,
    age_formula_mode = "interaction",
    age_scale_mode = "z_score"
  )


#----------------------------------------------------------#
# 3. Local fitting helpers -----
#----------------------------------------------------------#

make_checkpoint_file <- function(path, route_id, repeat_id, fold_id) {
  res <-
    base::file.path(
      path,
      stringr::str_glue("{route_id}_{repeat_id}_{fold_id}.csv")
    )

  return(res)
}

make_empty_anova_shares <- function(route_id, repeat_id, fold_id, status) {
  res <-
    tibble::tibble(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      component = c("Abiotic", "Associations", "Spatial"),
      anova_share = NA_real_,
      anova_status = status,
      anova_defined = FALSE
    )

  return(res)
}

fit_variant <- function(
    data_fold_input,
    route,
    route_id,
    repeat_id,
    fold_id,
    variant_name,
    variant_settings) {
  vec_warnings <-
    base::character()

  data_train_input <-
    data_fold_input |>
    purrr::chuck("data_train_input")

  data_test_input <-
    data_fold_input |>
    purrr::chuck("data_test_input")

  data_observed <-
    data_fold_input |>
    purrr::chuck("data_test_observed")

  data_diagnostics <-
    data_fold_input |>
    purrr::chuck("data_diagnostics")

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
        age_formula_mode = route[["age_formula_mode"]][[1L]]
      )
  }

  list_fit_arguments <-
    base::list(
      data_to_fit = data_train_variant,
      sel_abiotic_formula = formula_abiotic,
      sel_spatial_formula = stats::as.formula("~ 0 + ."),
      spatial_method = variant_settings[["spatial_method"]],
      error_family = config_model_fitting[["error_family"]],
      device = fit_config[["device"]],
      parallel = fit_config[["parallel"]],
      compute_se = FALSE,
      biotic = variant_settings[["biotic"]],
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
            what = fit_jsdm_model,
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

  make_metric_row <- function(
      status,
      error_message,
      converged = FALSE,
      convergence = NULL,
      metrics = NULL) {
    if (
      base::is.null(convergence)
    ) {
      convergence <-
        base::list(
          linear_trend_slope = NA_real_,
          median_diff = NA_real_,
          epochs_run = NA_integer_,
          early_stopping_triggered = NA
        )
    }

    if (
      base::is.null(metrics)
    ) {
      metrics <-
        tibble::tibble(
          loss = NA_real_,
          brier = NA_real_,
          auc = NA_real_,
          auc_macro = NA_real_
        )
    }

    res <-
      tibble::tibble(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        variant = variant_name,
        status = status,
        error_message = error_message,
        warning_text = warning_text,
        converged = converged,
        linear_trend_slope = convergence[["linear_trend_slope"]],
        median_diff = convergence[["median_diff"]],
        epochs_run = convergence[["epochs_run"]],
        early_stopping_triggered = convergence[[
          "early_stopping_triggered"
        ]]
      ) |>
      dplyr::bind_cols(metrics) |>
      dplyr::bind_cols(data_diagnostics)

    return(res)
  }

  if (
    base::inherits(mod_fit, "error")
  ) {
    return(
      base::list(
        model = NULL,
        metrics = make_metric_row(
          status = "error",
          error_message = base::conditionMessage(mod_fit)
        )
      )
    )
  }

  convergence <-
    tryCatch(
      expr = check_convergence_jsdm(mod_fit),
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(convergence, "error")
  ) {
    return(
      base::list(
        model = mod_fit,
        metrics = make_metric_row(
          status = "convergence_error",
          error_message = base::conditionMessage(convergence)
        )
      )
    )
  }

  flag_converged <-
    convergence[["linear_trend_slope"]] < 0.01 &&
    convergence[["median_diff"]] < 1

  data_spatial_test <-
    if (
      variant_settings[["spatial_method"]] == "none"
    ) {
      NULL
    } else {
      data_test_input |>
        purrr::chuck("data_spatial_to_fit")
    }

  data_predicted <-
    tryCatch(
      expr = stats::predict(
        object = mod_fit,
        newdata = data_test_abiotic,
        SP = data_spatial_test,
        type = "raw"
      ),
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(data_predicted, "error")
  ) {
    return(
      base::list(
        model = mod_fit,
        metrics = make_metric_row(
          status = "prediction_error",
          error_message = base::conditionMessage(data_predicted),
          converged = flag_converged,
          convergence = convergence
        )
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
    base::list(
      model = mod_fit,
      metrics = make_metric_row(
        status = status_value,
        error_message = NA_character_,
        converged = flag_converged,
        convergence = convergence,
        metrics = data_metrics
      )
    )

  return(res)
}

compute_anova_shares <- function(mod_full, route_id, repeat_id, fold_id) {
  if (
    base::is.null(mod_full)
  ) {
    return(
      make_empty_anova_shares(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        status = "full_model_missing"
      )
    )
  }

  anova_object <-
    tryCatch(
      expr = get_anova(
        mod = mod_full,
        n_samples = n_samples_anova,
        verbose = FALSE
      ),
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(anova_object, "error")
  ) {
    return(
      make_empty_anova_shares(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        status = base::conditionMessage(anova_object)
      )
    )
  }

  res <-
    extract_anova_fractions(anova_object = anova_object) |>
    dplyr::mutate(age = 0) |>
    recalculate_anova_components() |>
    dplyr::transmute(
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id,
      component = .data$component,
      anova_share = .data$R2_Nagelkerke_percentage,
      anova_status = "ok",
      anova_defined = base::is.finite(.data$R2_Nagelkerke_percentage)
    )

  return(res)
}

run_one_checkpoint <- function(route, repeat_id, fold_id, test_indices) {
  route_id <-
    route[["route_id"]][[1L]]

  file_variant_metrics <-
    make_checkpoint_file(
      path = path_checkpoint_variant_metrics,
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id
    )

  file_anova_shares <-
    make_checkpoint_file(
      path = path_checkpoint_anova_shares,
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id
    )

  file_predictive_shares <-
    make_checkpoint_file(
      path = path_checkpoint_predictive_shares,
      route_id = route_id,
      repeat_id = repeat_id,
      fold_id = fold_id
    )

  if (
    base::file.exists(file_variant_metrics) &&
      base::file.exists(file_anova_shares) &&
      base::file.exists(file_predictive_shares)
  ) {
    return(
      base::list(
        variant_metrics = readr::read_csv(
          file = file_variant_metrics,
          show_col_types = FALSE
        ),
        anova_shares = readr::read_csv(
          file = file_anova_shares,
          show_col_types = FALSE
        ),
        predictive_shares = readr::read_csv(
          file = file_predictive_shares,
          show_col_types = FALSE
        )
      )
    )
  }

  data_route_sample_ids <-
    get_decomposition_route_sample_ids(
      route = route,
      inputs = diagnostic_inputs
    )

  vec_sample_ids <-
    data_route_sample_ids |>
    dplyr::pull(.data$.row_name)

  vec_test_ids <-
    vec_sample_ids[test_indices]

  vec_train_ids <-
    vec_sample_ids[-test_indices]

  cli::cli_inform(
    stringr::str_glue(
      "Running {route_id}, {repeat_id}, {fold_id}."
    )
  )

  data_fold_input <-
    prepare_decomposition_fold_input(
      route = route,
      inputs = diagnostic_inputs,
      train_ids = vec_train_ids,
      test_ids = vec_test_ids
    )

  list_variants <-
    base::list(
      full = base::list(
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct()
      ),
      no_abiotic = base::list(
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct()
      ),
      no_spatial = base::list(
        spatial_method = "none",
        biotic = sjSDM::bioticStruct()
      ),
      no_associations = base::list(
        spatial_method = "linear",
        biotic = sjSDM::bioticStruct(diag = TRUE)
      )
    )

  list_fit_results <-
    list_variants |>
    purrr::imap(
      .f = ~ fit_variant(
        data_fold_input = data_fold_input,
        route = route,
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        variant_name = .y,
        variant_settings = .x
      )
    )

  data_variant_metrics <-
    list_fit_results |>
    purrr::map(.f = ~ .x[["metrics"]]) |>
    purrr::list_rbind()

  full_status <-
    data_variant_metrics |>
    dplyr::filter(.data$variant == "full") |>
    dplyr::pull(.data$status) |>
    dplyr::first()

  data_anova_shares <-
    if (
      full_status == "ok"
    ) {
      compute_anova_shares(
        mod_full = list_fit_results[["full"]][["model"]],
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id
      )
    } else {
      make_empty_anova_shares(
        route_id = route_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        status = "full_model_not_converged"
      )
    }

  data_predictive_shares <-
    compute_predictive_decomposition_shares(
      data_fold_metrics = data_variant_metrics
    ) |>
    dplyr::mutate(
      route_id = route_id,
      .before = 1L
    )

  readr::write_csv(
    x = data_variant_metrics,
    file = file_variant_metrics
  )

  readr::write_csv(
    x = data_anova_shares,
    file = file_anova_shares
  )

  readr::write_csv(
    x = data_predictive_shares,
    file = file_predictive_shares
  )

  res <-
    base::list(
      variant_metrics = data_variant_metrics,
      anova_shares = data_anova_shares,
      predictive_shares = data_predictive_shares
    )

  return(res)
}


#----------------------------------------------------------#
# 4. Run checkpointed folds -----
#----------------------------------------------------------#

list_checkpoint_results <-
  data_routes |>
  dplyr::group_split(.data$route_id) |>
  purrr::map(
    .f = ~ {
      route_i <-
        .x

      data_route_sample_ids <-
        get_decomposition_route_sample_ids(
          route = route_i,
          inputs = diagnostic_inputs
        )

      cv_indices <-
        make_repeated_cv_indices(
          n_samples = base::nrow(data_route_sample_ids),
          n_folds = n_folds,
          n_repeats = n_repeats,
          seed = seed_cv
        )

      cv_indices |>
        purrr::imap(
          .f = ~ {
            repeat_id_i <-
              .y

            .x |>
              purrr::imap(
                .f = ~ run_one_checkpoint(
                  route = route_i,
                  repeat_id = repeat_id_i,
                  fold_id = .y,
                  test_indices = .x
                )
              )
          }
        ) |>
        purrr::flatten()
    }
  ) |>
  purrr::flatten()

data_variant_metrics <-
  list_checkpoint_results |>
  purrr::map(.f = ~ .x[["variant_metrics"]]) |>
  purrr::list_rbind()

data_anova_shares <-
  list_checkpoint_results |>
  purrr::map(.f = ~ .x[["anova_shares"]]) |>
  purrr::list_rbind()

data_predictive_shares <-
  list_checkpoint_results |>
  purrr::map(.f = ~ .x[["predictive_shares"]]) |>
  purrr::list_rbind()


#----------------------------------------------------------#
# 5. Compare methods -----
#----------------------------------------------------------#

data_fold_comparison <-
  data_anova_shares |>
  dplyr::select(
    "route_id",
    "repeat_id",
    "fold_id",
    "component",
    "anova_share",
    "anova_status",
    "anova_defined"
  ) |>
  dplyr::left_join(
    data_predictive_shares |>
      dplyr::select(
        "route_id",
        "repeat_id",
        "fold_id",
        "component",
        predictive_share = "share",
        predictive_defined = "defined"
      ),
    by = dplyr::join_by(route_id, repeat_id, fold_id, component)
  ) |>
  dplyr::mutate(
    delta_anova_minus_predictive = .data$anova_share -
      .data$predictive_share,
    both_defined = .data$anova_defined & .data$predictive_defined
  )

data_fold_agreement <-
  data_fold_comparison |>
  dplyr::group_by(
    .data$route_id,
    .data$repeat_id,
    .data$fold_id
  ) |>
  dplyr::group_modify(
    .f = ~ {
      data_fold <-
        .x

      flag_defined <-
        base::all(data_fold[["both_defined"]])

      if (
        !base::isTRUE(flag_defined)
      ) {
        return(
          tibble::tibble(
            methods_defined = FALSE,
            spearman_component_share = NA_real_,
            anova_strongest = NA_character_,
            predictive_strongest = NA_character_,
            same_strongest_component = NA
          )
        )
      }

      anova_strongest <-
        data_fold[["component"]][
          base::which.max(data_fold[["anova_share"]])
        ]

      predictive_strongest <-
        data_fold[["component"]][
          base::which.max(data_fold[["predictive_share"]])
        ]

      tibble::tibble(
        methods_defined = TRUE,
        spearman_component_share = stats::cor(
          x = data_fold[["anova_share"]],
          y = data_fold[["predictive_share"]],
          method = "spearman"
        ),
        anova_strongest = anova_strongest,
        predictive_strongest = predictive_strongest,
        same_strongest_component = anova_strongest ==
          predictive_strongest
      )
    }
  ) |>
  dplyr::ungroup()

data_anova_summary <-
  data_anova_shares |>
  dplyr::group_by(.data$route_id, .data$component) |>
  dplyr::summarise(
    anova_share_median = stats::median(
      .data$anova_share,
      na.rm = TRUE
    ),
    anova_lwr_95 = stats::quantile(
      x = .data$anova_share,
      probs = 0.025,
      na.rm = TRUE,
      names = FALSE
    ),
    anova_upr_95 = stats::quantile(
      x = .data$anova_share,
      probs = 0.975,
      na.rm = TRUE,
      names = FALSE
    ),
    anova_n_defined = base::sum(.data$anova_defined, na.rm = TRUE),
    .groups = "drop"
  )

data_predictive_summary <-
  data_predictive_shares |>
  dplyr::group_by(.data$route_id) |>
  dplyr::group_split() |>
  purrr::map(
    .f = ~ {
      route_id <-
        .x[["route_id"]][[1L]]

      .x |>
        summarize_predictive_decomposition() |>
        dplyr::mutate(route_id = route_id, .before = 1L)
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::rename(
    predictive_share_median = "share_median",
    predictive_lwr_95 = "lwr_95",
    predictive_upr_95 = "upr_95",
    predictive_n_defined = "n_defined"
  )

data_route_summary <-
  data_anova_summary |>
  dplyr::left_join(
    data_predictive_summary,
    by = dplyr::join_by(route_id, component)
  )

data_agreement_summary <-
  data_fold_agreement |>
  dplyr::group_by(.data$route_id) |>
  dplyr::summarise(
    n_folds = dplyr::n(),
    n_defined_folds = base::sum(.data$methods_defined, na.rm = TRUE),
    median_spearman_component_share = stats::median(
      .data$spearman_component_share,
      na.rm = TRUE
    ),
    proportion_same_strongest_component = base::mean(
      .data$same_strongest_component,
      na.rm = TRUE
    ),
    .groups = "drop"
  )


#----------------------------------------------------------#
# 6. Write outputs -----
#----------------------------------------------------------#

file_run_metadata <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_run_metadata.csv"
  )

file_variant_metrics <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_variant_metrics.csv"
  )

file_anova_shares <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_anova_shares.csv"
  )

file_predictive_shares <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_predictive_shares.csv"
  )

file_fold_comparison <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_fold_comparison.csv"
  )

file_fold_agreement <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_fold_agreement.csv"
  )

file_route_summary <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_route_summary.csv"
  )

file_agreement_summary <-
  base::file.path(
    path_temp,
    "asia_decomposition_method_comparison_agreement_summary.csv"
  )

file_report <-
  base::file.path(
    path_reports,
    "asia_decomposition_method_comparison_report.md"
  )

data_run_metadata <-
  tibble::tibble(
    experiment_id = "asia_method_comparison",
    config_active = base::Sys.getenv("R_CONFIG_ACTIVE"),
    store_path = store_path,
    resolution_id = "genus",
    n_folds = n_folds,
    n_repeats = n_repeats,
    seed_cv = seed_cv,
    n_samples_anova = n_samples_anova,
    iter = fit_config[["iter"]],
    sampling = fit_config[["sampling"]],
    step_size = fit_config[["step_size"]],
    device = fit_config[["device"]],
    run_completed_at = base::as.character(base::Sys.time())
  )

readr::write_csv(x = data_run_metadata, file = file_run_metadata)
readr::write_csv(x = data_variant_metrics, file = file_variant_metrics)
readr::write_csv(x = data_anova_shares, file = file_anova_shares)
readr::write_csv(x = data_predictive_shares, file = file_predictive_shares)
readr::write_csv(x = data_fold_comparison, file = file_fold_comparison)
readr::write_csv(x = data_fold_agreement, file = file_fold_agreement)
readr::write_csv(x = data_route_summary, file = file_route_summary)
readr::write_csv(x = data_agreement_summary, file = file_agreement_summary)

vec_report_lines <-
  c(
    "# Asia Decomposition Method Comparison Diagnostic",
    "",
    "This report is generated by:",
    "",
    paste0(
      "`",
      "R/03_Supplementary_analyses/_Diagnostics/",
      "age_scalling/",
      "run_asia_decomposition_method_comparison_diagnostic.R",
      "`"
    ),
    "",
    "## Run Settings",
    "",
    paste0("- Folds: `", n_folds, "`"),
    paste0("- Repeats: `", n_repeats, "`"),
    paste0("- Iterations: `", fit_config[["iter"]], "`"),
    paste0("- Sampling: `", fit_config[["sampling"]], "`"),
    paste0("- ANOVA samples: `", n_samples_anova, "`"),
    paste0("- Device: `", fit_config[["device"]], "`"),
    "",
    "## Route Summary",
    "",
    utils::capture.output(print(data_route_summary, n = Inf)),
    "",
    "## Fold Agreement",
    "",
    utils::capture.output(print(data_fold_agreement, n = Inf)),
    "",
    "## Agreement Summary",
    "",
    utils::capture.output(print(data_agreement_summary, n = Inf)),
    "",
    "## Output Tables",
    "",
    paste0("- `", file_run_metadata, "`"),
    paste0("- `", file_variant_metrics, "`"),
    paste0("- `", file_anova_shares, "`"),
    paste0("- `", file_predictive_shares, "`"),
    paste0("- `", file_fold_comparison, "`"),
    paste0("- `", file_fold_agreement, "`"),
    paste0("- `", file_route_summary, "`"),
    paste0("- `", file_agreement_summary, "`")
  )

base::writeLines(text = vec_report_lines, con = file_report)

cli::cli_inform(
  c(
    "v" = stringr::str_glue("Saved metadata: {file_run_metadata}"),
    "v" = stringr::str_glue("Saved metrics: {file_variant_metrics}"),
    "v" = stringr::str_glue("Saved ANOVA shares: {file_anova_shares}"),
    "v" = stringr::str_glue(
      "Saved predictive shares: {file_predictive_shares}"
    ),
    "v" = stringr::str_glue("Saved comparison: {file_fold_comparison}"),
    "v" = stringr::str_glue("Saved report: {file_report}")
  )
)

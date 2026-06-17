#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        CZ genus predictive decomposition smoke pilot
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs a low-budget predictive ablation smoke test for the CZ paleo
#   genus branch in the resolution-test targets store.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

base::suppressWarnings(
  base::suppressMessages(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

store_path <-
  here::here("Data/targets/cz_paleo/pipeline_paleo_resolution_test")

path_temp <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "cz_predictive_pilot"
  )

path_figure <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "cz_predictive_pilot"
  )

base::dir.create(
  path = path_temp,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_figure,
  showWarnings = FALSE,
  recursive = TRUE
)

graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Load CZ genus targets -----
#----------------------------------------------------------#

if (
  isFALSE(base::dir.exists(store_path))
) {
  cli::cli_abort(
    stringr::str_glue("Targets store does not exist: {store_path}")
  )
}

data_meta <-
  targets::tar_meta(
    fields = c("name", "error"),
    complete_only = FALSE,
    store = store_path
  )

vec_required_targets <-
  c(
    "data_model_input_genus",
    "config_model_fitting",
    "model_anova_genus",
    "model_evaluation_genus"
  )

vec_missing_targets <-
  vec_required_targets |>
  purrr::discard(
    .p = ~ check_target_succeeded(
      data_meta = data_meta,
      target_name = .x
    )
  )

if (
  base::length(vec_missing_targets) > 0L
) {
  cli::cli_abort(
    c(
      "Required CZ genus targets are missing or failed.",
      "x" = stringr::str_c(vec_missing_targets, collapse = ", ")
    )
  )
}

data_model_input <-
  targets::tar_read_raw(
    name = "data_model_input_genus",
    store = store_path
  )

config_model_fitting <-
  targets::tar_read_raw(
    name = "config_model_fitting",
    store = store_path
  )

model_anova <-
  targets::tar_read_raw(
    name = "model_anova_genus",
    store = store_path
  )

model_evaluation <-
  targets::tar_read_raw(
    name = "model_evaluation_genus",
    store = store_path
  )


#----------------------------------------------------------#
# 2. Run predictive ablation smoke CV -----
#----------------------------------------------------------#

n_folds <-
  5L

n_repeats <-
  1L

seed_cv <-
  900723L

n_samples <-
  data_model_input |>
  purrr::chuck("data_community_to_fit") |>
  base::nrow()

cv_indices <-
  make_repeated_cv_indices(
    n_samples = n_samples,
    n_folds = n_folds,
    n_repeats = n_repeats,
    seed = seed_cv
  )

iter_smoke <-
  base::min(
    base::as.integer(config_model_fitting[["n_iter"]]),
    100L,
    na.rm = TRUE
  )

sampling_smoke <-
  base::min(
    base::as.integer(config_model_fitting[["n_sampling"]]),
    500L,
    na.rm = TRUE
  )

step_size_smoke <-
  base::min(
    base::as.integer(config_model_fitting[["n_step_size"]]),
    n_samples,
    na.rm = TRUE
  )

tune_strategy <-
  "random"

tune_steps <-
  5L

vec_lambda_tuning <-
  c(
    0,
    2^seq(-10, -2, length.out = 5)
  )

data_variant_metrics <-
  run_predictive_ablation_cv(
    data_model_input = data_model_input,
    cv_indices = cv_indices,
    config_model_fitting = config_model_fitting,
    iter = iter_smoke,
    sampling = sampling_smoke,
    step_size = step_size_smoke,
    device = "gpu",
    n_cores = NULL,
    tune = tune_strategy,
    tune_steps = tune_steps,
    selection_metric = "loss",
    alpha_cov = 0.5,
    alpha_coef = 0.5,
    alpha_spatial = 0.5,
    lambda_cov = vec_lambda_tuning,
    lambda_coef = vec_lambda_tuning,
    lambda_spatial = vec_lambda_tuning,
    seed = seed_cv,
    verbose = TRUE
  )

file_variant_metrics <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_variant_metrics.csv"
  )

readr::write_csv(
  x = data_variant_metrics,
  file = file_variant_metrics
)

if (
  isFALSE(base::any(data_variant_metrics[["status"]] == "ok"))
) {
  cli::cli_abort(
    c(
      "All predictive ablation variants failed.",
      "i" = stringr::str_glue(
        "Variant diagnostics were written to {file_variant_metrics}."
      )
    )
  )
}

data_fold_shares <-
  compute_predictive_decomposition_shares(
    data_fold_metrics = data_variant_metrics
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    .before = 1L
  )

data_summary <-
  summarise_predictive_decomposition(
    data_shares = data_fold_shares
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    .before = 1L
  )

data_auc_fold_shares <-
  compute_predictive_performance_shares(
    data_fold_metrics = data_variant_metrics,
    metric_column = "auc_test",
    metric_name = "AUC"
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    .before = 1L
  )

data_auc_summary <-
  summarise_predictive_decomposition(
    data_shares = data_auc_fold_shares
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "AUC",
    .before = 1L
  )

data_auc_macro_fold_shares <-
  compute_predictive_performance_shares(
    data_fold_metrics = data_variant_metrics,
    metric_column = "auc_macro_test",
    metric_name = "AUC_macro"
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    .before = 1L
  )

data_auc_macro_summary <-
  summarise_predictive_decomposition(
    data_shares = data_auc_macro_fold_shares
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "AUC_macro",
    .before = 1L
  )

data_pred_log_loss_fold_shares <-
  data_variant_metrics |>
  dplyr::mutate(loss = .data$pred_log_loss) |>
  compute_predictive_decomposition_shares() |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "pred_log_loss",
    .before = 1L
  )

data_pred_log_loss_summary <-
  summarise_predictive_decomposition(
    data_shares = data_pred_log_loss_fold_shares
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "pred_log_loss",
    .before = 1L
  )

data_pred_brier_fold_shares <-
  data_variant_metrics |>
  dplyr::mutate(loss = .data$pred_brier) |>
  compute_predictive_decomposition_shares() |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "pred_brier",
    .before = 1L
  )

data_pred_brier_summary <-
  summarise_predictive_decomposition(
    data_shares = data_pred_brier_fold_shares
  ) |>
  dplyr::mutate(
    resolution_id = "genus",
    metric_name = "pred_brier",
    .before = 1L
  )

file_fold_shares <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_folds.csv"
  )

file_summary <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_summary.csv"
  )

file_auc_fold_shares <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_auc_folds.csv"
  )

file_auc_summary <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_auc_summary.csv"
  )

file_auc_macro_fold_shares <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_auc_macro_folds.csv"
  )

file_auc_macro_summary <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_auc_macro_summary.csv"
  )

file_pred_log_loss_fold_shares <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_pred_log_loss_folds.csv"
  )

file_pred_log_loss_summary <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_pred_log_loss_summary.csv"
  )

file_pred_brier_fold_shares <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_pred_brier_folds.csv"
  )

file_pred_brier_summary <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_genus_pred_brier_summary.csv"
  )

readr::write_csv(
  x = data_fold_shares,
  file = file_fold_shares
)

readr::write_csv(
  x = data_summary,
  file = file_summary
)

readr::write_csv(
  x = data_auc_fold_shares,
  file = file_auc_fold_shares
)

readr::write_csv(
  x = data_auc_summary,
  file = file_auc_summary
)

readr::write_csv(
  x = data_auc_macro_fold_shares,
  file = file_auc_macro_fold_shares
)

readr::write_csv(
  x = data_auc_macro_summary,
  file = file_auc_macro_summary
)

readr::write_csv(
  x = data_pred_log_loss_fold_shares,
  file = file_pred_log_loss_fold_shares
)

readr::write_csv(
  x = data_pred_log_loss_summary,
  file = file_pred_log_loss_summary
)

readr::write_csv(
  x = data_pred_brier_fold_shares,
  file = file_pred_brier_fold_shares
)

readr::write_csv(
  x = data_pred_brier_summary,
  file = file_pred_brier_summary
)

if (
  isFALSE(base::any(data_fold_shares[["defined"]]))
) {
  cli::cli_abort(
    c(
      "No predictive decomposition folds produced defined shares.",
      "i" = stringr::str_glue(
        "Fold diagnostics were written to {file_fold_shares}."
      )
    )
  )
}


#----------------------------------------------------------#
# 3. Compare with ANOVA decomposition -----
#----------------------------------------------------------#

data_anova <-
  extract_anova_fractions(
    anova_object = model_anova,
    clamp_negative = TRUE
  ) |>
  dplyr::mutate(age = 0) |>
  recalculate_anova_components() |>
  dplyr::mutate(
    resolution_id = "genus"
  ) |>
  dplyr::select(
    resolution_id,
    component,
    anova_share = R2_Nagelkerke_percentage
  )

data_species_evaluation <-
  model_evaluation |>
  purrr::chuck("species")

existing_auc_mean <-
  if (
    "AUC" %in% base::colnames(data_species_evaluation)
  ) {
    data_species_evaluation |>
      dplyr::pull(.data$AUC) |>
      stats::median(na.rm = TRUE)
  } else {
    NA_real_
  }

data_comparison <-
  data_summary |>
  dplyr::left_join(
    data_anova,
    by = dplyr::join_by(resolution_id, component)
  ) |>
  dplyr::mutate(
    existing_auc_median = existing_auc_mean,
    share_delta_predictive_minus_anova = .data$share_median -
      .data$anova_share
  ) |>
  dplyr::arrange(.data$component)

file_comparison <-
  base::file.path(
    path_temp,
    "cz_predictive_decomposition_vs_anova_genus.csv"
  )

readr::write_csv(
  x = data_comparison,
  file = file_comparison
)


#----------------------------------------------------------#
# 4. Plot smoke summary -----
#----------------------------------------------------------#

plot_summary <-
  data_summary |>
  dplyr::filter(.data$component %in% c(
    "Abiotic",
    "Spatial",
    "Associations"
  )) |>
  dplyr::mutate(
    component = base::factor(
      .data$component,
      levels = c("Abiotic", "Spatial", "Associations")
    )
  ) |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data$component,
      y = .data$share_median
    )
  ) +
  ggplot2::scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20)
  ) +
  ggplot2::labs(
    x = NULL,
    y = "Predictive share (%)"
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_errorbar(
    mapping = ggplot2::aes(
      ymin = .data$lwr_95,
      ymax = .data$upr_95
    ),
    width = 0.15
  ) +
  ggplot2::geom_point(size = 3)

file_plot <-
  base::file.path(
    path_figure,
    "cz_predictive_decomposition_genus.png"
  )

ggview::save_ggplot(
  plot = plot_summary,
  file = file_plot
)

cli::cli_inform(
  c(
    "v" = stringr::str_glue("Saved variant metrics: {file_variant_metrics}"),
    "v" = stringr::str_glue("Saved fold shares: {file_fold_shares}"),
    "v" = stringr::str_glue("Saved summary: {file_summary}"),
    "v" = stringr::str_glue("Saved AUC folds: {file_auc_fold_shares}"),
    "v" = stringr::str_glue("Saved AUC summary: {file_auc_summary}"),
    "v" = stringr::str_glue(
      "Saved macro AUC folds: {file_auc_macro_fold_shares}"
    ),
    "v" = stringr::str_glue(
      "Saved macro AUC summary: {file_auc_macro_summary}"
    ),
    "v" = stringr::str_glue(
      "Saved prediction log-loss folds: {file_pred_log_loss_fold_shares}"
    ),
    "v" = stringr::str_glue(
      "Saved prediction log-loss summary: {file_pred_log_loss_summary}"
    ),
    "v" = stringr::str_glue(
      "Saved Brier folds: {file_pred_brier_fold_shares}"
    ),
    "v" = stringr::str_glue(
      "Saved Brier summary: {file_pred_brier_summary}"
    ),
    "v" = stringr::str_glue("Saved comparison: {file_comparison}"),
    "v" = stringr::str_glue("Saved figure: {file_plot}")
  )
)

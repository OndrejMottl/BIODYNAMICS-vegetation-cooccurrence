#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Asia predictive decomposition age minimal diagnostic
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs a minimal Asia genus decomposition diagnostic that compares
#   current center-scaled age interaction with z-scored age formulas.


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
    "asia_age_minimal"
  )

path_reports <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "asia_age_minimal"
  )

path_checkpoints <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_checkpoints"
  )

base::dir.create(
  path = path_temp,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_checkpoints,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_reports,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Run settings -----
#----------------------------------------------------------#

n_folds <- 3L
n_repeats <- 3L
seed_cv <- 900723L

# Optional overrides. Keep this diagnostic cheaper than production Asia.
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


#----------------------------------------------------------#
# 3. Run minimal age diagnostic routes -----
#----------------------------------------------------------#

data_routes <-
  tibble::tibble(
    route_id = c(
      "pooled_spatiotemporal_age_current",
      "pooled_spatiotemporal_age_z_main",
      "pooled_spatiotemporal_age_z_interaction"
    ),
    sample_mode = c(
      "pooled",
      "pooled",
      "pooled"
    ),
    spatial_mode = c(
      "spatiotemporal",
      "spatiotemporal",
      "spatiotemporal"
    ),
    use_age = c(
      TRUE,
      TRUE,
      TRUE
    ),
    age_formula_mode = c(
      "interaction",
      "main_effect",
      "interaction"
    ),
    age_scale_mode = c(
      "center",
      "z_score",
      "z_score"
    )
  )

run_one_checkpoint <- function(
    route,
    repeat_id,
    fold_id,
    test_indices) {
  route_id <-
    route[["route_id"]][[1L]]

  file_checkpoint <-
    base::file.path(
      path_checkpoints,
      stringr::str_glue(
        "{route_id}_repeat_{repeat_id}_{fold_id}.csv"
      )
    )

  if (
    base::file.exists(file_checkpoint)
  ) {
    return(
      readr::read_csv(
        file = file_checkpoint,
        show_col_types = FALSE
      ) |>
        dplyr::mutate(
          repeat_id = .env$repeat_id
        )
    )
  }

  cv_indices_single <-
    base::list(
      repeat_checkpoint = base::list(test_indices)
    )

  base::names(cv_indices_single[["repeat_checkpoint"]]) <-
    fold_id

  data_result <-
    run_decomposition_route_cv(
      route = route,
      inputs = diagnostic_inputs,
      cv_indices = cv_indices_single,
      fit_config = fit_config,
      verbose = TRUE
    ) |>
    dplyr::mutate(
      repeat_id = .env$repeat_id
    )

  readr::write_csv(
    x = data_result,
    file = file_checkpoint
  )

  return(data_result)
}

data_variant_metrics <-
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
              ) |>
              purrr::list_rbind()
          }
        ) |>
        purrr::list_rbind()
    }
  ) |>
  purrr::list_rbind()

diagnostic_summary <-
  summarize_decomposition_routes(
    variant_metrics = data_variant_metrics
  )

data_fold_shares <-
  diagnostic_summary |>
  purrr::chuck("data_fold_shares")

data_route_summary <-
  diagnostic_summary |>
  purrr::chuck("data_route_summary")

data_run_metadata <-
  tibble::tibble(
    experiment_id = "asia_age_minimal",
    config_active = base::Sys.getenv("R_CONFIG_ACTIVE"),
    store_path = store_path,
    resolution_id = "genus",
    n_folds = n_folds,
    n_repeats = n_repeats,
    seed_cv = seed_cv,
    iter = fit_config[["iter"]],
    sampling = fit_config[["sampling"]],
    step_size = fit_config[["step_size"]],
    device = fit_config[["device"]],
    run_completed_at = base::as.character(base::Sys.time())
  )


#----------------------------------------------------------#
# 4. Write outputs -----
#----------------------------------------------------------#

file_run_metadata <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_run_metadata.csv"
  )

file_variant_metrics <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_variant_metrics.csv"
  )

file_fold_shares <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_fold_shares.csv"
  )

file_route_summary <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_route_summary.csv"
  )

file_full_loss_comparison <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_full_loss_comparison.csv"
  )

file_z_route_comparison <-
  base::file.path(
    path_temp,
    "asia_decomposition_age_minimal_z_route_comparison.csv"
  )

file_report <-
  base::file.path(
    path_reports,
    "asia_decomposition_age_minimal_report.md"
  )

readr::write_csv(
  x = data_run_metadata,
  file = file_run_metadata
)

readr::write_csv(
  x = data_variant_metrics,
  file = file_variant_metrics
)

readr::write_csv(
  x = data_fold_shares,
  file = file_fold_shares
)

readr::write_csv(
  x = data_route_summary,
  file = file_route_summary
)

data_status_summary <-
  data_variant_metrics |>
  dplyr::count(
    .data$route_id,
    .data$status,
    name = "n_variant_fits"
  ) |>
  dplyr::arrange(
    .data$route_id,
    .data$status
  )

data_full_loss_reference <-
  data_variant_metrics |>
  dplyr::filter(
    .data$route_id == "pooled_spatiotemporal_age_current",
    .data$variant == "full"
  ) |>
  dplyr::select(
    "repeat_id",
    "fold_id",
    current_loss = "loss",
    current_status = "status"
  )

data_full_loss_comparison <-
  data_variant_metrics |>
  dplyr::filter(
    .data$route_id != "pooled_spatiotemporal_age_current",
    .data$variant == "full"
  ) |>
  dplyr::select(
    "route_id",
    "repeat_id",
    "fold_id",
    candidate_loss = "loss",
    candidate_status = "status"
  ) |>
  dplyr::left_join(
    data_full_loss_reference,
    by = dplyr::join_by(repeat_id, fold_id)
  ) |>
  dplyr::mutate(
    delta_loss_candidate_minus_current = .data$candidate_loss -
      .data$current_loss,
    pair_defined = .data$current_status == "ok" &
      .data$candidate_status == "ok" &
      base::is.finite(.data$delta_loss_candidate_minus_current),
    candidate_beats_current = .data$pair_defined &
      .data$delta_loss_candidate_minus_current < 0
  ) |>
  dplyr::group_by(.data$route_id) |>
  dplyr::summarise(
    n_pairs = dplyr::n(),
    n_defined_pairs = base::sum(
      .data$pair_defined,
      na.rm = TRUE
    ),
    n_candidate_beats_current = base::sum(
      .data$candidate_beats_current,
      na.rm = TRUE
    ),
    proportion_candidate_beats_current = base::mean(
      .data$candidate_beats_current[.data$pair_defined],
      na.rm = TRUE
    ),
    mean_delta_loss_candidate_minus_current = base::mean(
      .data$delta_loss_candidate_minus_current[.data$pair_defined],
      na.rm = TRUE
    ),
    median_delta_loss_candidate_minus_current = stats::median(
      .data$delta_loss_candidate_minus_current[.data$pair_defined],
      na.rm = TRUE
    ),
    .groups = "drop"
  )

readr::write_csv(
  x = data_full_loss_comparison,
  file = file_full_loss_comparison
)

data_z_main_reference <-
  data_variant_metrics |>
  dplyr::filter(
    .data$route_id == "pooled_spatiotemporal_age_z_main",
    .data$variant == "full"
  ) |>
  dplyr::select(
    "repeat_id",
    "fold_id",
    main_loss = "loss",
    main_status = "status"
  )

data_z_route_comparison <-
  data_variant_metrics |>
  dplyr::filter(
    .data$route_id == "pooled_spatiotemporal_age_z_interaction",
    .data$variant == "full"
  ) |>
  dplyr::select(
    "repeat_id",
    "fold_id",
    interaction_loss = "loss",
    interaction_status = "status"
  ) |>
  dplyr::left_join(
    data_z_main_reference,
    by = dplyr::join_by(repeat_id, fold_id)
  ) |>
  dplyr::mutate(
    delta_loss_interaction_minus_main = .data$interaction_loss -
      .data$main_loss,
    pair_defined = .data$interaction_status == "ok" &
      .data$main_status == "ok" &
      base::is.finite(.data$delta_loss_interaction_minus_main),
    interaction_beats_main = .data$pair_defined &
      .data$delta_loss_interaction_minus_main < 0
  ) |>
  dplyr::summarise(
    n_pairs = dplyr::n(),
    n_defined_pairs = base::sum(.data$pair_defined, na.rm = TRUE),
    n_interaction_beats_main = base::sum(
      .data$interaction_beats_main,
      na.rm = TRUE
    ),
    proportion_interaction_beats_main = base::mean(
      .data$interaction_beats_main[.data$pair_defined],
      na.rm = TRUE
    ),
    mean_delta_loss_interaction_minus_main = base::mean(
      .data$delta_loss_interaction_minus_main[.data$pair_defined],
      na.rm = TRUE
    ),
    median_delta_loss_interaction_minus_main = stats::median(
      .data$delta_loss_interaction_minus_main[.data$pair_defined],
      na.rm = TRUE
    )
  )

readr::write_csv(
  x = data_z_route_comparison,
  file = file_z_route_comparison
)

vec_report_lines <-
  c(
    "# Asia Decomposition Age Minimal Diagnostic",
    "",
    "This report is generated by:",
    "",
    paste0(
      "`",
      "R/03_Supplementary_analyses/_Diagnostics/",
      "age_scalling/",
      "run_asia_decomposition_age_minimal_diagnostic.R",
      "`"
    ),
    "",
    "## Run Settings",
    "",
    paste0("- Experiment: `", data_run_metadata[["experiment_id"]], "`"),
    paste0("- Folds: `", n_folds, "`"),
    paste0("- Repeats: `", n_repeats, "`"),
    paste0("- Iterations: `", fit_config[["iter"]], "`"),
    paste0("- Sampling: `", fit_config[["sampling"]], "`"),
    paste0("- Step size: `", fit_config[["step_size"]], "`"),
    paste0("- Device: `", fit_config[["device"]], "`"),
    "",
    "## Route Summary",
    "",
    utils::capture.output(
      print(
        data_route_summary,
        n = Inf
      )
    ),
    "",
    "## Variant Fit Status",
    "",
    utils::capture.output(
      print(
        data_status_summary,
        n = Inf
      )
    ),
    "",
    "## Full-Model Loss Compared With Current Route",
    "",
    utils::capture.output(
      print(
        data_full_loss_comparison,
        n = Inf
      )
    ),
    "",
    "## Z-Scored Interaction Compared With Z-Scored Main Effect",
    "",
    utils::capture.output(
      print(
        data_z_route_comparison,
        n = Inf
      )
    ),
    "",
    "## Output Tables",
    "",
    paste0("- `", file_run_metadata, "`"),
    paste0("- `", file_variant_metrics, "`"),
    paste0("- `", file_fold_shares, "`"),
    paste0("- `", file_route_summary, "`"),
    paste0("- `", file_full_loss_comparison, "`"),
    paste0("- `", file_z_route_comparison, "`")
  )

base::writeLines(
  text = vec_report_lines,
  con = file_report
)

cli::cli_inform(
  c(
    "v" = stringr::str_glue("Saved metadata: {file_run_metadata}"),
    "v" = stringr::str_glue("Saved metrics: {file_variant_metrics}"),
    "v" = stringr::str_glue("Saved shares: {file_fold_shares}"),
    "v" = stringr::str_glue("Saved summary: {file_route_summary}"),
    "v" = stringr::str_glue(
      "Saved loss comparison: {file_full_loss_comparison}"
    ),
    "v" = stringr::str_glue(
      "Saved z-route comparison: {file_z_route_comparison}"
    ),
    "v" = stringr::str_glue("Saved report: {file_report}")
  )
)

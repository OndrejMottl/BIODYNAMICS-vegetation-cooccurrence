#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#      CZ predictive decomposition age-main diagnostic
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs controlled CZ genus decomposition diagnostics that compare
#   no-age and age-main-effect abiotic formulas.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  base::suppressMessages(
    library(here)
  )
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

base::suppressWarnings(
  base::suppressMessages(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

store_path <-
  here::here("Data/targets/cz_paleo/pipeline_paleo_resolution_test")

pipeline_script <-
  "R/Pipelines/pipeline_paleo_resolution_test.R"

path_temp <-
  here::here(
    "Documentation/Reports/Diagnostics/age_scalling",
    "cz_age_main"
  )

base::dir.create(
  path = path_temp,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Run settings -----
#----------------------------------------------------------#

refresh_upstream <- FALSE
n_folds <- 5L
n_repeats <- 5L
seed_cv <- 900723L

# Optional smoke overrides. Set to NULL to use config values.
iter_override <- NULL
sampling_override <- NULL
step_size_override <- NULL
device_override <- "gpu"


#----------------------------------------------------------#
# 2. Refresh and load upstream targets -----
#----------------------------------------------------------#

data_run_metadata <-
  refresh_cz_decomposition_upstream(
    refresh_upstream = refresh_upstream,
    store_path = store_path,
    pipeline_script = pipeline_script,
    verbose = TRUE
  )

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
    n_early_stopping = config_model_fitting[["n_early_stopping"]]
  )


#----------------------------------------------------------#
# 3. Run age-main diagnostic routes -----
#----------------------------------------------------------#

data_routes <-
  tibble::tibble(
    route_id = c(
      "pooled_spatiotemporal_no_age",
      "pooled_spatiotemporal_age_main",
      "pooled_spatial_age_main"
    ),
    sample_mode = c(
      "pooled",
      "pooled",
      "pooled"
    ),
    spatial_mode = c(
      "spatiotemporal",
      "spatiotemporal",
      "spatial"
    ),
    use_age = c(
      FALSE,
      TRUE,
      TRUE
    ),
    age_formula_mode = c(
      "none",
      "main_effect",
      "main_effect"
    )
  )

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

      run_decomposition_route_cv(
        route = route_i,
        inputs = diagnostic_inputs,
        cv_indices = cv_indices,
        fit_config = fit_config,
        verbose = TRUE
      )
    }
  ) |>
  purrr::list_rbind()

diagnostic_summary <-
  summarise_decomposition_routes(
    variant_metrics = data_variant_metrics
  )

data_fold_shares <-
  diagnostic_summary |>
  purrr::chuck("data_fold_shares")

data_route_summary <-
  diagnostic_summary |>
  purrr::chuck("data_route_summary")

data_run_metadata <-
  data_run_metadata |>
  dplyr::mutate(
    experiment_id = "age_main",
    n_folds = n_folds,
    n_repeats = n_repeats,
    seed_cv = seed_cv,
    iter = fit_config[["iter"]],
    sampling = fit_config[["sampling"]],
    step_size = fit_config[["step_size"]],
    device = fit_config[["device"]]
  )


#----------------------------------------------------------#
# 4. Write outputs -----
#----------------------------------------------------------#

file_run_metadata <-
  base::file.path(
    path_temp,
    "cz_decomposition_age_main_run_metadata.csv"
  )

file_variant_metrics <-
  base::file.path(
    path_temp,
    "cz_decomposition_age_main_variant_metrics.csv"
  )

file_fold_shares <-
  base::file.path(
    path_temp,
    "cz_decomposition_age_main_fold_shares.csv"
  )

file_route_summary <-
  base::file.path(
    path_temp,
    "cz_decomposition_age_main_route_summary.csv"
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

cli::cli_inform(
  c(
    "v" = stringr::str_glue("Saved metadata: {file_run_metadata}"),
    "v" = stringr::str_glue("Saved metrics: {file_variant_metrics}"),
    "v" = stringr::str_glue("Saved shares: {file_fold_shares}"),
    "v" = stringr::str_glue("Saved summary: {file_route_summary}")
  )
)

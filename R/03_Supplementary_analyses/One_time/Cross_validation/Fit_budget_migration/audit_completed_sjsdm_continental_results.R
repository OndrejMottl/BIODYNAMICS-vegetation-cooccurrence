#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Audit completed continental sjSDM models
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Decide whether each legacy continental selection and final model may be
#   retained after independent CV-budget calibration.
# Workflow contract:
#   Requires accepted calibration evidence for every eligible continental
#   analysis, continent, and resolution combination.
#   Reads model stores without changing them and records convergence, legacy
#   budgets, and winner agreement. Missing calibration blocks the audit.
#   The resulting CSV is evidence for runner 05, not an invalidation itself.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))

#----------------------------------------------------------#
# 1. Resolve continental stores and target suffixes -----
#----------------------------------------------------------#

data_profiles <-
  tibble::tibble(
    analysis_id = base::c("paleo_spatial", "modern_spatial"),
    profile_id = base::c(
      "project_paleo_spatial_continental",
      "project_modern_spatial_continental"
    ),
    store_root = here::here(
      "Data",
      "targets",
      base::c(
        "paleo_spatial_continental",
        "modern_spatial_continental"
      )
    )
  )
data_work <-
  tidyr::crossing(
    profile_row = base::seq_len(base::nrow(data_profiles)),
    continent_id = base::c("europe", "america", "asia"),
    resolution_id = base::c("genus", "family", "functional_type")
  ) |>
  dplyr::mutate(
    analysis_id = data_profiles[["analysis_id"]][.data[["profile_row"]]],
    profile_id = data_profiles[["profile_id"]][.data[["profile_row"]]],
    target_suffix = dplyr::case_when(
      .data[["analysis_id"]] == "modern_spatial" &
        .data[["resolution_id"]] == "functional_type" ~ "ft_modern",
      .default = .data[["resolution_id"]]
    ),
    store_path = base::file.path(
      data_profiles[["store_root"]][.data[["profile_row"]]],
      .data[["continent_id"]],
      stringr::str_c(
        "pipeline_",
        .data[["analysis_id"]],
        "_resolution"
      )
    )
  )

#----------------------------------------------------------#
# 2. Inspect completed models and legacy selections -----
#----------------------------------------------------------#

list_completed <-
  data_work |>
  dplyr::rowwise() |>
  dplyr::mutate(
    list_feasibility = base::list(
      base::tryCatch(
        targets::tar_read_raw(
          name = stringr::str_c(
            "data_cross_validation_feasibility_",
            .data[["target_suffix"]]
          ),
          store = .data[["store_path"]]
        ),
        error = function(error_condition) NULL
      )
    ),
    full_model_eligible = !base::identical(
      purrr::pluck(
        .data[["list_feasibility"]],
        "cv_feasibility_status",
        1L,
        .default = NA_character_
      ),
      "full_model_infeasible"
    ),
    model_available = targets::tar_exist_objects(
      names = stringr::str_c("mod_jsdm_", .data[["target_suffix"]]),
      store = .data[["store_path"]]
    ),
    list_model = base::list(
      if (
        .data[["model_available"]]
      ) {
        base::tryCatch(
          targets::tar_read_raw(
            name = stringr::str_c(
              "mod_jsdm_",
              .data[["target_suffix"]]
            ),
            store = .data[["store_path"]]
          ),
          error = function(error_condition) NULL
        )
      } else {
        NULL
      }
    ),
    model_is_sjsdm = base::inherits(.data[["list_model"]], "sjSDM"),
    list_convergence = base::list(
      if (
        .data[["model_is_sjsdm"]]
      ) {
        base::tryCatch(
          diagnose_jsdm_convergence(.data[["list_model"]]),
          error = function(error_condition) NULL
        )
      } else {
        NULL
      }
    ),
    final_model_converged =
      purrr::pluck(
        .data[["list_convergence"]],
        "linear_trend_slope",
        .default = Inf
      ) < 0.01 &&
      purrr::pluck(
        .data[["list_convergence"]],
        "median_diff",
        .default = Inf
      ) < 1,
    list_selection = base::list(
      base::tryCatch(
        targets::tar_read_raw(
          name = stringr::str_c(
            "data_sjsdm_regularization_selection_for_fit_",
            .data[["target_suffix"]]
          ),
          store = .data[["store_path"]]
        ),
        error = function(error_condition) NULL
      )
    ),
    legacy_candidate_id = purrr::pluck(
      .data[["list_selection"]],
      "candidate_id",
      1L,
      .default = NA_character_
    ),
    list_final_config = base::list(
      base::tryCatch(
        targets::tar_read_raw(
          name = stringr::str_c(
            "config_model_fitting_",
            .data[["target_suffix"]]
          ),
          store = .data[["store_path"]]
        ),
        error = function(error_condition) NULL
      )
    ),
    legacy_cv_n_iter = purrr::pluck(
      .data[["list_final_config"]],
      "n_iter",
      .default = NA_integer_
    ),
    legacy_cv_n_sampling = purrr::pluck(
      .data[["list_final_config"]],
      "n_sampling",
      .default = NA_integer_
    ),
    final_n_iter = .data[["legacy_cv_n_iter"]],
    final_n_sampling = .data[["legacy_cv_n_sampling"]]
  ) |>
  dplyr::ungroup() |>
  dplyr::filter(.data[["full_model_eligible"]]) |>
  dplyr::select(
    "analysis_id",
    "profile_id",
    "continent_id",
    "resolution_id",
    "target_suffix",
    "store_path",
    "model_available",
    "model_is_sjsdm",
    "final_model_converged",
    "legacy_candidate_id",
    "legacy_cv_n_iter",
    "legacy_cv_n_sampling",
    "final_n_iter",
    "final_n_sampling"
  )

path_report <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget"
  )
fs::dir_create(path_report)

#----------------------------------------------------------#
# 3. Record legacy provenance -----
#----------------------------------------------------------#

readr::write_csv(
  list_completed,
  fs::path(path_report, "continental_legacy_provenance.csv"),
  na = "NA"
)

data_calibration <-
  list_completed |>
  dplyr::rowwise() |>
  dplyr::mutate(
    file_budget = here::here(
      "Documentation",
      "Reports",
      "Model_calibration",
      "sjsdm_cv_fit_budget",
      .data[["profile_id"]],
      .data[["continent_id"]],
      .data[["resolution_id"]],
      "accepted_budget.csv"
    ),
    list_budget = base::list(
      if (
        base::file.exists(.data[["file_budget"]])
      ) {
        readr::read_csv(
          .data[["file_budget"]],
          show_col_types = FALSE
        )
      } else {
        NULL
      }
    ),
    calibration_status = dplyr::if_else(
      base::is.null(.data[["list_budget"]]) ||
        base::nrow(.data[["list_budget"]]) != 1L,
      "missing",
      "accepted"
    ),
    candidate_id = purrr::pluck(
      .data[["list_budget"]],
      "candidate_id",
      1L,
      .default = NA_character_
    ),
    n_iter_initial = purrr::pluck(
      .data[["list_budget"]],
      "n_iter_initial",
      1L,
      .default = NA_integer_
    ),
    n_iter_max = purrr::pluck(
      .data[["list_budget"]],
      "n_iter_max",
      1L,
      .default = NA_integer_
    ),
    n_sampling = purrr::pluck(
      .data[["list_budget"]],
      "n_sampling",
      1L,
      .default = NA_integer_
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    "analysis_id",
    "continent_id",
    "resolution_id",
    "calibration_status",
    "candidate_id",
    "n_iter_initial",
    "n_iter_max",
    "n_sampling"
  )

#----------------------------------------------------------#
# 4. Apply calibrated retention rules -----
#----------------------------------------------------------#

if (
  base::any(data_calibration[["calibration_status"]] != "accepted")
) {
  readr::write_csv(
    data_calibration |>
      dplyr::filter(.data[["calibration_status"]] != "accepted"),
    fs::path(path_report, "continental_audit_pending_calibration.csv"),
    na = "NA"
  )
  cli::cli_abort(
    base::c(
      "Calibration runner 04 cannot audit incomplete calibration results.",
      "x" = "See continental_audit_pending_calibration.csv.",
      "1" = "Complete runner 02 for every listed representative.",
      "2" = "Run runner 03 to publish all accepted budgets.",
      "3" = "Then rerun runner 04 before building invalidations."
    )
  )
}

data_audit <-
  evaluate_sjsdm_continental_cv_retention(
    data_completed = list_completed,
    data_calibration = data_calibration
  )
readr::write_csv(
  data_audit,
  fs::path(path_report, "continental_retention_audit.csv"),
  na = "NA"
)

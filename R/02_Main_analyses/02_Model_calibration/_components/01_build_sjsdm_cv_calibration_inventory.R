#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Build sjSDM CV calibration inventory
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Inventory current cached CV inputs, select one maximum-complexity
#   time slice per temporal profile, and select calibration representatives.
# Workflow contract:
#   Prerequisite: complete stage 01 preparation for every analysis in scope.
#   Reads target metadata, CV feasibility, and historical final-fit budgets.
#   Writes inventory and representative CSVs; it does not fit models or
#   modify production configuration. Missing current evidence is fatal.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))

path_report <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget"
  )
fs::dir_create(path_report)

#----------------------------------------------------------#
# 1. Inventory spatial units -----
#----------------------------------------------------------#

data_spatial_sources <-
  tidyr::crossing(
    analysis_id = base::c("paleo_spatial", "modern_spatial"),
    resolution_id = base::c("genus", "family", "functional_type")
  ) |>
  dplyr::mutate(
    file_suffix = dplyr::if_else(
      .data[["resolution_id"]] == "functional_type",
      "ft",
      .data[["resolution_id"]]
    ),
    file_tuning = base::file.path(
      here::here(),
      "Data",
      "Input",
      "Model_tuning",
      stringr::str_c(
        "model_tuning_",
        .data[["analysis_id"]],
        "_",
        .data[["file_suffix"]],
        ".csv"
      )
    )
  )

data_spatial_units <-
  purrr::map2(
    data_spatial_sources[["file_tuning"]],
    base::seq_len(base::nrow(data_spatial_sources)),
    .f = function(file_tuning, source_row) {
      data_context <-
        data_spatial_sources[source_row, , drop = FALSE]
      readr::read_csv(file_tuning, show_col_types = FALSE) |>
        dplyr::mutate(
          analysis_id = data_context[["analysis_id"]][[1L]],
          resolution_id = data_context[["resolution_id"]][[1L]],
          tier_id = dplyr::case_when(
            .data[["scale_id"]] %in%
              base::c("europe", "america", "asia") ~ "continental",
            stringr::str_detect(.data[["scale_id"]], "_l[0-9]+$") ~
              "local",
            .default = "regional"
          ),
          continent_id = dplyr::case_when(
            .data[["scale_id"]] == "europe" |
              stringr::str_starts(.data[["scale_id"]], "eu_") ~
              "europe",
            .data[["scale_id"]] == "america" |
              stringr::str_starts(.data[["scale_id"]], "am_") ~
              "america",
            .default = "asia"
          ),
          is_temporal = FALSE
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    store_path = here::here(
      "Data",
      "targets",
      stringr::str_c(
        .data[["analysis_id"]],
        .data[["tier_id"]],
        sep = "_"
      ),
      .data[["scale_id"]],
      stringr::str_c(
        "pipeline_",
        .data[["analysis_id"]],
        "_resolution"
      )
    ),
    target_suffix = dplyr::case_when(
      .data[["analysis_id"]] == "modern_spatial" &
        .data[["resolution_id"]] == "functional_type" ~ "ft_modern",
      .default = .data[["resolution_id"]]
    )
  )

#----------------------------------------------------------#
# 2. Inventory temporal profiles -----
#----------------------------------------------------------#

data_temporal_profiles <-
  tibble::tibble(
    profile_id = base::c(
      "project_paleo_temporal_europe",
      "project_paleo_temporal_america",
      "project_paleo_temporal_asia"
    ),
    analysis_id = "paleo_temporal",
    tier_id = "continental",
    continent_id = base::c("europe", "america", "asia"),
    resolution_id = "genus",
    scale_id = continent_id,
    store_path = here::here(
      "Data",
      "targets",
      stringr::str_c("paleo_temporal_", continent_id),
      "pipeline_paleo_temporal"
    ),
    is_temporal = TRUE
  )

data_temporal_profiles <-
  purrr::pmap_dfr(
    data_temporal_profiles,
    function(
        profile_id,
        analysis_id,
        tier_id,
        continent_id,
        resolution_id,
        scale_id,
        store_path,
        is_temporal) {
      base::Sys.setenv(R_CONFIG_ACTIVE = profile_id)
      data_meta <-
        base::tryCatch(
          targets::tar_meta(store = store_path),
          error = function(error_condition) {
            tibble::tibble(name = base::character())
          }
        )
      vec_feasibility_targets <-
        data_meta[["name"]][
          stringr::str_starts(
            data_meta[["name"]],
            "data_cross_validation_feasibility_timeslice_"
          )
        ]
      data_slices <-
        purrr::map_dfr(
          vec_feasibility_targets,
          function(target_name) {
            data_feasibility <-
              base::tryCatch(
                targets::tar_read_raw(
                  name = target_name,
                  store = store_path
                ),
                error = function(error_condition) NULL
              )
            tibble::tibble(
              target_suffix = stringr::str_remove(
                target_name,
                "^data_cross_validation_feasibility_"
              ),
              n_locations = purrr::pluck(
                data_feasibility,
                "n_locations",
                1L,
                .default = NA_integer_
              ),
              n_samples = purrr::pluck(
                data_feasibility,
                "n_samples",
                1L,
                .default = NA_integer_
              ),
              n_taxa = purrr::pluck(
                data_feasibility,
                "n_taxa",
                1L,
                .default = NA_integer_
              ),
              cv_strategy = purrr::pluck(
                data_feasibility,
                "cv_strategy",
                1L,
                .default = NA_character_
              ),
              effective_folds = purrr::pluck(
                data_feasibility,
                "effective_folds",
                1L,
                .default = NA_integer_
              )
            )
          }
        )
      selected_suffix <-
        data_slices |>
        dplyr::filter(
          base::is.finite(.data[["n_locations"]]),
          base::is.finite(.data[["n_samples"]]),
          base::is.finite(.data[["n_taxa"]])
        ) |>
        dplyr::mutate(
          calibration_eligible =
            .data[["cv_strategy"]] ==
              "spatially_stratified_group_kfold" &
            .data[["effective_folds"]] >= 5L,
          complexity_score =
            .data[["n_taxa"]] *
            (.data[["n_samples"]] + .data[["n_locations"]])
        ) |>
        dplyr::arrange(
          dplyr::desc(.data[["calibration_eligible"]]),
          dplyr::desc(.data[["complexity_score"]]),
          .data[["target_suffix"]]
        ) |>
        dplyr::slice_head(n = 1L) |>
        dplyr::pull("target_suffix")
      value_early_stopping <-
        load_active_config_value(
          base::c("model_fitting", "n_early_stopping")
        )

      tibble::tibble(
        profile_id = profile_id,
        analysis_id = analysis_id,
        tier_id = tier_id,
        continent_id = continent_id,
        resolution_id = resolution_id,
        scale_id = scale_id,
        store_path = store_path,
        target_suffix = if (
          base::length(selected_suffix) == 1L
        ) {
          selected_suffix
        } else {
          NA_character_
        },
        is_temporal = is_temporal,
        n_iter = load_active_config_value(
          base::c("model_fitting", "n_iter")
        ),
        n_sampling = load_active_config_value(
          base::c("model_fitting", "n_sampling")
        ),
        n_early_stopping = if (
          base::is.null(value_early_stopping)
        ) {
          NA_integer_
        } else {
          base::as.integer(value_early_stopping)
        }
      )
    }
  )

#----------------------------------------------------------#
# 3. Read cached feasibility evidence -----
#----------------------------------------------------------#

data_units <-
  dplyr::bind_rows(
    data_spatial_units |>
      dplyr::select(
        "analysis_id",
        "tier_id",
        "continent_id",
        "resolution_id",
        "scale_id",
        "store_path",
        "target_suffix",
        "n_iter",
        "n_sampling",
        "n_early_stopping",
        "is_temporal"
      ),
    data_temporal_profiles |>
      dplyr::select(
        "analysis_id",
        "tier_id",
        "continent_id",
        "resolution_id",
        "scale_id",
        "store_path",
        "target_suffix",
        "n_iter",
        "n_sampling",
        "n_early_stopping",
        "is_temporal"
      )
  )

data_inventory <-
  data_units |>
  dplyr::rowwise() |>
  dplyr::mutate(
    target_name = stringr::str_c(
      "data_cross_validation_feasibility",
      dplyr::if_else(
        base::is.na(.data[["target_suffix"]]),
        "",
        stringr::str_c("_", .data[["target_suffix"]])
      )
    ),
    list_feasibility = base::list(
      base::tryCatch(
        targets::tar_read_raw(
          name = .data[["target_name"]],
          store = .data[["store_path"]]
        ),
        error = function(error_condition) NULL
      )
    ),
    n_locations = purrr::pluck(
      .data[["list_feasibility"]],
      "n_locations",
      1L,
      .default = NA_integer_
    ),
    n_samples = purrr::pluck(
      .data[["list_feasibility"]],
      "n_samples",
      1L,
      .default = NA_integer_
    ),
    n_taxa = purrr::pluck(
      .data[["list_feasibility"]],
      "n_taxa",
      1L,
      .default = NA_integer_
    ),
    cv_strategy = purrr::pluck(
      .data[["list_feasibility"]],
      "cv_strategy",
      1L,
      .default = NA_character_
    ),
    cv_feasibility_status = purrr::pluck(
      .data[["list_feasibility"]],
      "cv_feasibility_status",
      1L,
      .default = NA_character_
    ),
    effective_folds = purrr::pluck(
      .data[["list_feasibility"]],
      "effective_folds",
      1L,
      .default = NA_integer_
    ),
    list_target_errors = base::list(
      {
        data_errors <-
          load_targets_store_metadata(
            store_path = .data[["store_path"]],
            fields = base::c("name", "error")
          )
        if (
          base::is.null(data_errors)
        ) {
          data_errors <-
            tibble::tibble(
              name = base::character(),
              error = base::character()
            )
        }
        data_errors
      }
    ),
    list_error_classification = base::list(
      classify_sjsdm_unit_pipeline_error(.data[["list_target_errors"]])
    ),
    current_complexity_available = base::all(
      base::is.finite(
        base::c(.data[["n_locations"]], .data[["n_samples"]],
          .data[["n_taxa"]])
      )
    ),
    target_error_count =
      base::nrow(.data[["list_target_errors"]]),
    preparation_status = dplyr::case_when(
      .data[["current_complexity_available"]] ~ "prepared",
      purrr::pluck(
        .data[["list_error_classification"]],
        "status"
      ) == "expected_infeasible" ~ "expected_infeasible",
      .data[["target_error_count"]] > 0L ~ "pipeline_error",
      .default = "missing"
    ),
    preparation_reason_code = purrr::pluck(
      .data[["list_error_classification"]],
      "reason_code",
      .default = NA_character_
    ),
    preparation_observed_count = purrr::pluck(
      .data[["list_error_classification"]],
      "observed_count",
      .default = NA_integer_
    ),
    preparation_required_count = purrr::pluck(
      .data[["list_error_classification"]],
      "required_count",
      .default = NA_integer_
    ),
    preparation_error_target = purrr::pluck(
      .data[["list_error_classification"]],
      "root_target",
      .default = NA_character_
    ),
    preparation_error = purrr::pluck(
      .data[["list_error_classification"]],
      "root_error",
      .default = NA_character_
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    -"list_feasibility",
    -"list_target_errors",
    -"list_error_classification"
  )

readr::write_csv(
  data_inventory,
  fs::path(path_report, "calibration_unit_inventory.csv"),
  na = "NA"
)

#----------------------------------------------------------#
# 4. Validate and select representatives -----
#----------------------------------------------------------#

vec_blocking_statuses <-
  base::c("missing", "pipeline_error")
file_preparation_blockers <-
  fs::path(path_report, "calibration_preparation_blockers.csv")
if (
  base::any(
    data_inventory[["preparation_status"]] %in% vec_blocking_statuses
  )
) {
  data_blockers <-
    data_inventory |>
    dplyr::filter(
      .data[["preparation_status"]] %in% vec_blocking_statuses
    )
  readr::write_csv(
    data_blockers,
    file_preparation_blockers,
    na = "NA"
  )
  cli::cli_abort(
    base::c(
      "Calibration cannot start because preparation is incomplete.",
      "x" = "See calibration_preparation_blockers.csv for exact units.",
      "1" = stringr::str_c(
        "Run R/02_Main_analyses/01_Preparation/",
        "01_run_preparation.R to prepare the missing analyses."
      ),
        "2" = paste(
        "Expected infeasible units are accepted. Missing evidence and",
        "unexplained pipeline errors must be resolved."
        ),
      "3" = paste(
        "After stage 01 succeeds, rerun",
        "R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R."
      ),
      "i" = "Archived pre-trait stores are deliberately not accepted."
    )
  )
} else if (
  fs::file_exists(file_preparation_blockers)
) {
  fs::file_delete(file_preparation_blockers)
}

data_representatives <-
  data_inventory |>
  dplyr::filter(.data[["preparation_status"]] == "prepared") |>
  select_sjsdm_cv_calibration_representatives()

readr::write_csv(
  data_representatives,
  fs::path(path_report, "calibration_representatives.csv"),
  na = "NA"
)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Publish sjSDM CV fit budgets
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Publish accepted calibration budgets as one validated publication step to
#   spatial tuning tables and paleo temporal profiles.
# Workflow contract:
#   Requires accepted, timed calibration evidence for every representative
#   and a calibrated assignment for every production unit.
#   Mutates six model-tuning CSVs and the paleo temporal profile fragment;
#   it does not mutate target stores or final-model fitting budgets.
#   Regenerate and validate config.yml immediately after this script succeeds.

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
file_inventory <-
  fs::path(path_report, "calibration_unit_inventory.csv")
file_representatives <-
  fs::path(path_report, "calibration_representatives.csv")

assertthat::assert_that(
  base::file.exists(file_inventory),
  base::file.exists(file_representatives),
  msg = paste(
    "Calibration runner 03 cannot publish because runner 01 outputs are",
    "missing. Complete preparation-only production runs, then run",
    "01_build_sjsdm_cv_calibration_inventory.R before publication."
  )
)

#----------------------------------------------------------#
# 1. Load accepted calibration evidence -----
#----------------------------------------------------------#

data_units <-
  readr::read_csv(file_inventory, show_col_types = FALSE)
data_representatives <-
  readr::read_csv(file_representatives, show_col_types = FALSE)
assertthat::assert_that(
  base::all(
    base::c(
      "cv_strategy",
      "cv_feasibility_status",
      "effective_folds"
    ) %in% base::colnames(data_units)
  ),
  msg = "Rebuild the calibration inventory before publication."
)

#----------------------------------------------------------#
# 2. Assign budgets to all production units -----
#----------------------------------------------------------#

data_accepted <-
  data_representatives |>
  dplyr::rowwise() |>
  dplyr::mutate(
    profile_id = dplyr::if_else(
      .data[["is_temporal"]],
      stringr::str_c(
        "project_paleo_temporal_",
        .data[["continent_id"]]
      ),
      stringr::str_c(
        "project_",
        .data[["analysis_id"]],
        "_",
        .data[["tier_id"]]
      )
    ),
    file_result = fs::path(
      here::here("Data", "Temp", "Sjsdm_cv_calibration"),
      .data[["profile_id"]],
      .data[["scale_id"]],
      .data[["resolution_id"]],
      "calibration_result.qs"
    ),
    list_result = base::list(
      if (
        base::file.exists(.data[["file_result"]])
      ) {
        qs2::qs_read(.data[["file_result"]])
      } else {
        NULL
      }
    ),
    result_contract_version = purrr::pluck(
      .data[["list_result"]],
      "calibration_contract_version",
      .default = NA_character_
    ),
    calibration_status = dplyr::if_else(
      .data[["result_contract_version"]] ==
        "sjsdm_cv_adaptive_calibration_v3",
      purrr::pluck(
        .data[["list_result"]],
        "calibration_status",
        .default = "missing"
      ),
      "incompatible_contract",
      missing = "incompatible_contract"
    ),
    list_budget = base::list(
      purrr::pluck(
        .data[["list_result"]],
        "data_accepted_budget",
        .default = NULL
      )
    ),
    list_runtime = base::list(
      {
        data_attempts <-
          purrr::pluck(
            .data[["list_result"]],
            "data_fit_attempts",
            .default = NULL
          )
        accepted_order <-
          purrr::pluck(
            .data[["list_budget"]],
            "budget_order",
            1L,
            .default = NA_integer_
          )
        data_accepted_attempts <-
          if (
            base::is.null(data_attempts) ||
              !base::is.finite(accepted_order)
          ) {
            tibble::tibble()
          } else {
            data_attempts |>
              dplyr::filter(
                .data[["budget_order"]] == accepted_order,
                .data[["fit_status"]] == "ok"
              )
          }
        tibble::tibble(
          measured_seconds_per_fit = if (
            base::nrow(data_accepted_attempts) == 0L
          ) {
            NA_real_
          } else {
            stats::median(data_accepted_attempts[["runtime_seconds"]])
          },
          measured_seconds_per_epoch = if (
            base::nrow(data_accepted_attempts) == 0L
          ) {
            NA_real_
          } else {
            stats::median(
              data_accepted_attempts[["runtime_seconds"]] /
                data_accepted_attempts[["epochs_run"]]
            )
          }
        )
      }
    )
  ) |>
  dplyr::ungroup()

if (
  base::any(data_accepted[["calibration_status"]] != "accepted")
) {
  readr::write_csv(
    data_accepted |>
      dplyr::filter(.data[["calibration_status"]] != "accepted") |>
      dplyr::select(
        "analysis_id",
        "tier_id",
        "continent_id",
        "resolution_id",
        "scale_id",
        "selection_reason",
        "result_contract_version",
        "calibration_status",
        "file_result"
      ),
    fs::path(path_report, "budget_publication_blockers.csv"),
    na = "NA"
  )
  cli::cli_abort(
    base::c(
      "Calibration runner 03 cannot publish incomplete evidence.",
      "x" = "See budget_publication_blockers.csv for exact representatives.",
      "1" = paste(
        "Run 02_run_sjsdm_cv_fit_budget_calibration.R for every listed",
        "representative until each result is accepted."
      ),
      "2" = "Rerun this publication runner only after all blockers clear."
    )
  )
}

data_accepted_budgets <-
  data_accepted |>
  dplyr::select(
    "analysis_id",
    "tier_id",
    "continent_id",
    "resolution_id",
    "scale_id",
    "selection_reason",
    "list_budget",
    "list_runtime"
  ) |>
  tidyr::unnest(base::c("list_budget", "list_runtime"))
assertthat::assert_that(
  base::all(
    base::is.finite(
      data_accepted_budgets[["measured_seconds_per_fit"]]
    )
  ),
  base::all(
    base::is.finite(
      data_accepted_budgets[["measured_seconds_per_epoch"]]
    )
  ),
  msg = "Accepted calibrations require finite measured runtimes."
)

#----------------------------------------------------------#
# 3. Prepare spatial and temporal production updates -----
#----------------------------------------------------------#

data_assigned <-
  resolve_sjsdm_cv_calibration_budgets(
    data_units = data_units,
    data_accepted = data_accepted_budgets
  )

assertthat::assert_that(
  base::all(data_assigned[["cv_budget_status"]] == "calibrated"),
  msg = "Production budget assignment is incomplete."
)

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
    file_tuning = here::here(
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

list_spatial_tables <-
  purrr::pmap(
    data_spatial_sources,
    function(analysis_id, resolution_id, file_suffix, file_tuning) {
      data_tuning <-
        readr::read_csv(file_tuning, show_col_types = FALSE)
      data_budget <-
        data_assigned |>
        dplyr::filter(
          .data[["analysis_id"]] == .env[["analysis_id"]],
          .data[["resolution_id"]] == .env[["resolution_id"]],
          .data[["tier_id"]] != "continental" |
            .data[["analysis_id"]] != "paleo_temporal"
        ) |>
        dplyr::select(
          "scale_id",
          dplyr::starts_with("cv_n_")
        )
      data_updated <-
        data_tuning |>
        dplyr::select(-dplyr::starts_with("cv_n_")) |>
        dplyr::left_join(data_budget, by = "scale_id")

      assertthat::assert_that(
        base::nrow(data_updated) == base::nrow(data_tuning),
        !base::any(base::is.na(data_updated[["cv_n_iter_initial"]])),
        msg = stringr::str_glue(
          "Incomplete publication table for {analysis_id} {resolution_id}."
        )
      )

      return(data_updated)
    }
  )
base::names(list_spatial_tables) <-
  data_spatial_sources[["file_tuning"]]

data_temporal <-
  data_assigned |>
  dplyr::filter(.data[["analysis_id"]] == "paleo_temporal")
assertthat::assert_that(
  base::nrow(data_temporal) == 3L,
  msg = "All three temporal budgets are required for publication."
)

file_temporal <-
  here::here("Configuration", "Profiles", "Main", "Paleo", "temporal.yml")
vec_temporal_lines <-
  base::readLines(file_temporal, warn = FALSE)

for (
  temporal_row in base::seq_len(base::nrow(data_temporal))
) {
  continent_id <-
    data_temporal[["continent_id"]][[temporal_row]]
  profile_line <-
    base::grep(
      stringr::str_c("^project_paleo_temporal_", continent_id, ":$"),
      vec_temporal_lines
    )
  next_profile <-
    base::grep(
      "^project_paleo_temporal_[a-z]+:$",
      vec_temporal_lines
    )
  next_profile <-
    next_profile[next_profile > profile_line]
  block_end <-
    if (
      base::length(next_profile) == 0L
    ) {
      base::length(vec_temporal_lines)
    } else {
      next_profile[[1L]] - 1L
    }
  block_rows <-
    base::seq.int(profile_line, block_end)

  for (
    field_id in base::c(
      "n_iter_initial",
      "n_iter_max",
      "n_sampling"
    )
  ) {
    field_line <-
      block_rows[
        base::grepl(
          stringr::str_c("^        ", field_id, ":"),
          vec_temporal_lines[block_rows]
        )
      ]
    assertthat::assert_that(
      base::length(field_line) == 1L,
      msg = stringr::str_glue(
        "Could not resolve {field_id} for temporal {continent_id}."
      )
    )
    value <-
      data_temporal[[stringr::str_c("cv_", field_id)]][[temporal_row]]
    vec_temporal_lines[[field_line]] <-
      stringr::str_glue("        {field_id}: {value}")
  }

  status_line <-
    block_rows[
      base::grepl(
        "^        calibration_status:",
        vec_temporal_lines[block_rows]
      )
    ]
  assertthat::assert_that(
    base::length(status_line) == 1L,
    msg = stringr::str_glue(
      "Could not resolve calibration_status for temporal {continent_id}."
    )
  )
  vec_temporal_lines[[status_line]] <-
    "        calibration_status: \"calibrated\""
}

purrr::iwalk(
  list_spatial_tables,
  ~ readr::write_csv(.x, .y, na = "NA")
)

#----------------------------------------------------------#
# 4. Publish budgets and provenance -----
#----------------------------------------------------------#

base::writeLines(vec_temporal_lines, file_temporal, useBytes = TRUE)
readr::write_csv(
  data_assigned,
  fs::path(path_report, "assigned_production_budgets.csv"),
  na = "NA"
)

vec_unit_keys <-
  base::c(
    "analysis_id",
    "tier_id",
    "continent_id",
    "resolution_id",
    "scale_id"
  )
data_cost <-
  data_assigned |>
  dplyr::left_join(
    data_units |>
      dplyr::select(
        dplyr::all_of(vec_unit_keys),
        "cv_strategy",
        "cv_feasibility_status",
        "effective_folds"
      ),
    by = vec_unit_keys
  ) |>
  dplyr::mutate(
    scheduled_candidate_fold_fits = dplyr::case_when(
      .data[["cv_strategy"]] == "none" |
        .data[["cv_feasibility_status"]] ==
          "full_model_infeasible" ~ 0L,
      base::is.finite(.data[["effective_folds"]]) ~
        base::as.integer(.data[["effective_folds"]] * 14L),
      .default = NA_integer_
    ),
    estimated_initial_gpu_hours =
      .data[["scheduled_candidate_fold_fits"]] *
        .data[["cv_measured_seconds_per_fit"]] / 3600,
    estimated_escalation_ceiling_gpu_hours =
      .data[["scheduled_candidate_fold_fits"]] *
        .data[["cv_measured_seconds_per_epoch"]] *
        .data[["cv_n_iter_max"]] / 3600,
    estimate_scope = "regularization_tuning_only"
  )
readr::write_csv(
  data_cost,
  fs::path(path_report, "estimated_production_tuning_cost_by_unit.csv"),
  na = "NA"
)
data_cost_summary <-
  data_cost |>
  dplyr::group_by(.data[["analysis_id"]], .data[["tier_id"]]) |>
  dplyr::summarise(
    n_units = dplyr::n(),
    scheduled_candidate_fold_fits = base::sum(
      .data[["scheduled_candidate_fold_fits"]],
      na.rm = TRUE
    ),
    estimated_initial_gpu_hours = base::sum(
      .data[["estimated_initial_gpu_hours"]],
      na.rm = TRUE
    ),
    estimated_escalation_ceiling_gpu_hours = base::sum(
      .data[["estimated_escalation_ceiling_gpu_hours"]],
      na.rm = TRUE
    ),
    n_units_missing_estimate = base::sum(
      !base::is.finite(.data[["estimated_initial_gpu_hours"]])
    ),
    estimate_scope = "regularization_tuning_only",
    .groups = "drop"
  )
readr::write_csv(
  data_cost_summary,
  fs::path(path_report, "estimated_production_tuning_cost_summary.csv"),
  na = "NA"
)
readr::write_csv(
  tibble::tibble(
    commit = system2("git", base::c("rev-parse", "HEAD"), stdout = TRUE),
    published_at = base::Sys.time(),
    n_units = base::nrow(data_assigned),
    n_representatives = base::nrow(data_accepted_budgets)
  ),
  fs::path(path_report, "budget_publication_provenance.csv"),
  na = "NA"
)

cli::cli_inform(
  base::c(
    "v" = "Accepted CV fit budgets published to production inputs.",
    "i" = "Regenerate and validate config.yml before production."
  )
)

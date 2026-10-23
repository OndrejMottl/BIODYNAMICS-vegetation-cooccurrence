#' @title Run the Shared sjSDM Tuning Sequence
#' @description
#' Orchestrates isolated unit and tier stores for exhaustive or staged tuning.
#' Staged execution alternates one cumulative unit round with one tier-wide
#' survivor target, then publishes the existing final tier artifact.
#' @param unit_pipeline
#' Character scalar path to the unit pipeline script.
#' @param tuning_target_names
#' Non-empty character vector of public unit tuning-summary targets.
#' @param unit_store_suffixes
#' Optional character vector of isolated spatial-unit store suffixes. `NULL`
#' runs one non-nested unit store, as used by temporal mapped pipelines.
#' @param prebuild_interpolation
#' Logical forwarded to [run_pipeline()] for unit executions.
#' @param fresh_run
#' Logical. When true, destroys unit stores on their first round and the tier
#' store before its first aggregation. Later rounds always resume.
#' @param tuning_strategy
#' Character scalar, `"exhaustive"` or `"staged"`.
#' @param n_rounds
#' Positive integer configured repeat/tuning-round count.
#' @param run_pipeline_function
#' Injectable pipeline runner. Defaults to [run_pipeline()].
#' @param vec_allowed_profile_roles
#' Profile roles forwarded to [run_pipeline()]. Production callers should
#' retain `c("main", "smoke")`; dedicated runners authorize other roles.
#' @param vec_allowed_profile_statuses
#' Profile statuses forwarded to [run_pipeline()]. Production callers should
#' retain `"active"`.
#' @param has_tuning_evidence_function
#' Injectable fail-closed evidence checker. Defaults to
#' [has_sjsdm_tuning_evidence()].
#' @param target_store
#' Root targets-store path. Defaults to the active configuration value.
#' @param load_metadata_function
#' Injectable metadata loader used for legacy-cache recovery.
#' @param diagnose_endpoints_function,read_target_function
#' Injectable tuning-endpoint diagnostics and target reader.
#' @param invalidate_target_function
#' Injectable target invalidator used only for incompatible legacy caches.
#' @param validate_tuning_targets
#' Logical. Validate tuning artifacts after each production unit round.
#' @param cache_recovery_attempts
#' Positive integer maximum targeted legacy-cache repairs per unit and round.
#' @param validate_calibration_function
#' Injectable live calibration guard for main production profiles.
#' @param unit_target_names
#' Optional named per-unit tuning requests from verified preparation. The
#' exact store-target pairs are persisted for resolution-aware tier pooling.
#' @return
#' Invisible `NULL`. Pipeline stores contain the durable results. Unit-level
#' failures are reported and skipped; successful units continue.
#' @export
run_sjsdm_tuning_sequence <- function(
    unit_pipeline = NULL,
    tuning_target_names = NULL,
    unit_store_suffixes = NULL,
    prebuild_interpolation = FALSE,
    fresh_run = FALSE,
    tuning_strategy = NULL,
    n_rounds = NULL,
    run_pipeline_function = run_pipeline,
    vec_allowed_profile_roles = base::c("main", "smoke"),
    vec_allowed_profile_statuses = "active",
    has_tuning_evidence_function = has_sjsdm_tuning_evidence,
    target_store = load_active_config_value("target_store"),
    load_metadata_function = load_targets_store_metadata,
    diagnose_endpoints_function =
      diagnose_sjsdm_cv_preparation_endpoints,
    read_target_function = targets::tar_read_raw,
    invalidate_target_function = targets::tar_invalidate,
    validate_tuning_targets = base::identical(
      run_pipeline_function,
      run_pipeline
    ),
    cache_recovery_attempts = 8L,
    validate_calibration_function = validate_sjsdm_cv_production_calibration,
    unit_target_names = NULL) {
  assertthat::assert_that(
    base::is.character(unit_pipeline),
    base::length(unit_pipeline) == 1L,
    !base::is.na(unit_pipeline),
    base::nzchar(unit_pipeline),
    msg = "unit_pipeline must be one non-empty path."
  )

  assertthat::assert_that(
    base::is.character(tuning_target_names),
    base::length(tuning_target_names) > 0L,
    base::all(!base::is.na(tuning_target_names)),
    base::all(base::nzchar(tuning_target_names)),
    msg = "tuning_target_names must contain non-empty target names."
  )

  assertthat::assert_that(
    base::is.null(unit_store_suffixes) ||
      (
        base::is.character(unit_store_suffixes) &&
          base::length(unit_store_suffixes) > 0L &&
          base::all(!base::is.na(unit_store_suffixes)) &&
          base::all(base::nzchar(unit_store_suffixes))
      ),
    msg = "unit_store_suffixes must be NULL or non-empty strings."
  )

  assertthat::assert_that(
    base::is.logical(prebuild_interpolation),
    base::length(prebuild_interpolation) == 1L,
    !base::is.na(prebuild_interpolation),
    msg = "prebuild_interpolation must be one logical value."
  )

  assertthat::assert_that(
    base::is.logical(fresh_run),
    base::length(fresh_run) == 1L,
    !base::is.na(fresh_run),
    msg = "fresh_run must be one logical value."
  )

  assertthat::assert_that(
    base::is.character(tuning_strategy),
    base::length(tuning_strategy) == 1L,
    tuning_strategy %in% base::c("exhaustive", "staged"),
    msg = "tuning_strategy must be exhaustive or staged."
  )

  flag_valid_round_count <-
    base::is.numeric(n_rounds) &&
    base::length(n_rounds) == 1L &&
    base::is.finite(n_rounds) &&
    n_rounds >= 1L &&
    n_rounds == base::as.integer(n_rounds)

  assertthat::assert_that(
    flag_valid_round_count,
    msg = "n_rounds must be one positive integer."
  )

  assertthat::assert_that(
    base::is.function(run_pipeline_function),
    msg = "run_pipeline_function must be a function."
  )
  assertthat::assert_that(
    base::is.function(has_tuning_evidence_function),
    msg = "has_tuning_evidence_function must be a function."
  )
  assertthat::assert_that(
    base::is.character(target_store),
    base::length(target_store) == 1L,
    !base::is.na(target_store),
    base::nzchar(target_store),
    msg = "target_store must be one non-empty path."
  )
  assertthat::assert_that(
    base::is.function(load_metadata_function),
    base::is.function(diagnose_endpoints_function),
    base::is.function(read_target_function),
    base::is.function(invalidate_target_function),
    msg = "Tuning cache-recovery helpers must be functions."
  )
  assertthat::assert_that(
    base::is.logical(validate_tuning_targets),
    base::length(validate_tuning_targets) == 1L,
    !base::is.na(validate_tuning_targets),
    msg = "validate_tuning_targets must be one logical value."
  )
  assertthat::assert_that(
    base::is.numeric(cache_recovery_attempts),
    base::length(cache_recovery_attempts) == 1L,
    base::is.finite(cache_recovery_attempts),
    cache_recovery_attempts >= 1L,
    cache_recovery_attempts ==
      base::as.integer(cache_recovery_attempts),
    msg = "cache_recovery_attempts must be one positive integer."
  )
  data_round_plan <-
    build_sjsdm_tuning_round_plan(
      tuning_strategy = tuning_strategy,
      n_rounds = n_rounds
    )

  if (
    base::identical(run_pipeline_function, run_pipeline) &&
      load_active_config_value(base::c("_profile", "role")) == "main"
  ) {
    validate_calibration_function(
      profile_id = base::Sys.getenv("R_CONFIG_ACTIVE")
    )
  }

  vec_unit_store_paths <-
    build_sjsdm_tuning_store_paths(
      unit_pipeline = unit_pipeline,
      unit_store_suffixes = unit_store_suffixes,
      target_store = target_store
    )
  vec_active_store_suffixes <-
    if (
      base::is.null(unit_store_suffixes)
    ) {
      NA_character_
    } else {
      unit_store_suffixes
    }
  vec_active_store_paths <- vec_unit_store_paths

  file_unit_requests <-
    fs::path(target_store, "sjsdm_tier_unit_requests.csv")
  if (
    !base::is.null(unit_target_names) || base::file.exists(file_unit_requests)
  ) {
    assertthat::assert_that(!base::is.null(unit_store_suffixes),
      msg = "Resolution-aware requests require nested spatial stores.")
    data_unit_requests <-
      purrr::map2(unit_store_suffixes, vec_unit_store_paths, ~ {
        vec_targets <-
          if (
            base::is.null(unit_target_names)
          ) {
            tuning_target_names
          } else {
            unit_target_names[[.x]]
          }
        tibble::tibble(source_store = base::rep(here::here(.y),
          base::length(vec_targets)), target_name = vec_targets)
      }) |>
      purrr::list_rbind()
    fs::dir_create(target_store)
    readr::write_csv(data_unit_requests, file_unit_requests)
  }

  for (
    round_index in base::seq_len(base::nrow(data_round_plan))
  ) {
    round_id <-
      data_round_plan[["round_id"]][[round_index]]

    fresh_round <-
      fresh_run && round_id == 1L

    prebuild_round <-
      prebuild_interpolation && round_id == 1L

    final_round <-
      data_round_plan[["final_round"]][[round_index]]

    data_unit_status <-
      run_sjsdm_tuning_unit_round(
      round_id = round_id,
      unit_pipeline = unit_pipeline,
      tuning_target_names = tuning_target_names,
      unit_store_suffixes = if (
        base::is.null(unit_store_suffixes)
      ) {
        NULL
      } else {
        vec_active_store_suffixes
      },
      prebuild_round = prebuild_round,
      fresh_round = fresh_round,
      run_pipeline_function = run_pipeline_function,
      vec_allowed_profile_roles = vec_allowed_profile_roles,
      vec_allowed_profile_statuses = vec_allowed_profile_statuses,
      unit_target_names = unit_target_names
    )

    flag_unit_success <-
      data_unit_status[["pipeline_status"]] == "ok"
    if (
      validate_tuning_targets &&
        base::any(data_unit_status[["pipeline_status"]] == "error")
    ) {
      base::print(data_unit_status)
      cli::cli_abort("Unexplained tuning failures block tier selection.")
    }
    vec_active_store_suffixes <-
      data_unit_status[["store_suffix"]][flag_unit_success]
    vec_active_store_paths <-
      vec_active_store_paths[flag_unit_success]

    if (
      validate_tuning_targets &&
        base::length(vec_active_store_paths) > 0L
    ) {
      data_recovery_status <-
        purrr::map2(
          .x = vec_active_store_suffixes,
          .y = vec_active_store_paths,
          .f = function(store_suffix, store_path) {
            vec_unit_targets <-
              if (
                base::is.null(unit_target_names)
              ) {
                tuning_target_names
              } else {
                unit_target_names[[store_suffix]]
              }
            data_endpoints <-
              diagnose_endpoints_function(
                store_path = store_path,
                target_names = vec_unit_targets,
                load_metadata_function = load_metadata_function,
                read_target_function = read_target_function
              )
            vec_previous_targets <- base::character()

            for (
              recovery_attempt in
                base::seq_len(cache_recovery_attempts)
            ) {
              flag_legacy_cache <-
                base::any(
                  data_endpoints[["endpoint_status"]] ==
                    "cache_format_incompatible"
                )
              if (!flag_legacy_cache) {
                break
              }

              data_target_errors <-
                load_metadata_function(
                  store_path = store_path,
                  fields = base::c("name", "error", "time")
                )
              vec_invalidate_targets <-
                build_sjsdm_legacy_cache_invalidation_targets(
                  data_endpoints = data_endpoints,
                  data_target_errors = data_target_errors
                )
              flag_no_progress <-
                base::length(vec_invalidate_targets) == 0L ||
                (
                  base::length(vec_previous_targets) > 0L &&
                    base::setequal(
                      vec_invalidate_targets,
                      vec_previous_targets
                    )
                )
              if (flag_no_progress) {
                break
              }

              vec_previous_targets <- vec_invalidate_targets
              cli::cli_inform(
                base::c(
                  "!" = stringr::str_glue(
                    "Recovering unreadable tuning cache for ",
                    "{store_suffix}."
                  ),
                  "i" = stringr::str_glue(
                    "Attempt {recovery_attempt} invalidates only: ",
                    "{stringr::str_c(",
                    "vec_invalidate_targets, collapse = ', ')}"
                  )
                )
              )
              invalidate_target_function(
                names = vec_invalidate_targets,
                store = store_path
              )

              run_sjsdm_tuning_unit_round(
                round_id = round_id,
                unit_pipeline = unit_pipeline,
                tuning_target_names = vec_unit_targets,
                unit_store_suffixes = if (
                  base::is.na(store_suffix)
                ) {
                  NULL
                } else {
                  store_suffix
                },
                prebuild_round = FALSE,
                fresh_round = FALSE,
                run_pipeline_function = run_pipeline_function,
                vec_allowed_profile_roles =
                  vec_allowed_profile_roles,
                vec_allowed_profile_statuses =
                  vec_allowed_profile_statuses
              )

              data_endpoints <-
                diagnose_endpoints_function(
                  store_path = store_path,
                  target_names = vec_unit_targets,
                  load_metadata_function = load_metadata_function,
                  read_target_function = read_target_function
                )
            }

            flag_prepared <-
              base::all(
                data_endpoints[["endpoint_status"]] == "prepared"
              )
            if (!flag_prepared) {
              vec_incomplete_targets <-
                data_endpoints |>
                dplyr::filter(
                  .data[["endpoint_status"]] != "prepared"
                ) |>
                dplyr::pull("target_name")
              cli::cli_inform(
                base::c(
                  "!" = stringr::str_glue(
                    "Skipping incomplete tuning unit {store_suffix}."
                  ),
                  "x" = stringr::str_glue(
                    "Unreadable targets: {stringr::str_c(",
                    "vec_incomplete_targets, collapse = ', ')}"
                  ),
                  "i" = "Tuning will continue with the next unit."
                )
              )
            }

            tibble::tibble(
              store_suffix = store_suffix,
              store_path = store_path,
              tuning_targets_ready = flag_prepared
            )
          }
        ) |>
        purrr::list_rbind()

      vec_active_store_suffixes <-
        data_recovery_status[["store_suffix"]][
          data_recovery_status[["tuning_targets_ready"]]
        ]
      vec_active_store_paths <-
        data_recovery_status[["store_path"]][
          data_recovery_status[["tuning_targets_ready"]]
        ]
      if (
        base::any(!data_recovery_status[["tuning_targets_ready"]])
      ) {
        cli::cli_abort("Incomplete tuning evidence blocks tier selection.")
      }
    }

    if (
      base::length(vec_active_store_paths) == 0L
    ) {
      cli::cli_warn(
        base::c(
          "No unit completed the current tuning round.",
          "i" = "Errors were logged; no tier selection was attempted."
        )
      )
      return(base::invisible(NULL))
    }

    flag_has_tuning_evidence <-
      if (
        base::is.null(unit_target_names)
      ) {
        has_tuning_evidence_function(store_paths = vec_active_store_paths,
          target_names = tuning_target_names)
      } else {
        purrr::map2_lgl(vec_active_store_paths, vec_active_store_suffixes,
          ~ has_tuning_evidence_function(store_paths = .x,
            target_names = unit_target_names[[.y]])) |>
          base::any()
      }

    assertthat::assert_that(
      base::is.logical(flag_has_tuning_evidence),
      base::length(flag_has_tuning_evidence) == 1L,
      !base::is.na(flag_has_tuning_evidence),
      msg = stringr::str_c(
        "has_tuning_evidence_function must return one ",
        "non-missing logical value."
      )
    )

    if (
      !flag_has_tuning_evidence
    ) {
      return(base::invisible(NULL))
    }

    run_sjsdm_tuning_tier_round(
      tuning_strategy = tuning_strategy,
      tier_target_name =
        data_round_plan[["tier_target_name"]][[round_index]],
      fresh_round = fresh_round,
      final_round = final_round,
      run_pipeline_function = run_pipeline_function,
      vec_allowed_profile_roles = vec_allowed_profile_roles,
      vec_allowed_profile_statuses = vec_allowed_profile_statuses,
      unit_store_suffixes = if (
        base::is.null(unit_store_suffixes)
      ) {
        NULL
      } else {
        vec_active_store_suffixes
      }
    )
  }

  return(base::invisible(NULL))
}

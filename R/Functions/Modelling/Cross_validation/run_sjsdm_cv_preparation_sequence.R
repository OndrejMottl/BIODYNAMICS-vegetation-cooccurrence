#' @title Run the sjSDM Cross-Validation Preparation Sequence
#' @description
#' Builds selected cross-validation preparation targets in isolated unit stores
#' without requesting tuning fits or final models.
#' @param unit_pipeline
#' Character scalar path to the production unit pipeline.
#' @param preparation_target_names
#' Non-empty character vector of prepared-fold target names.
#' @param unit_store_suffixes
#' Optional character vector of spatial-unit store suffixes. `NULL` runs the
#' non-nested store used by a temporal profile.
#' @param prebuild_interpolation
#' Logical forwarded to [run_pipeline()] for each unit execution.
#' @param preparation_resource_profile
#' Runtime resource profile forwarded to [run_pipeline()].
#' @param interpolation_workers_override
#' Optional explicit positive interpolation worker count.
#' @param run_pipeline_function
#' Injectable pipeline runner. Defaults to [run_pipeline()].
#' @param target_store
#' Root target-store path used to inspect unit-level target errors.
#' @param resolve_store_function
#' Injectable unit-store path resolver.
#' @param load_metadata_function,classify_error_function
#' Injectable target-metadata loader and unit-error classifier.
#' @param diagnose_endpoints_function
#' Injectable prepared-endpoint diagnostic.
#' @param read_target_function
#' Injectable raw target reader used by endpoint validation.
#' @param invalidate_target_function
#' Injectable target invalidator used for legacy-cache recovery.
#' @param validate_endpoints
#' Logical. If `TRUE`, require every requested endpoint to have successful,
#' hashed metadata and to be readable. Defaults to `TRUE` for the production
#' pipeline runner and `FALSE` for injected test runners.
#' @param cache_recovery_attempts
#' Non-negative integer maximum number of targeted legacy-cache retries.
#' @return
#' Invisibly, a unit-status tibble. Prepared targets remain cached in
#' production stores.
#' @details
#' This function is used only when a main-analysis runner is explicitly placed
#' in CV-fold preparation mode. A target-level failure in one spatial unit or
#' temporal store is recorded so all remaining independent work can be
#' attempted. Expected infeasibility is accepted. Unexplained target failures
#' and per-unit runner failures without fresh target metadata are reported
#' after all spatial units have been attempted. This guarantees maximum unit
#' coverage while keeping unexpected outcomes visible at component exit.
#' Legacy-cache recovery follows all affected targets and dependencies visible
#' in metadata, but stops for registered data limitations or when an
#' invalidation makes no progress. Final unexplained-error output is grouped
#' once per unit.
#' @export
run_sjsdm_cv_preparation_sequence <- function(
    unit_pipeline = NULL,
    preparation_target_names = NULL,
    unit_store_suffixes = NULL,
    prebuild_interpolation = FALSE,
    preparation_resource_profile = "shared",
    interpolation_workers_override = NULL,
    run_pipeline_function = run_pipeline,
    target_store = load_active_config_value("target_store"),
    resolve_store_function = resolve_pipeline_store_path,
    load_metadata_function = load_targets_store_metadata,
    classify_error_function = classify_sjsdm_unit_pipeline_error,
    diagnose_endpoints_function =
      diagnose_sjsdm_cv_preparation_endpoints,
    read_target_function = targets::tar_read_raw,
    invalidate_target_function = targets::tar_invalidate,
    validate_endpoints = base::identical(
      run_pipeline_function,
      run_pipeline
    ),
    cache_recovery_attempts = 8L) {
  assertthat::assert_that(
    base::is.character(unit_pipeline),
    base::length(unit_pipeline) == 1L,
    !base::is.na(unit_pipeline),
    base::nzchar(unit_pipeline),
    msg = "unit_pipeline must be one non-empty path."
  )
  assertthat::assert_that(
    base::is.character(preparation_target_names),
    base::length(preparation_target_names) > 0L,
    base::all(!base::is.na(preparation_target_names)),
    base::all(base::nzchar(preparation_target_names)),
    !base::any(base::duplicated(preparation_target_names)),
    msg = "preparation_target_names must be unique non-empty names."
  )
  assertthat::assert_that(
    base::is.null(unit_store_suffixes) ||
      (
        base::is.character(unit_store_suffixes) &&
          base::length(unit_store_suffixes) > 0L &&
          base::all(!base::is.na(unit_store_suffixes)) &&
          base::all(base::nzchar(unit_store_suffixes)) &&
          !base::any(base::duplicated(unit_store_suffixes))
      ),
    msg = "unit_store_suffixes must be NULL or unique non-empty names."
  )
  assertthat::assert_that(
    assertthat::is.flag(prebuild_interpolation),
    msg = "prebuild_interpolation must be TRUE or FALSE."
  )
  assertthat::assert_that(
    base::is.function(run_pipeline_function),
    msg = "run_pipeline_function must be a function."
  )
  assertthat::assert_that(
    base::is.character(target_store),
    base::length(target_store) == 1L,
    !base::is.na(target_store),
    base::nzchar(target_store),
    msg = "target_store must be one non-empty path."
  )
  assertthat::assert_that(
    base::is.function(resolve_store_function),
    base::is.function(load_metadata_function),
    base::is.function(classify_error_function),
    base::is.function(diagnose_endpoints_function),
    base::is.function(read_target_function),
    base::is.function(invalidate_target_function),
    msg = paste(
      "Store resolution, metadata loading, endpoint diagnosis, target",
      "reading, invalidation, and error classification must use functions."
    )
  )
  assertthat::assert_that(
    assertthat::is.flag(validate_endpoints),
    base::is.numeric(cache_recovery_attempts),
    base::length(cache_recovery_attempts) == 1L,
    base::is.finite(cache_recovery_attempts),
    cache_recovery_attempts >= 0L,
    cache_recovery_attempts == base::as.integer(cache_recovery_attempts),
    msg = paste(
      "validate_endpoints must be logical and cache_recovery_attempts",
      "must be one non-negative integer."
    )
  )
  cache_recovery_attempts <-
    base::as.integer(cache_recovery_attempts)

  if (
    base::is.null(unit_store_suffixes)
  ) {
    store_path <-
      resolve_store_function(
        pipeline_script = here::here(unit_pipeline),
        target_store = target_store,
        store_suffix = NULL
      )
    data_errors_before <-
      load_metadata_function(
        store_path = store_path,
        fields = base::c("name", "error", "time")
      )
    if (
      base::is.null(data_errors_before)
    ) {
      data_errors_before <-
        tibble::tibble(
          name = base::character(),
          error = base::character(),
          time = base::as.POSIXct(base::character())
        )
    }

    error_condition <-
      base::tryCatch(
        expr = {
          run_pipeline_function(
            sel_script = unit_pipeline,
            target_names = preparation_target_names,
            plot_progress = FALSE,
            prebuild_interpolation = prebuild_interpolation,
            preparation_resource_profile =
              preparation_resource_profile,
            interpolation_workers_override =
              interpolation_workers_override
          )
          NULL
        },
        error = function(error_captured) error_captured
      )

    data_endpoints <-
      if (
        validate_endpoints
      ) {
        diagnose_endpoints_function(
          store_path = store_path,
          target_names = preparation_target_names,
          load_metadata_function = load_metadata_function,
          read_target_function = read_target_function
        )
      } else {
        tibble::tibble(
          target_name = preparation_target_names,
          endpoint_status = if (
            base::is.null(error_condition)
          ) {
            "prepared"
          } else {
            "missing"
          },
          data_hash = NA_character_,
          error_message = NA_character_
        )
      }

    vec_previous_invalidation_targets <- base::character()
    for (
      recovery_attempt in base::seq_len(cache_recovery_attempts)
    ) {
      flag_legacy_cache <-
        base::any(
          data_endpoints[["endpoint_status"]] ==
            "cache_format_incompatible"
        )
      if (
        !validate_endpoints || !flag_legacy_cache
      ) {
        break
      }
      data_cache_errors <-
        load_metadata_function(
          store_path = store_path,
          fields = base::c("name", "error", "time")
        )
      list_cache_classification <-
        if (
          base::is.data.frame(data_cache_errors)
        ) {
          classify_sjsdm_previous_preparation_error(
            data_target_errors = data_cache_errors,
            classify_error_function = classify_error_function
          )
        } else {
          NULL
        }
      if (
        base::identical(
          list_cache_classification[["status"]],
          "expected_infeasible"
        )
      ) {
        cli::cli_inform(
          base::c(
            "!" = paste(
              "Skipping legacy-cache recovery because a current",
              "expected data limitation blocks the endpoint."
            )
          )
        )
        break
      }
      vec_invalidate_targets <-
        build_sjsdm_legacy_cache_invalidation_targets(
          data_endpoints = data_endpoints,
          data_target_errors = data_cache_errors
        )
      if (
        base::length(vec_invalidate_targets) == 0L
      ) {
        break
      }
      if (
        base::length(vec_previous_invalidation_targets) > 0L &&
          base::setequal(
            vec_invalidate_targets,
            vec_previous_invalidation_targets
          )
      ) {
        cli::cli_inform(
          base::c(
            "!" = paste(
              "Stopping legacy-cache recovery because the previous",
              "invalidation made no progress."
            )
          )
        )
        break
      }
      vec_previous_invalidation_targets <- vec_invalidate_targets
      cli::cli_inform(
        base::c(
          "!" = "Recovering unreadable legacy target cache.",
          "i" = stringr::str_glue(
            "Attempt {recovery_attempt} invalidates only: ",
            "{stringr::str_c(vec_invalidate_targets, collapse = ', ')}"
          )
        )
      )
      invalidate_target_function(
        names = vec_invalidate_targets,
        store = store_path
      )
      error_condition <-
        base::tryCatch(
          expr = {
            run_pipeline_function(
              sel_script = unit_pipeline,
              target_names = preparation_target_names,
              plot_progress = FALSE,
              prebuild_interpolation = prebuild_interpolation,
              preparation_resource_profile =
                preparation_resource_profile,
              interpolation_workers_override =
                interpolation_workers_override
            )
            NULL
          },
          error = function(error_captured) error_captured
        )
      data_endpoints <-
        diagnose_endpoints_function(
          store_path = store_path,
          target_names = preparation_target_names,
          load_metadata_function = load_metadata_function,
          read_target_function = read_target_function
        )
    }

    flag_endpoints_prepared <-
      base::all(data_endpoints[["endpoint_status"]] == "prepared")
    if (
      base::is.null(error_condition) && !flag_endpoints_prepared
    ) {
      vec_incomplete_targets <-
        data_endpoints |>
        dplyr::filter(.data[["endpoint_status"]] != "prepared") |>
        dplyr::pull("target_name")
      error_condition <-
        base::simpleError(
          stringr::str_glue(
            "Requested preparation endpoints are incomplete: ",
            "{stringr::str_c(vec_incomplete_targets, collapse = ', ')}"
          )
        )
    }

    if (
      base::is.null(error_condition)
    ) {
      data_status <-
        data_endpoints |>
        dplyr::transmute(
          scale_id = NA_character_,
          target_name = .data[["target_name"]],
          preparation_status = .data[["endpoint_status"]],
          reason_code = NA_character_,
          observed_count = NA_integer_,
          required_count = NA_integer_,
          root_target = NA_character_,
          data_hash = .data[["data_hash"]],
          error_message = .data[["error_message"]]
        )
    } else {
      data_errors_after <-
        load_metadata_function(
          store_path = store_path,
          fields = base::c("name", "error", "time")
        )
      if (
        base::is.null(data_errors_after)
      ) {
        data_errors_after <-
          tibble::tibble(
            name = base::character(),
            error = base::character(),
            time = base::as.POSIXct(base::character())
          )
      }
      data_new_errors <-
        extract_new_target_errors(
          data_errors_before = data_errors_before,
          data_errors_after = data_errors_after
        )

      list_previous_classification <-
        if (
          base::nrow(data_errors_after) > 0L
        ) {
          classify_sjsdm_previous_preparation_error(
            data_target_errors = data_errors_after,
            data_new_errors = data_new_errors,
            classify_error_function = classify_error_function
          )
        } else {
          NULL
        }
      list_classification <-
        if (
          base::nrow(data_new_errors) > 0L
        ) {
          list_previous_classification
        } else {
          NULL
        }

      if (
        base::nrow(data_new_errors) == 0L
      ) {
        error_message <-
          base::conditionMessage(error_condition)
        previous_root_error <-
          purrr::pluck(
            list_previous_classification,
            "root_error",
            .default = NA_character_
          )
        previous_root_prefix <-
          stringr::str_extract(
            previous_root_error,
            "^[^.]+[.]"
          )
        flag_condition_matches_previous_root <-
          !base::is.na(previous_root_prefix) &&
          stringr::str_detect(
            error_message,
            stringr::fixed(previous_root_prefix)
          )
        flag_repeated_expected_infeasibility <-
          flag_condition_matches_previous_root &&
          base::identical(
            purrr::pluck(
              list_previous_classification,
              "status",
              .default = NA_character_
            ),
            "expected_infeasible"
          )

        if (
          flag_repeated_expected_infeasibility
        ) {
          list_classification <-
            list_previous_classification
        } else {
          vec_incomplete_targets <-
            data_endpoints |>
            dplyr::filter(
              .data[["endpoint_status"]] != "prepared"
            ) |>
            dplyr::pull("target_name")
          list_classification <-
            base::list(
              status = "unexpected_error",
              reason_code = NA_character_,
              observed_count = NA_integer_,
              required_count = NA_integer_,
              root_target = dplyr::first(
                vec_incomplete_targets,
                default = data_endpoints[["target_name"]][[1L]]
              ),
              root_error = error_message
            )
        }
      }

      if (
        base::is.null(list_classification)
      ) {
        list_classification <-
          classify_error_function(data_new_errors)
      }
      preparation_status <-
        list_classification[["status"]]
      cli::cli_inform(
        base::c(
          "!" = paste(
            "Skipping failed non-nested preparation component."
          ),
          "x" = stringr::str_glue(
            "{list_classification[['root_target']]}: ",
            "{list_classification[['root_error']]}"
          ),
          "i" = stringr::str_glue(
            "Recorded status: {preparation_status}."
          ),
          "i" = stringr::str_glue(
            "Reason code: {list_classification[['reason_code']]}"
          ),
          "i" = paste(
            "Preparation will retain completed targets and allow the",
            "stage to continue."
          )
        )
      )
      data_status <-
        data_endpoints |>
        dplyr::transmute(
          scale_id = NA_character_,
          target_name = .data[["target_name"]],
          preparation_status = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            "prepared",
            .env[["preparation_status"]]
          ),
          reason_code = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            NA_character_,
            base::ifelse(
              .data[["endpoint_status"]] ==
                "cache_format_incompatible" &
                !base::identical(
                  .env[["list_classification"]][["status"]],
                  "expected_infeasible"
                ),
              "cache_format_incompatible",
              .env[["list_classification"]][["reason_code"]]
            )
          ),
          observed_count = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            NA_integer_,
            .env[["list_classification"]][["observed_count"]]
          ),
          required_count = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            NA_integer_,
            .env[["list_classification"]][["required_count"]]
          ),
          root_target = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            NA_character_,
            dplyr::coalesce(
              .env[["list_classification"]][["root_target"]],
              .data[["target_name"]]
            )
          ),
          data_hash = .data[["data_hash"]],
          error_message = base::ifelse(
            .data[["endpoint_status"]] == "prepared",
            NA_character_,
            dplyr::coalesce(
              .data[["error_message"]],
              .env[["list_classification"]][["root_error"]]
            )
          )
        )
    }
  } else {
    data_status <-
      unit_store_suffixes |>
      purrr::map(
        .f = function(unit_store_suffix) {
          store_path <-
            resolve_store_function(
              pipeline_script = here::here(unit_pipeline),
              target_store = target_store,
              store_suffix = unit_store_suffix
            )
          data_errors_before <-
            load_metadata_function(
              store_path = store_path,
              fields = base::c("name", "error", "time")
            )
          if (
            base::is.null(data_errors_before)
          ) {
            data_errors_before <-
              tibble::tibble(
                name = base::character(),
                error = base::character(),
                time = base::as.POSIXct(base::character())
              )
          }

          error_condition <-
            base::tryCatch(
              expr = {
                run_pipeline_function(
                  sel_script = unit_pipeline,
                  store_suffix = unit_store_suffix,
                  target_names = preparation_target_names,
                  plot_progress = FALSE,
                  prebuild_interpolation = prebuild_interpolation,
                  preparation_resource_profile =
                    preparation_resource_profile,
                  interpolation_workers_override =
                    interpolation_workers_override
                )
                NULL
              },
              error = function(error_captured) error_captured
            )

          data_endpoints <-
            if (
              validate_endpoints
            ) {
              diagnose_endpoints_function(
                store_path = store_path,
                target_names = preparation_target_names,
                load_metadata_function = load_metadata_function,
                read_target_function = read_target_function
              )
            } else {
              tibble::tibble(
                target_name = preparation_target_names,
                endpoint_status = if (
                  base::is.null(error_condition)
                ) {
                  "prepared"
                } else {
                  "missing"
                },
                data_hash = NA_character_,
                error_message = NA_character_
              )
            }

          vec_previous_invalidation_targets <- base::character()
          for (
            recovery_attempt in base::seq_len(cache_recovery_attempts)
          ) {
            flag_legacy_cache <-
              base::any(
                data_endpoints[["endpoint_status"]] ==
                  "cache_format_incompatible"
              )
            if (
              !validate_endpoints || !flag_legacy_cache
            ) {
              break
            }
            data_cache_errors <-
              load_metadata_function(
                store_path = store_path,
                fields = base::c("name", "error", "time")
              )
            list_cache_classification <-
              if (
                base::is.data.frame(data_cache_errors)
              ) {
                classify_sjsdm_previous_preparation_error(
                  data_target_errors = data_cache_errors,
                  classify_error_function = classify_error_function
                )
              } else {
                NULL
              }
            if (
              base::identical(
                list_cache_classification[["status"]],
                "expected_infeasible"
              )
            ) {
              cli::cli_inform(
                base::c(
                  "!" = paste(
                    "Skipping legacy-cache recovery because a current",
                    "expected data limitation blocks the endpoint."
                  )
                )
              )
              break
            }
            vec_invalidate_targets <-
              build_sjsdm_legacy_cache_invalidation_targets(
                data_endpoints = data_endpoints,
                data_target_errors = data_cache_errors
              )
            if (
              base::length(vec_invalidate_targets) == 0L
            ) {
              break
            }
            if (
              base::length(vec_previous_invalidation_targets) > 0L &&
                base::setequal(
                  vec_invalidate_targets,
                  vec_previous_invalidation_targets
                )
            ) {
              cli::cli_inform(
                base::c(
                  "!" = paste(
                    "Stopping legacy-cache recovery because the previous",
                    "invalidation made no progress."
                  )
                )
              )
              break
            }
            vec_previous_invalidation_targets <- vec_invalidate_targets
            cli::cli_inform(
              base::c(
                "!" = stringr::str_glue(
                  "Recovering unreadable cache for {unit_store_suffix}."
                ),
                "i" = stringr::str_glue(
                  "Attempt {recovery_attempt} invalidates only: ",
                  "{stringr::str_c(
                    vec_invalidate_targets,
                    collapse = ', '
                  )}"
                )
              )
            )
            invalidate_target_function(
              names = vec_invalidate_targets,
              store = store_path
            )
            error_condition <-
              base::tryCatch(
                expr = {
                  run_pipeline_function(
                    sel_script = unit_pipeline,
                    store_suffix = unit_store_suffix,
                    target_names = preparation_target_names,
                    plot_progress = FALSE,
                    prebuild_interpolation = prebuild_interpolation,
                    preparation_resource_profile =
                      preparation_resource_profile,
                    interpolation_workers_override =
                      interpolation_workers_override
                  )
                  NULL
                },
                error = function(error_captured) error_captured
              )
            data_endpoints <-
              diagnose_endpoints_function(
                store_path = store_path,
                target_names = preparation_target_names,
                load_metadata_function = load_metadata_function,
                read_target_function = read_target_function
              )
          }

          flag_endpoints_prepared <-
            base::all(
              data_endpoints[["endpoint_status"]] == "prepared"
            )
          if (
            base::is.null(error_condition) && !flag_endpoints_prepared
          ) {
            vec_incomplete_targets <-
              data_endpoints |>
              dplyr::filter(
                .data[["endpoint_status"]] != "prepared"
              ) |>
              dplyr::pull("target_name")
            error_condition <-
              base::simpleError(
                stringr::str_glue(
                  "Requested preparation endpoints are incomplete: ",
                  "{stringr::str_c(
                    vec_incomplete_targets,
                    collapse = ', '
                  )}"
                )
              )
          }

          if (
            base::is.null(error_condition)
          ) {
            return(
              data_endpoints |>
              dplyr::transmute(
                scale_id = unit_store_suffix,
                target_name = .data[["target_name"]],
                preparation_status = .data[["endpoint_status"]],
                reason_code = NA_character_,
                observed_count = NA_integer_,
                required_count = NA_integer_,
                root_target = NA_character_,
                data_hash = .data[["data_hash"]],
                error_message = .data[["error_message"]]
              )
            )
          }

          data_errors_after <-
            load_metadata_function(
              store_path = store_path,
              fields = base::c("name", "error", "time")
            )
          if (
            base::is.null(data_errors_after)
          ) {
            data_errors_after <-
              tibble::tibble(
                name = base::character(),
                error = base::character(),
                time = base::as.POSIXct(base::character())
              )
          }
          data_new_errors <-
            extract_new_target_errors(
              data_errors_before = data_errors_before,
              data_errors_after = data_errors_after
            )
          list_previous_classification <-
            classify_sjsdm_previous_preparation_error(
              data_target_errors = data_errors_after,
              data_new_errors = data_new_errors,
              classify_error_function = classify_error_function
            )
          list_classification <-
            if (
              base::nrow(data_new_errors) > 0L
            ) {
              list_previous_classification
            } else {
              NULL
            }

          if (
            base::nrow(data_new_errors) == 0L
          ) {
            error_message <-
              base::conditionMessage(error_condition)
            flag_empty_dependency_pattern <-
              stringr::str_detect(
                error_message,
                stringr::fixed("cannot branch over empty target")
              ) &&
              base::any(
                stringr::str_detect(
                  error_message,
                  stringr::fixed(
                    base::c(
                      "list_community_interpolation_index",
                      "vec_community_taxa_checked"
                    )
                  )
                )
              )
            previous_root_error <-
              list_previous_classification[["root_error"]]
            previous_root_prefix <-
              stringr::str_extract(
                previous_root_error,
                "^[^.]+[.]"
              )
            flag_condition_matches_previous_root <-
              !base::is.na(previous_root_prefix) &&
              stringr::str_detect(
                error_message,
                stringr::fixed(previous_root_prefix)
              )
            flag_repeated_expected_infeasibility <-
              (
                flag_empty_dependency_pattern ||
                  flag_condition_matches_previous_root ||
                  stringr::str_starts(
                    error_message,
                    "Requested preparation endpoints are incomplete:"
                  )
              ) &&
              base::identical(
                list_previous_classification[["status"]],
                "expected_infeasible"
              )

            if (
              flag_repeated_expected_infeasibility
            ) {
              list_classification <-
                list_previous_classification
            } else {
              # Per-unit runner, cache, and dependency failures must not stop
              #   later spatial IDs. Preserve them as unexplained outcomes so
              #   the component can report them after every ID is attempted.
              list_classification <-
                base::list(
                  status = "unexpected_error",
                  reason_code = NA_character_,
                  observed_count = NA_integer_,
                  required_count = NA_integer_,
                  root_target =
                    list_previous_classification[["root_target"]],
                  root_error = error_message
                )
            }
          }

          if (
            base::is.null(list_classification)
          ) {
            list_classification <-
              classify_error_function(data_new_errors)
          }

          preparation_status <-
            list_classification[["status"]]

          cli::cli_inform(
            base::c(
              "!" = stringr::str_glue(
                "Skipping failed unit {unit_store_suffix}."
              ),
              "x" = stringr::str_glue(
                "{list_classification[['root_target']]}: ",
                "{list_classification[['root_error']]}"
              ),
              "i" = stringr::str_glue(
                "Recorded status: {preparation_status}."
              ),
              "i" = stringr::str_glue(
                "Reason code: {list_classification[['reason_code']]}"
              ),
              "i" = "Preparation will continue with the next unit."
            )
          )
          return(
            data_endpoints |>
            dplyr::transmute(
              scale_id = unit_store_suffix,
              target_name = .data[["target_name"]],
              preparation_status = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                "prepared",
                .env[["preparation_status"]]
              ),
              reason_code = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                NA_character_,
                base::ifelse(
                  .data[["endpoint_status"]] ==
                    "cache_format_incompatible" &
                    !base::identical(
                      .env[["list_classification"]][["status"]],
                      "expected_infeasible"
                    ),
                  "cache_format_incompatible",
                  .env[["list_classification"]][["reason_code"]]
                )
              ),
              observed_count = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                NA_integer_,
                .env[["list_classification"]][["observed_count"]]
              ),
              required_count = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                NA_integer_,
                .env[["list_classification"]][["required_count"]]
              ),
              root_target = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                NA_character_,
                dplyr::coalesce(
                  .env[["list_classification"]][["root_target"]],
                  .data[["target_name"]]
                )
              ),
              data_hash = .data[["data_hash"]],
              error_message = base::ifelse(
                .data[["endpoint_status"]] == "prepared",
                NA_character_,
                dplyr::coalesce(
                  .data[["error_message"]],
                  .env[["list_classification"]][["root_error"]]
                )
              )
            )
          )
        }
      ) |>
      purrr::list_rbind()
  }

  n_prepared <-
    base::sum(data_status[["preparation_status"]] == "prepared")
  n_expected_infeasible <-
    base::sum(
      data_status[["preparation_status"]] == "expected_infeasible"
    )
  n_other_target_errors <-
    base::sum(
      data_status[["preparation_status"]] == "unexpected_error"
    )
  cli::cli_inform(
    base::c(
      "v" = "CV-fold preparation sequence completed.",
      "i" = stringr::str_glue("Prepared endpoints: {n_prepared}."),
      "i" = stringr::str_glue(
        "Expected-infeasible endpoints: {n_expected_infeasible}."
      ),
      "i" = stringr::str_glue(
        "Unexplained endpoint errors: {n_other_target_errors}."
      )
    )
  )

  if (
    n_other_target_errors > 0L
  ) {
    data_unexpected <-
      data_status |>
      dplyr::filter(
        .data[["preparation_status"]] == "unexpected_error"
      )
    data_unexpected_units <-
      data_unexpected |>
      dplyr::mutate(
        scale_label = dplyr::coalesce(
          .data[["scale_id"]],
          "non_nested_store"
        ),
        target_label = dplyr::coalesce(
          .data[["root_target"]],
          .data[["target_name"]]
        )
      ) |>
      dplyr::group_by(.data[["scale_label"]]) |>
      dplyr::summarise(
        target_label = stringr::str_c(
          base::sort(base::unique(.data[["target_label"]])),
          collapse = ", "
        ),
        .groups = "drop"
      )
    n_unexpected_units <-
      base::nrow(data_unexpected_units)
    n_preview_units <-
      base::min(n_unexpected_units, 20L)
    vec_error_details <-
      stringr::str_glue(
        "{data_unexpected_units[['scale_label']][",
        "base::seq_len(n_preview_units)]} ",
        "[{data_unexpected_units[['target_label']][",
        "base::seq_len(n_preview_units)]}]"
      )
    cli::cli_abort(
      base::c(
        "CV-fold preparation completed with unexplained target-level errors.",
        "x" = stringr::str_c(
          n_unexpected_units,
          " affected units. First ",
          n_preview_units,
          ":\n",
          stringr::str_c(vec_error_details, collapse = "\n")
        ),
        "i" = paste(
          "Completed and expected-infeasible units remain cached.",
          "Resolve these errors, then rerun the same component."
        ),
        "i" = paste(
          "Exact messages are preserved above in the component log and",
          "in the target-store metadata."
        )
      )
    )
  }

  return(base::invisible(data_status))
}

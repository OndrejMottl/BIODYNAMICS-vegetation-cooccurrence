#' @title Run a Pipeline Interpolation Prebuild
#' @description
#' Prebuilds interpolation branches with the configured preprocessing
#' workers without invalidating completed target metadata. The active R
#' library paths are supplied to target definitions so parallel workers can
#' resolve packages from the project library reliably.
#' @param pipeline_script
#' Path to the selected targets pipeline script.
#' @param pipeline_store
#' Path to the selected targets store.
#' @param workers
#' Positive integer number of preprocessing workers.
#' @return
#' `NULL`, invisibly. The function is called for targets side effects.
#' @export
run_pipeline_interpolation_prebuild <- function(
    pipeline_script,
    pipeline_store,
    workers) {
  assertthat::assert_that(
    base::is.numeric(workers) &&
      base::length(workers) == 1L &&
      base::is.finite(workers) &&
      workers >= 1L &&
      workers == base::as.integer(workers),
    msg = "`workers` must be one positive integer."
  )

  workers <-
    base::as.integer(workers)

  previous_target_library <-
    targets::tar_option_get("library")
  base::on.exit(
    targets::tar_option_set(
      library = previous_target_library
    ),
    add = TRUE
  )
  targets::tar_option_set(
    library = base::.libPaths()
  )

  path_shared_registry <-
    base::file.path(
      pipeline_store,
      "shared_memory_registry"
    )

  vec_durable_input_targets <-
    base::c(
      "data_community_proportions",
      "data_age_uncertainty",
      "list_community_interpolation_index"
    )
  data_pipeline_manifest <-
    targets::tar_manifest(
      script = pipeline_script,
      callr_function = NULL
    )
  flag_has_durable_input_targets <-
    base::all(
      vec_durable_input_targets %in%
        data_pipeline_manifest[["name"]]
    )
  flag_has_core_count_guard <-
    "flag_available_core_count_validated" %in%
      data_pipeline_manifest[["name"]]
  vec_durable_inputs_outdated <-
    if (
      flag_has_durable_input_targets
    ) {
      targets::tar_outdated(
        names = tidyselect::all_of(vec_durable_input_targets),
        shortcut = FALSE,
        reporter = "silent",
        callr_function = NULL,
        script = pipeline_script,
        store = pipeline_store
      )
    } else {
      vec_durable_input_targets
    }
  vec_legacy_shared_paths <-
    base::file.path(
      pipeline_store,
      "objects",
      base::c(
        "data_community_proportions_shared",
        "data_age_uncertainty_shared"
      )
    )
  list_legacy_shared_reads <-
    purrr::map(
      vec_legacy_shared_paths,
      ~ base::tryCatch(
        qs2::qs_read(
          file = .x,
          validate_checksum = FALSE
        ),
        error = function(err) err
      )
    )
  flag_legacy_shared_handles <-
    base::all(base::file.exists(vec_legacy_shared_paths)) &&
    base::all(
      purrr::map_lgl(
        list_legacy_shared_reads,
        ~ base::inherits(.x, "error") &&
          base::grepl(
            pattern = "shared memory region not found",
            x = base::conditionMessage(.x),
            fixed = TRUE
          )
      )
    )
  flag_reuse_cached_branches <-
    FALSE
  path_cached_branch_recovery <-
    base::file.path(
      pipeline_store,
      "recovery",
      "interpolation_branches"
    )
  path_cache_migration_provenance <-
    base::file.path(
      pipeline_store,
      "recovery",
      "interpolation_cache_migration_v1.csv"
    )
  flag_unmigrated_complete_cache <-
    base::length(vec_durable_inputs_outdated) == 0L &&
    !base::file.exists(path_cache_migration_provenance)

  if (
    flag_unmigrated_complete_cache
  ) {
    data_pattern_meta <-
      load_targets_store_metadata(
        store_path = pipeline_store,
        fields = base::c("name", "children")
      )
    vec_current_branches <-
      data_pattern_meta |>
      dplyr::filter(
        .data[["name"]] ==
          "data_community_interpolated_dataset"
      ) |>
      dplyr::pull("children") |>
      purrr::flatten_chr()
    vec_cached_branch_paths <-
      base::file.path(
        pipeline_store,
        "objects",
        vec_current_branches
      )
    list_interpolation_index <-
      targets::tar_read_raw(
        name = "list_community_interpolation_index",
        store = pipeline_store
      )
    flag_partial_legacy_cache <-
      base::length(vec_current_branches) > 0L &&
      base::length(list_interpolation_index) !=
        base::length(vec_current_branches)
    if (
      flag_partial_legacy_cache
    ) {
      cli::cli_abort(
        base::c(
          "Legacy interpolation cache recovery is inconsistent.",
          "x" = base::paste(
            "The interpolation index and stored branch map have",
            "different lengths."
          ),
          "i" = "No interpolation branches were started."
        )
      )
    }
    vec_previous_index_hashes <-
      list_interpolation_index |>
      purrr::map_chr(
        ~ digest::digest(
          object = .x,
          algo = "xxhash64",
          serialize = TRUE
        )
      )
    vec_previous_recovery_paths <-
      stringr::str_glue(
        "{path_cached_branch_recovery}/{vec_previous_index_hashes}.qs"
      )
    flag_primary_cache_exists <-
      base::file.exists(vec_cached_branch_paths)
    vec_selected_cached_branch_paths <-
      base::ifelse(
        flag_primary_cache_exists,
        vec_cached_branch_paths,
        vec_previous_recovery_paths
      )
    flag_reuse_cached_branches <-
      base::length(vec_current_branches) > 0L &&
      base::all(base::file.exists(vec_selected_cached_branch_paths))
  }

  if (
    flag_reuse_cached_branches
  ) {
    base::dir.create(
      path = path_cached_branch_recovery,
      recursive = TRUE,
      showWarnings = FALSE
    )
    vec_branch_index_hashes <-
      list_interpolation_index |>
      purrr::map_chr(
        ~ digest::digest(
          object = purrr::chuck(.x, "dataset_name"),
          algo = "xxhash64",
          serialize = TRUE
        )
      )
    vec_recovery_branch_paths <-
      stringr::str_glue(
        "{path_cached_branch_recovery}/{vec_branch_index_hashes}.qs"
      )
    vec_copy_success <-
      base::file.copy(
        from = vec_selected_cached_branch_paths,
        to = vec_recovery_branch_paths,
        overwrite = TRUE
      )
    if (
      !base::all(vec_copy_success)
    ) {
      cli::cli_abort(
        base::c(
          "Legacy interpolation cache recovery is incomplete.",
          "x" = stringr::str_glue(
            "Could not preserve {base::sum(!vec_copy_success)} branch files."
          ),
          "i" = "No interpolation branches were started."
        )
      )
    }
    cli::cli_inform(
      base::c(
        "i" = stringr::str_glue(
          "Reusing {base::length(vec_current_branches)} protected ",
          "interpolation branches during the cache-format migration."
        )
      )
    )
  }

  withr::with_envvar(
    new = base::c(
      BIODYNAMICS_PREPROCESSING_WORKER = "true",
      BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
      BIODYNAMICS_PREPROCESSING_WORKERS = base::as.character(workers),
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY =
        path_shared_registry,
      BIODYNAMICS_REUSE_CACHED_INTERPOLATION_BRANCHES =
        base::tolower(base::as.character(flag_reuse_cached_branches)),
      BIODYNAMICS_CACHED_INTERPOLATION_BRANCH_DIR =
        path_cached_branch_recovery
    ),
    code = {
      if (
        flag_has_core_count_guard
      ) {
        base::tryCatch(
          targets::tar_make(
            names = tidyselect::all_of(
              "flag_available_core_count_validated"
            ),
            script = pipeline_script,
            store = pipeline_store,
            reporter = "silent",
            callr_function = NULL
          ),
          finally = targets::tar_unblock_process(
            store = pipeline_store
          )
        )
        data_core_guard_meta <-
          load_targets_store_metadata(
            store_path = pipeline_store,
            fields = base::c("name", "error")
          ) |>
          dplyr::filter(
            .data[["name"]] ==
              "flag_available_core_count_validated",
            !base::is.na(.data[["error"]]),
            base::nzchar(.data[["error"]])
          )
        if (
          base::nrow(data_core_guard_meta) > 0L
        ) {
          cli::cli_abort(
            data_core_guard_meta[["error"]][[1L]]
          )
        }
      }
      base::tryCatch(
        targets::tar_make(
          names = tidyselect::all_of("data_community_interpolated"),
          script = pipeline_script,
          store = pipeline_store,
          reporter = targets::tar_config_get("reporter_make"),
          callr_function = NULL
        ),
        finally = targets::tar_unblock_process(
          store = pipeline_store
        )
      )
    }
  )

  if (
    flag_reuse_cached_branches
  ) {
    data_durable_meta <-
      load_targets_store_metadata(
        store_path = pipeline_store,
        fields = base::c("name", "data")
      ) |>
      dplyr::filter(.data[["name"]] %in% vec_durable_input_targets) |>
      dplyr::arrange(.data[["name"]])
    data_migration_provenance <-
      tibble::tibble(
        contract_version = "interpolation_cache_migration_v1",
        migrated_at = base::format(
          base::Sys.time(),
          "%Y-%m-%dT%H:%M:%S%z"
        ),
        branch_count = base::length(vec_current_branches),
        durable_input_hash = digest::digest(
          data_durable_meta,
          algo = "xxhash64",
          serialize = TRUE
        ),
        source_branch_map_hash = digest::digest(
          vec_current_branches,
          algo = "xxhash64",
          serialize = TRUE
        ),
        legacy_shared_handles = flag_legacy_shared_handles
      )
    readr::write_csv(
      x = data_migration_provenance,
      file = path_cache_migration_provenance
    )
  }

  return(base::invisible(NULL))
}

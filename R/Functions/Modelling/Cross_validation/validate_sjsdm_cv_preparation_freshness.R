#' @title Validate Current Calibration Preparation Dependencies
#' @description
#' Blocks stale preparation without executing analytical pipeline targets.
#' @param pipeline_script,store_path
#' Current pipeline definition and its existing unit store.
#' @param target_names
#' Prepared input endpoints whose upstream dependencies must be current.
#' @param manifest_function,network_function,outdated_function
#' Injectable public targets inspection functions.
#' @param load_metadata_function
#' Injectable public cached-target metadata reader. Missing dependency records
#' block validation before shortcut inspection; analytical work is not run.
#' @param read_target_function
#' Injectable cached target reader for configuration comparisons.
#' @param verify_folds_function
#' Injectable exact in-memory proof for preparation-only code differences.
#' @param verify_mapping_function
#' Injectable exact in-memory proof for the known pure community mapper.
#' @return Invisibly, `NULL` after successful validation.
#' @details
#' Always-cued configuration commands are read-only and compared exactly with
#' cached values. Other always-cued ancestors are rejected. All remaining
#' ancestors are checked individually with shortcut inspection, avoiding the
#' false propagation of unchanged always-cued configuration into their users.
#' The two known shared-memory interpolation handles are operational wrappers;
#' their durable input ancestors are inspected instead of creating new handles.
#' Required cached dependency records are checked before shortcut inspection,
#' which cannot bootstrap newly introduced targets without metadata.
#' @examples
#' \dontrun{
#' validate_sjsdm_cv_preparation_freshness(
#'   "R/Pipelines/pipeline.R", "Data/targets/store", "prepared_folds"
#' )
#' }
#' @export
validate_sjsdm_cv_preparation_freshness <- function(
    pipeline_script,
    store_path,
    target_names,
    manifest_function = targets::tar_manifest,
    network_function = targets::tar_network,
    outdated_function = targets::tar_outdated,
    read_target_function = targets::tar_read_raw,
    verify_folds_function = is_sjsdm_cv_prepared_folds_current,
    verify_mapping_function = is_sjsdm_cv_preparation_mapping_current,
    load_metadata_function = targets::tar_meta) {
  assertthat::assert_that(
    base::is.character(pipeline_script),
    base::length(pipeline_script) == 1L,
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::is.character(target_names),
    base::length(target_names) > 0L,
    base::all(!base::is.na(target_names)),
    base::all(base::nzchar(target_names)),
    msg = "Preparation freshness requires a pipeline, store and endpoints."
  )
  data_manifest <-
    manifest_function(
      script = pipeline_script,
      fields = tidyselect::all_of(base::c("name", "command", "cue_mode")),
      callr_function = NULL
    )
  list_network <-
    network_function(
      script = pipeline_script,
      store = store_path,
      outdated = FALSE,
      callr_function = NULL
    )
  data_edges <-
    list_network[["edges"]]
  vec_ancestors <- target_names
  repeat {
    vec_expanded <-
      base::union(
        vec_ancestors,
        data_edges[["from"]][data_edges[["to"]] %in% vec_ancestors]
      )
    if (
      base::setequal(vec_expanded, vec_ancestors)
    ) {
      break
    }
    vec_ancestors <- vec_expanded
  }
  vec_missing <-
    base::setdiff(target_names, data_manifest[["name"]])
  data_ancestors <-
    data_manifest |>
    dplyr::filter(.data[["name"]] %in% vec_ancestors)
  data_always <-
    data_ancestors |>
    dplyr::filter(.data[["cue_mode"]] == "always")
  vec_operational_handles <-
    base::intersect(data_always[["name"]], base::c(
      "data_community_proportions_shared", "data_age_uncertainty_shared"
    ))
  vec_verified_handles <-
    vec_operational_handles |>
    purrr::keep(.p = function(target_name) {
      index_target <-
        base::match(target_name, data_always[["name"]])
      expression_command <-
        base::parse(text = data_always[["command"]][[index_target]])[[1L]]
      durable_name <-
        stringr::str_remove(target_name, "_shared$")
      base::is.call(expression_command) &&
        base::identical(expression_command[[1L]],
          base::as.name("build_shared_interpolation_data")) &&
        durable_name %in% data_edges[["from"]][
          data_edges[["to"]] == target_name
        ]
    })
  vec_configuration_names <-
    data_always[["name"]][
      stringr::str_starts(data_always[["name"]], "config_") |
        stringr::str_detect(data_always[["name"]],
          "^vec_cross_validation_grouped_fold_ladder(_|$)") |
        data_always[["name"]] %in% base::c(
          "path_traits_reference_store",
          "data_traits_analysis_release_fingerprint",
          "data_trait_taxonomy_fingerprint"
        )
    ]
  vec_unknown_always <-
    base::setdiff(data_always[["name"]],
      base::c(vec_configuration_names, vec_verified_handles))
  data_cached_metadata <-
    load_metadata_function(store = store_path, fields = "name")
  vec_missing_cached <-
    base::setdiff(
      base::setdiff(data_ancestors[["name"]], vec_verified_handles),
      data_cached_metadata[["name"]]
    )
  vec_configuration_changes <-
    base::character()
  environment_config <-
    base::new.env(parent = base::parent.frame())
  scale_id <-
    resolve_scale_id_from_store(store = store_path)
  environment_config[["resolve_scale_id_from_store"]] <-
    purrr::partial(resolve_scale_id_from_store, store = store_path)
  environment_config[[
    "load_model_tuning_parameter_for_scale_and_resolution"
  ]] <-
    purrr::partial(load_model_tuning_parameter_for_scale_and_resolution,
      scale_id = scale_id)
  for (
    index in base::seq_len(base::nrow(data_always))
  ) {
    target_name <-
      data_always[["name"]][[index]]
    if (
      !target_name %in% vec_configuration_names
    ) {
      next
    }
    vec_dependencies <-
      base::intersect(
        data_edges[["from"]][data_edges[["to"]] == target_name],
        data_manifest[["name"]]
      )
    # Evaluate only tracked read-only configuration expressions, never data
    #   preparation or model commands. Pipeline functions remain in scope.
    flag_same_configuration <-
      base::tryCatch(
        expr = {
          for (
            dependency_name in vec_dependencies
          ) {
            base::assign(
              x = dependency_name,
              value = read_target_function(name = dependency_name,
                store = store_path),
              envir = environment_config
            )
          }
          base::identical(
            base::eval(base::parse(text = data_always[["command"]][[index]]),
              envir = environment_config),
            read_target_function(name = target_name, store = store_path)
          )
        },
        error = function(error_condition) FALSE
      )
    if (
      !flag_same_configuration
    ) {
      vec_configuration_changes <-
        base::c(vec_configuration_changes, target_name)
    }
  }
  vec_inspected <-
    base::setdiff(data_ancestors[["name"]], data_always[["name"]])
  vec_outdated <-
    if (
      base::length(vec_missing) == 0L &&
        base::length(vec_missing_cached) == 0L &&
        base::length(vec_unknown_always) == 0L &&
        base::length(vec_configuration_changes) == 0L
    ) {
      # Shortcut checks require cached records for every selected ancestor.
      # Report missing preparation first; never bootstrap or fit in this guard.
      outdated_function(
        names = tidyselect::all_of(vec_inspected),
        shortcut = TRUE,
        reporter = "silent",
        script = pipeline_script,
        store = store_path,
        callr_function = NULL
      )
    } else {
      base::character()
    }
  # A multi-target dry run can propagate an always-cued dependency even when
  #   its value is unchanged. Inspect each reported ancestor independently so
  #   genuine file, command and global changes still block at their root.
  vec_directly_outdated <-
    if (
      base::length(vec_outdated) > 1L
    ) {
      vec_outdated |>
      purrr::keep(.p = function(target_name) {
        base::length(outdated_function(
          names = tidyselect::all_of(target_name),
          shortcut = TRUE, reporter = "silent",
          script = pipeline_script, store = store_path,
          callr_function = NULL
        )) > 0L
      })
    } else {
      vec_outdated
    }
  if (
    base::length(vec_missing) == 0L &&
      base::length(vec_unknown_always) == 0L &&
      base::length(vec_configuration_changes) == 0L &&
      base::all(stringr::str_detect(vec_directly_outdated,
        "^(list_sjsdm_prepared_tuning_folds|data_community_by_resolution)_"))
  ) {
    vec_mapping_targets <-
      vec_directly_outdated[stringr::str_starts(vec_directly_outdated,
        "data_community_by_resolution_")]
    vec_verified_mapping <-
      vec_mapping_targets |>
      purrr::keep(.p = function(target_name) {
        index_target <-
          base::match(target_name, data_manifest[["name"]])
        verify_mapping_function(store_path = store_path,
          target_name = target_name,
          command = data_manifest[["command"]][[index_target]])
      })
    vec_directly_outdated <-
      base::setdiff(vec_directly_outdated, vec_verified_mapping)
  }
  if (
    base::length(vec_missing) == 0L &&
      base::length(vec_unknown_always) == 0L &&
      base::length(vec_configuration_changes) == 0L &&
      base::length(vec_directly_outdated) > 0L &&
      base::all(stringr::str_detect(vec_directly_outdated,
        "^list_sjsdm_prepared_tuning_folds(_|$)"))
  ) {
    vec_verified_folds <-
      vec_directly_outdated |>
      purrr::keep(.p = ~ verify_folds_function(
        store_path = store_path, target_name = .x
      ))
    vec_directly_outdated <-
      base::setdiff(vec_directly_outdated, vec_verified_folds)
  }
  vec_blockers <-
    base::unique(base::c(vec_missing, vec_missing_cached, vec_unknown_always,
      vec_configuration_changes, vec_directly_outdated))
  if (
    base::length(vec_blockers) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Calibration is blocked by stale or missing preparation.",
        "x" = "Store: {store_path}",
        "x" = "Targets: {stringr::str_c(vec_blockers, collapse = ', ')}",
        "i" = "Unverified always-cued work: {vec_unknown_always}",
        "i" = "First rerun the appropriate stage 01 component, or:",
        "i" = stringr::str_c(
          "Rscript R/02_Main_analyses/01_Preparation/",
          "01_run_preparation.R"
        ),
        "i" = "No preparation or model targets were executed by this guard."
      )
    )
  }
  return(base::invisible(NULL))
}

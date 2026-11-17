#' @title Diagnose Freshness of One Model Targets Store
#' @description
#' Lists the targets of one existing store that would rerun under the current
#' code and configuration, without building any target.
#' @param pipeline_script
#' Path to the pipeline definition that owns the store.
#' @param store_path
#' Path to the targets store.
#' @param profile_id
#' Configuration profile used to define the pipeline (`R_CONFIG_ACTIVE`).
#' @param data_manifest
#' Optional manifest with `name`, `command`, and `cue_mode` columns. When
#' `NULL` it is read with `manifest_function`. Pass a cached manifest to
#' inspect many stores of one pipeline and profile cheaply.
#' @param data_edges
#' Optional target-only network edges with `from` and `to` columns. When
#' `NULL` they are read with `network_function`.
#' @param manifest_function,network_function,outdated_function
#' Injectable `{targets}` inspection functions.
#' @param read_target_function
#' Injectable cached-target reader used for configuration comparisons.
#' @param load_metadata_function
#' Injectable metadata reader returning `name` and `error` columns.
#' @return
#' A tibble with columns `store_path`, `target_name`, `finding_type`,
#' `flag_blocking`, and `detail`. It has zero rows when every target is
#' current. Finding types:
#' \itemize{
#'   \item `store_missing` (not blocking): the store does not exist.
#'   \item `missing_metadata`: a pipeline target was never built.
#'   \item `config_changed`: an always-cued `config_*` target would return a
#'     different value.
#'   \item `outdated`: a target would rerun; includes targets downstream of a
#'     changed configuration or of a never-built target.
#'   \item `errored_expected` (not blocking) and `errored_unexpected`: cached
#'     errors classified with [classify_sjsdm_unit_pipeline_error()].
#'   \item `always_cued_not_evaluated` (not blocking): other always-cued
#'     targets, which `{targets}` reruns on every build by design.
#' }
#' @details
#' The method mirrors [validate_sjsdm_cv_preparation_freshness()]. Always-cued
#' `config_*` commands are re-evaluated in a private environment with the
#' store's cached dependencies, and [resolve_scale_id_from_store()] bound to
#' this store, then compared with the cached value. All other built targets
#' are checked in one `tar_outdated(shortcut = TRUE)` call, so unchanged
#' always-cued configuration does not propagate false positives, while a
#' genuinely outdated target still marks the named targets downstream of it.
#' Targets downstream of errored targets that were never built are attributed
#' to the error rather than reported as missing.
#' @seealso [load_model_store_index()], [apply_model_store_freshness_ledger()]
#' @examples
#' \dontrun{
#' diagnose_model_store_freshness(
#'   pipeline_script = "R/Pipelines/pipeline_paleo_temporal.R",
#'   store_path = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal",
#'   profile_id = "project_paleo_temporal_europe"
#' )
#' }
#' @export
diagnose_model_store_freshness <- function(
    pipeline_script,
    store_path,
    profile_id,
    data_manifest = NULL,
    data_edges = NULL,
    manifest_function = targets::tar_manifest,
    network_function = targets::tar_network,
    outdated_function = targets::tar_outdated,
    read_target_function = targets::tar_read_raw,
    load_metadata_function = targets::tar_meta) {
  assertthat::assert_that(
    assertthat::is.string(pipeline_script),
    assertthat::is.string(store_path),
    assertthat::is.string(profile_id),
    base::nzchar(profile_id),
    msg = "Supply one pipeline script, store path, and profile identifier."
  )

  if (
    !base::dir.exists(store_path)
  ) {
    res_missing <-
      tibble::tibble(
        store_path = store_path,
        target_name = NA_character_,
        finding_type = "store_missing",
        flag_blocking = FALSE,
        detail = NA_character_
      )
    return(res_missing)
  }

  withr::local_envvar(R_CONFIG_ACTIVE = profile_id)

  data_manifest_used <-
    if (
      base::is.null(data_manifest)
    ) {
      manifest_function(
        script = pipeline_script,
        fields = tidyselect::all_of(base::c("name", "command", "cue_mode")),
        callr_function = NULL
      )
    } else {
      data_manifest
    }
  data_edges_used <-
    if (
      base::is.null(data_edges)
    ) {
      list_network <-
        network_function(
          script = pipeline_script,
          store = store_path,
          targets_only = TRUE,
          outdated = FALSE,
          callr_function = NULL
        )
      list_network[["edges"]]
    } else {
      data_edges
    }

  assertthat::assert_that(
    base::all(
      base::c("name", "command", "cue_mode") %in%
        base::names(data_manifest_used)
    ),
    base::all(base::c("from", "to") %in% base::names(data_edges_used)),
    msg = "The manifest or network edges do not use the required columns."
  )

  graph_targets <-
    igraph::graph_from_data_frame(
      d = data_edges_used |>
        dplyr::select("from", "to"),
      directed = TRUE,
      vertices = base::union(
        data_manifest_used[["name"]],
        base::c(data_edges_used[["from"]], data_edges_used[["to"]])
      )
    )

  data_metadata <-
    load_metadata_function(
      store = store_path,
      fields = base::c("name", "error")
    )
  vec_cached <-
    data_metadata[["name"]]
  data_errors <-
    data_metadata |>
    dplyr::filter(
      .data[["name"]] %in% data_manifest_used[["name"]],
      !base::is.na(.data[["error"]]),
      base::nzchar(.data[["error"]])
    )

  # Targets downstream of an errored target are skipped, not built, under
  #   error = "continue"/"null"; attribute them to the error instead.
  vec_error_descendants <-
    data_errors[["name"]] |>
    purrr::map(
      .f = ~ igraph::subcomponent(graph_targets, v = .x, mode = "out") |>
        base::names()
    ) |>
    purrr::list_c(ptype = base::character()) |>
    base::unique() |>
    base::setdiff(data_errors[["name"]])
  vec_missing <-
    data_manifest_used[["name"]] |>
    base::setdiff(vec_cached) |>
    base::setdiff(vec_error_descendants)

  data_findings_errors <-
    if (
      base::nrow(data_errors) > 0L
    ) {
      list_error_class <-
        classify_sjsdm_unit_pipeline_error(
          data_target_errors = data_errors |>
            dplyr::select("name", "error")
        )
      flag_expected <-
        base::identical(list_error_class[["status"]], "expected_infeasible")
      tibble::tibble(
        store_path = store_path,
        target_name = data_errors[["name"]],
        finding_type = if (
          flag_expected
        ) {
          "errored_expected"
        } else {
          "errored_unexpected"
        },
        flag_blocking = !flag_expected,
        detail = if (
          flag_expected
        ) {
          base::as.character(list_error_class[["reason_code"]])
        } else {
          data_errors[["error"]]
        }
      )
    } else {
      NULL
    }

  data_always <-
    data_manifest_used |>
    dplyr::filter(.data[["cue_mode"]] == "always")
  vec_configuration_names <-
    data_always[["name"]][
      stringr::str_starts(data_always[["name"]], "config_")
    ] |>
    base::intersect(vec_cached)
  vec_other_always <-
    data_always[["name"]] |>
    base::setdiff(vec_configuration_names) |>
    base::setdiff(vec_missing)

  # Evaluate only tracked read-only configuration expressions, never data
  #   preparation or model commands. Store-dependent helpers are bound to the
  #   inspected store, as tar_path_store() is not set outside tar_make().
  environment_config <-
    base::new.env(parent = base::globalenv())
  scale_id <-
    resolve_scale_id_from_store(store = store_path)
  environment_config[["resolve_scale_id_from_store"]] <-
    purrr::partial(resolve_scale_id_from_store, store = store_path)
  if (
    base::exists(
      "load_model_tuning_parameter_for_scale_and_resolution",
      mode = "function"
    )
  ) {
    environment_config[[
      "load_model_tuning_parameter_for_scale_and_resolution"
    ]] <-
      purrr::partial(
        load_model_tuning_parameter_for_scale_and_resolution,
        scale_id = scale_id
      )
  }

  vec_configuration_changes <-
    vec_configuration_names |>
    purrr::keep(
      .p = function(target_name) {
        command_text <-
          data_always[["command"]][data_always[["name"]] == target_name][[1L]]
        vec_dependencies <-
          data_edges_used[["from"]][data_edges_used[["to"]] == target_name] |>
          base::intersect(data_manifest_used[["name"]])
        flag_same <-
          base::tryCatch(
            expr = {
              for (
                dependency_name in vec_dependencies
              ) {
                base::assign(
                  x = dependency_name,
                  value = read_target_function(
                    name = dependency_name,
                    store = store_path
                  ),
                  envir = environment_config
                )
              }
              base::identical(
                base::eval(
                  base::parse(text = command_text),
                  envir = environment_config
                ),
                read_target_function(name = target_name, store = store_path)
              )
            },
            error = function(error_condition) FALSE
          )
        return(!flag_same)
      }
    )

  # Shortcut inspection cannot bootstrap a target whose upstream target has
  #   no record, so everything downstream of an unbuilt target is reported
  #   as outdated directly.
  vec_missing_descendants <-
    vec_missing |>
    purrr::map(
      .f = ~ igraph::subcomponent(graph_targets, v = .x, mode = "out") |>
        base::names()
    ) |>
    purrr::list_c(ptype = base::character()) |>
    base::unique() |>
    base::intersect(data_manifest_used[["name"]]) |>
    base::setdiff(vec_missing) |>
    base::setdiff(data_always[["name"]])

  vec_inspected <-
    data_manifest_used[["name"]] |>
    base::setdiff(data_always[["name"]]) |>
    base::setdiff(vec_missing) |>
    base::setdiff(vec_missing_descendants) |>
    base::setdiff(vec_error_descendants) |>
    base::setdiff(data_errors[["name"]])

  vec_outdated_direct <-
    if (
      base::length(vec_inspected) > 0L
    ) {
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

  vec_outdated_config_descendants <-
    vec_configuration_changes |>
    purrr::map(
      .f = ~ igraph::subcomponent(graph_targets, v = .x, mode = "out") |>
        base::names()
    ) |>
    purrr::list_c(ptype = base::character()) |>
    base::unique() |>
    base::intersect(data_manifest_used[["name"]]) |>
    base::setdiff(data_always[["name"]])

  vec_outdated <-
    vec_outdated_direct |>
    base::union(vec_outdated_config_descendants) |>
    base::union(vec_missing_descendants) |>
    base::setdiff(vec_missing)

  data_findings_targets <-
    tibble::tibble(
      finding_type = base::c(
        "missing_metadata",
        "config_changed",
        "outdated",
        "always_cued_not_evaluated"
      ),
      flag_blocking = base::c(TRUE, TRUE, TRUE, FALSE),
      target_name = base::list(
        vec_missing,
        vec_configuration_changes,
        vec_outdated,
        vec_other_always
      )
    ) |>
    tidyr::unnest_longer(
      col = "target_name",
      ptype = base::character()
    ) |>
    dplyr::mutate(
      store_path = store_path,
      detail = NA_character_
    )

  res <-
    dplyr::bind_rows(
      data_findings_targets,
      data_findings_errors
    ) |>
    dplyr::select(
      "store_path",
      "target_name",
      "finding_type",
      "flag_blocking",
      "detail"
    ) |>
    dplyr::arrange(.data[["finding_type"]], .data[["target_name"]])

  return(res)
}

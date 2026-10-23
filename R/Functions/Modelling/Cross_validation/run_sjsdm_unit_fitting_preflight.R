#' @title Revalidate Spatial Unit Preparation Before Fitting
#' @description
#' Reads prepared-fold evidence per resolution and reattempts only registered
#' failed preparation roots through the canonical runner. Current input hashes
#' are checked by targets; stale metadata alone never authorizes an exclusion.
#' @param unit_pipeline,target_store
#' Pipeline script and root store path.
#' @param scale_ids,resolution_ids
#' Unique requested units and pipeline resolution suffixes.
#' @param run_pipeline_function,load_metadata_function
#' Injectable canonical runner and cached metadata loader.
#' @param diagnose_endpoints_function,read_target_function
#' Injectable endpoint checker and target reader.
#' @param verbose Logical controlling progress messages.
#' @return
#' A tibble of unit-resolution fitting statuses, reasons and root evidence.
#' Missing evidence and unexplained errors block fitting after all units have
#' been checked. Changed formerly infeasible inputs require stage 01 again.
#' @details
#' No tuning or model target is requested. Successful preparation is not
#' rebuilt by this check. A failed shared root excludes all its resolutions;
#' a resolution-specific root never excludes another resolution.
#' @examples
#' \dontrun{
#' run_sjsdm_unit_fitting_preflight(
#'   unit_pipeline = "R/Pipelines/pipeline_modern_spatial_resolution.R",
#'   target_store = "Data/targets/modern_spatial_regional",
#'   scale_ids = "eu_r005", resolution_ids = c("genus", "family")
#' )
#' }
#' @export
run_sjsdm_unit_fitting_preflight <- function(
    unit_pipeline,
    target_store,
    scale_ids,
    resolution_ids,
    run_pipeline_function = run_pipeline,
    load_metadata_function = load_targets_store_metadata,
    diagnose_endpoints_function = diagnose_sjsdm_cv_preparation_endpoints,
    read_target_function = targets::tar_read_raw,
    verbose = TRUE) {
  assertthat::assert_that(
    assertthat::is.string(unit_pipeline),
    assertthat::is.string(target_store),
    base::is.character(scale_ids), base::length(scale_ids) > 0L,
    base::all(!base::is.na(scale_ids)), base::all(base::nzchar(scale_ids)),
    !base::anyDuplicated(scale_ids),
    base::is.character(resolution_ids), base::length(resolution_ids) > 0L,
    base::all(!base::is.na(resolution_ids)),
    base::all(base::nzchar(resolution_ids)),
    !base::anyDuplicated(resolution_ids),
    assertthat::is.flag(verbose),
    base::is.function(run_pipeline_function),
    base::is.function(load_metadata_function),
    base::is.function(diagnose_endpoints_function),
    base::is.function(read_target_function),
    msg = "Fitting preflight requires unique units and resolution suffixes."
  )
  data_plan <-
    scale_ids |>
    purrr::map(.f = ~ {
      scale_id <- .x
      store_path <-
        resolve_pipeline_store_path(pipeline_script = unit_pipeline,
          target_store = target_store, store_suffix = scale_id)
      data_metadata_raw <-
        load_metadata_function(store_path = store_path,
          fields = base::c("name", "error"))
      data_metadata <-
        if (
          base::is.null(data_metadata_raw)
        ) {
          tibble::tibble(name = base::character(),
            error = base::character())
        } else {
          data_metadata_raw
        }
      data_recorded_errors <-
        data_metadata |>
        dplyr::filter(
          !base::is.na(.data[["error"]]),
          base::nzchar(.data[["error"]])
        )
      list_classifications <-
        base::seq_len(base::nrow(data_recorded_errors)) |>
        purrr::map(.f = ~ classify_sjsdm_unit_pipeline_error(
          data_target_errors = data_recorded_errors[.x, , drop = FALSE]))
      vec_expected <-
        purrr::map_lgl(list_classifications,
          ~ base::identical(.x[["status"]], "expected_infeasible"))
      data_registered_roots <-
        data_recorded_errors[vec_expected, , drop = FALSE]
      vec_known_resolutions <-
        base::unique(base::c(resolution_ids,
          "genus", "family", "functional_type", "ft_modern"))
      vec_requested_roots <-
        purrr::map_lgl(data_registered_roots[["name"]], ~ {
          base::any(stringr::str_ends(.x,
            stringr::str_c("_", resolution_ids))) ||
            !base::any(stringr::str_ends(.x,
              stringr::str_c("_", vec_known_resolutions)))
        })
      data_roots <-
        data_registered_roots[vec_requested_roots, , drop = FALSE]
      # Execute each failed root once, not its CV/model descendants. targets
      #   checks commands, globals, configuration and durable input hashes.
      list_root_results <-
        data_roots[["name"]] |>
        rlang::set_names() |>
        purrr::map(.f = ~ {
          root_target <- .x
          base::tryCatch(expr = {
            # Reuse the internal lightweight worker setup: no Python/GPU
            #   preflight is needed for a preparation-root-only request.
            withr::with_envvar(
              new = base::c(BIODYNAMICS_PREPROCESSING_WORKER = "true"),
              code = run_pipeline_function(
                sel_script = unit_pipeline,
                store_suffix = scale_id,
                target_names = root_target,
                prebuild_interpolation = FALSE,
                plot_progress = FALSE
              )
            )
            NULL
          }, error = function(error_condition) error_condition)
        })
      resolution_ids |>
        purrr::map(.f = ~ {
          resolution_id <- .x
          vec_resolution_roots <-
            stringr::str_ends(data_roots[["name"]],
              stringr::str_c("_", resolution_id))
          vec_other_roots <-
            purrr::map_lgl(data_roots[["name"]], ~ base::any(
              stringr::str_ends(.x,
                stringr::str_c("_", vec_known_resolutions))))
          data_selected_roots <-
            data_roots[vec_resolution_roots | !vec_other_roots, ,
              drop = FALSE]
          fitting_status <- "eligible"
          reason_code <- NA_character_
          root_target <- NA_character_
          error_message <- NA_character_
          if (
            base::nrow(data_selected_roots) > 0L
          ) {
            vec_confirmed <-
              purrr::map_lgl(data_selected_roots[["name"]],
                ~ base::inherits(list_root_results[[.x]],
                  "sjsdm_unit_expected_infeasible"))
            if (
              !base::all(vec_confirmed)
            ) {
              fitting_status <- "error"
              root_target <-
                data_selected_roots[["name"]][!vec_confirmed][[1L]]
              error_condition <-
                list_root_results[[root_target]]
              error_message <-
                if (
                  base::is.null(error_condition)
                ) {
                  "Formerly infeasible preparation changed; refresh evidence."
                } else {
                  base::conditionMessage(error_condition)
                }
            } else {
              data_current_roots <-
                load_metadata_function(store_path = store_path,
                  fields = base::c("name", "error")) |>
                dplyr::filter(.data[["name"]] %in%
                  data_selected_roots[["name"]])
              list_root <-
                classify_sjsdm_unit_pipeline_error(data_current_roots)
              fitting_status <-
                if (
                  base::identical(list_root[["status"]],
                    "expected_infeasible")
                ) {
                  "expected_infeasible"
                } else {
                  "error"
                }
              reason_code <-
                list_root[["reason_code"]]
              root_target <-
                list_root[["root_target"]]
              error_message <-
                if (
                  fitting_status == "error"
                ) {
                  "Current failure-root evidence could not be verified."
                } else {
                  list_root[["root_error"]]
                }
            }
          } else {
            data_endpoint <-
              diagnose_endpoints_function(store_path = store_path,
                target_names = stringr::str_c(
                  "list_sjsdm_prepared_tuning_folds_", resolution_id),
                load_metadata_function = load_metadata_function,
                read_target_function = read_target_function)
            assertthat::assert_that(
              base::nrow(data_endpoint) == 1L,
              msg = "Prepared-fold diagnosis must cover its requested endpoint."
            )
            if (
              !base::all(data_endpoint[["endpoint_status"]] == "prepared")
            ) {
              fitting_status <- "error"
              error_message <- "Prepared-fold evidence is missing/unreadable."
            }
          }
          if (
            verbose && fitting_status != "eligible"
          ) {
            cli::cli_inform(stringr::str_glue(
              "Preparation {scale_id}/{resolution_id}: {fitting_status} ",
              "({reason_code}); root {root_target}."))
          }
          tibble::tibble(scale_id = scale_id,
            resolution_id = resolution_id, fitting_status = fitting_status,
            preparation_reason_code = reason_code, root_target = root_target,
            error_message = error_message)
        }) |>
        purrr::list_rbind()
    }) |>
    purrr::list_rbind()
  data_blockers <-
    data_plan |>
    dplyr::filter(.data[["fitting_status"]] == "error")
  if (
    base::nrow(data_blockers) > 0L
  ) {
    cli::cli_abort(base::c(
      "Fitting requires resolved current preparation (stage 01).",
      "x" = stringr::str_c(stringr::str_glue(
        "{data_blockers[['scale_id']]}/",
        "{data_blockers[['resolution_id']]}: ",
        "{data_blockers[['error_message']]}"), collapse = "\n"),
      "i" = stringr::str_c("Rscript R/02_Main_analyses/01_Preparation/",
        "01_run_preparation.R"),
      "i" = "Refresh stage 02 evidence if prepared inputs changed."
    ), data_preparation_plan = data_plan)
  }
  return(data_plan)
}

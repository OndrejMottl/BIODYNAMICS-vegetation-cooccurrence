#' @title Run Common sjSDM Sensitivity When Stores Are Ready
#' @description
#' Checks every enabled tier's configured representative model store before
#' running the cross-tier common-regularization sensitivity pipeline.
#' @param profile_ids
#' Non-empty character vector of unique spatial configuration profile IDs.
#' @param pipeline_name
#' Single spatial-resolution pipeline directory name.
#' @param sensitivity_script
#' Common-regularization sensitivity pipeline script path.
#' @param config_file
#' Configuration file passed to `config_get_function`.
#' @param project_root
#' Project root used to resolve configured relative target-store paths.
#' @param config_get_function
#' Injectable configuration reader. Defaults to [config::get()].
#' @param dir_exists_function
#' Injectable directory-existence predicate. Defaults to [fs::dir_exists()].
#' @param run_pipeline_function
#' Injectable pipeline runner. Defaults to [run_pipeline()].
#' @return
#' Tibble with one row per requested profile, its representative store status,
#' and a sensitivity status of `"completed"`, `"skipped_missing_store"`, or
#' `"skipped_disabled"`.
#' @details
#' The sensitivity pipeline is an all-tier operation. It is not started unless
#' every configured representative store exists, so a standalone local runner
#' can finish without failing on absent continental or regional stores.
#' @examples
#' \dontrun{
#' run_sjsdm_cross_tier_sensitivity(
#'   profile_ids = c(
#'     "project_paleo_spatial_continental",
#'     "project_paleo_spatial_regional",
#'     "project_paleo_spatial_local"
#'   ),
#'   pipeline_name = "pipeline_paleo_spatial_resolution"
#' )
#' }
#' @export
run_sjsdm_cross_tier_sensitivity <- function(
    profile_ids = NULL,
    pipeline_name = NULL,
    sensitivity_script = base::file.path(
      "R",
      "Pipelines",
      "pipeline_sjsdm_common_regularization_sensitivity.R"
    ),
    config_file = here::here("config.yml"),
    project_root = here::here(),
    config_get_function = config::get,
    dir_exists_function = fs::dir_exists,
    run_pipeline_function = run_pipeline) {
  flag_valid_profile_ids <-
    base::is.character(profile_ids) &&
    base::length(profile_ids) > 0L &&
    base::all(!base::is.na(profile_ids)) &&
    base::all(base::nzchar(profile_ids)) &&
    !base::any(base::duplicated(profile_ids))

  assertthat::assert_that(
    flag_valid_profile_ids,
    msg = "`profile_ids` must contain unique non-empty strings."
  )

  assertthat::assert_that(
    base::is.character(pipeline_name),
    base::length(pipeline_name) == 1L,
    !base::is.na(pipeline_name),
    base::nzchar(pipeline_name),
    msg = "`pipeline_name` must be one non-empty string."
  )

  assertthat::assert_that(
    base::is.character(sensitivity_script),
    base::length(sensitivity_script) == 1L,
    !base::is.na(sensitivity_script),
    base::nzchar(sensitivity_script),
    msg = "`sensitivity_script` must be one non-empty string."
  )

  assertthat::assert_that(
    base::is.character(config_file),
    base::length(config_file) == 1L,
    base::nzchar(config_file),
    base::is.character(project_root),
    base::length(project_root) == 1L,
    base::nzchar(project_root),
    msg = "Configuration and project paths must be non-empty strings."
  )

  assertthat::assert_that(
    base::is.function(config_get_function),
    base::is.function(dir_exists_function),
    base::is.function(run_pipeline_function),
    msg = "Common-sensitivity orchestration backends must be functions."
  )

  data_readiness <-
    profile_ids |>
    purrr::map(
      .f = function(profile_id) {
        list_config <-
          config_get_function(
            config = profile_id,
            file = config_file
          )

        list_sensitivity <-
          purrr::chuck(
            list_config,
            "model_fitting",
            "cross_validation",
            "common_regularization_sensitivity"
          )

        enabled <-
          base::isTRUE(list_sensitivity[["enabled"]])

        scale_id <-
          if (
            enabled
          ) {
            purrr::chuck(
              list_sensitivity,
              "representative_scale_id"
            )
          } else {
            NA_character_
          }

        store_path <-
          if (
            enabled
          ) {
            base::file.path(
              project_root,
              purrr::chuck(list_config, "target_store"),
              scale_id,
              pipeline_name
            )
          } else {
            NA_character_
          }

        tibble::tibble(
          profile_id = profile_id,
          tier_id = purrr::chuck(
            list_config,
            "model_fitting",
            "cross_validation",
            "tier_id"
          ),
          scale_id = scale_id,
          store_path = store_path,
          enabled = enabled
        )
      }
    ) |>
    purrr::list_rbind()

  enabled <-
    data_readiness[["enabled"]]

  if (
    !base::any(enabled)
  ) {
    base::message(
      "Skipping common-regularization sensitivity; ",
      "all configured profiles are disabled."
    )

    return(
      data_readiness |>
        dplyr::mutate(
          store_status = "disabled",
          sensitivity_status = "skipped_disabled"
        ) |>
        dplyr::select(-"enabled")
    )
  }

  enabled_store_exists <-
    dir_exists_function(
      data_readiness[["store_path"]][enabled]
    )

  assertthat::assert_that(
    base::is.logical(enabled_store_exists),
    base::length(enabled_store_exists) == base::sum(enabled),
    base::all(!base::is.na(enabled_store_exists)),
    msg = "`dir_exists_function` must return one logical per enabled store."
  )

  store_exists <-
    base::rep(NA, base::nrow(data_readiness))

  store_exists[enabled] <-
    enabled_store_exists

  data_readiness <-
    data_readiness |>
    dplyr::mutate(
      store_status = dplyr::case_when(
        !.data[["enabled"]] ~ "disabled",
        store_exists ~ "ready",
        .default = "missing"
      )
    )

  if (
    base::any(!enabled_store_exists)
  ) {
    missing_paths <-
      data_readiness[["store_path"]][enabled][!enabled_store_exists]

    base::message(
      "Skipping common-regularization sensitivity; missing stores: ",
      stringr::str_c(missing_paths, collapse = ", ")
    )

    return(
      data_readiness |>
        dplyr::mutate(
          sensitivity_status = dplyr::if_else(
            .data[["enabled"]],
            "skipped_missing_store",
            "skipped_disabled"
          )
        ) |>
        dplyr::select(-"enabled")
    )
  }

  run_pipeline_function(
    sel_script = sensitivity_script
  )

  res <-
    data_readiness |>
    dplyr::mutate(
      sensitivity_status = dplyr::if_else(
        .data[["enabled"]],
        "completed",
        "skipped_disabled"
      )
    ) |>
    dplyr::select(-"enabled")

  return(res)
}

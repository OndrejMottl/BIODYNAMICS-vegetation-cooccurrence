#' @title Refresh CZ Decomposition Upstream Targets
#' @description
#' Refreshes or validates the CZ paleo resolution-test target store.
#' @param refresh_upstream
#' Logical. If `TRUE`, rebuilds the upstream targets before validation.
#' @param store_path
#' Targets store path to validate.
#' @param pipeline_script
#' Pipeline script used for the upstream refresh.
#' @param run_pipeline_fn
#' Pipeline runner. Defaults to `run_pipeline()`.
#' @param tar_meta_fn
#' Metadata reader. Defaults to `targets::tar_meta()`.
#' @param verbose
#' Logical. If `TRUE`, progress messages are printed.
#' @return
#' One-row tibble with refresh metadata and validation status.
#' @export
refresh_cz_decomposition_upstream <- function(
    refresh_upstream = TRUE,
    store_path = here::here(
      "Data/targets/cz_paleo/pipeline_paleo_resolution_test"
    ),
    pipeline_script = "R/Pipelines/pipeline_paleo_resolution_test.R",
    run_pipeline_fn = run_pipeline,
    tar_meta_fn = targets::tar_meta,
    verbose = TRUE) {
  assertthat::assert_that(
    assertthat::is.flag(refresh_upstream),
    msg = "`refresh_upstream` must be TRUE or FALSE."
  )

  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    msg = "`store_path` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(pipeline_script),
    base::length(pipeline_script) == 1L,
    msg = "`pipeline_script` must be a single character string."
  )

  assertthat::assert_that(
    base::is.function(run_pipeline_fn),
    msg = "`run_pipeline_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(tar_meta_fn),
    msg = "`tar_meta_fn` must be a function."
  )

  if (
    base::isTRUE(refresh_upstream)
  ) {
    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    if (
      base::isTRUE(verbose)
    ) {
      cli::cli_inform("Refreshing CZ paleo resolution-test targets.")
    }

    run_pipeline_fn(
      sel_script = pipeline_script,
      fresh_run = TRUE,
      prebuild_interpolation = TRUE
    )
  }

  data_meta <-
    tar_meta_fn(
      fields = c("name", "error"),
      complete_only = FALSE,
      store = store_path
    )

  vec_required_targets <-
    c(
      "data_sample_ids_checked_genus",
      "data_community_model_matrix_genus",
      "data_abiotic_wide_genus",
      "data_spatial_mev_core",
      "data_coords_projected",
      "config_data_processing",
      "config_model_fitting",
      "config_spatial_predictors"
    )

  vec_missing_targets <-
    vec_required_targets |>
    purrr::discard(
      .p = ~ check_target_succeeded(
        data_meta = data_meta,
        target_name = .x
      )
    )

  flag_upstream_ok <-
    base::length(vec_missing_targets) == 0L

  if (
    base::isFALSE(flag_upstream_ok)
  ) {
    cli::cli_abort(
      c(
        "Required upstream CZ diagnostic targets are missing or failed.",
        "x" = stringr::str_c(vec_missing_targets, collapse = ", ")
      )
    )
  }

  res <-
    tibble::tibble(
      refreshed_at = base::as.character(base::Sys.time()),
      refresh_upstream = refresh_upstream,
      config_active = base::Sys.getenv("R_CONFIG_ACTIVE"),
      pipeline_script = pipeline_script,
      store_path = store_path,
      upstream_status = "ok",
      missing_targets = NA_character_
    )

  return(res)
}

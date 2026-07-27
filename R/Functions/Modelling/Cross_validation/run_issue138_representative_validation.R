#' @title Run an Issue 138 Representative Validation
#' @description
#' Runs staged tuning and selected final targets for one bounded validation
#' profile through the shared sjSDM orchestration engine.
#' @param active_config
#' Non-default configuration profile used for the validation.
#' @param unit_pipeline
#' Unit pipeline script passed to [run_sjsdm_tuning_sequence()].
#' @param tuning_target_names
#' Public tuning-summary targets included in the validation.
#' @param final_target_names
#' Final model, evaluation, and provenance targets to complete.
#' @param store_suffix
#' Optional isolated spatial-unit store suffix.
#' @param prebuild_interpolation
#' Logical controlling the first-round interpolation prebuild.
#' @param fresh_run
#' Logical controlling whether the first tuning round clears its isolated
#' target store. Use `FALSE` to resume completed work items.
#' @param run_sequence_function
#' Injectable tuning-sequence function used by tests.
#' @param run_pipeline_function
#' Injectable pipeline runner used by tests.
#' @return
#' Invisible `NULL`. Results are written to isolated target stores.
#' @export
run_issue138_representative_validation <- function(
    active_config = NULL,
    unit_pipeline = NULL,
    tuning_target_names = NULL,
    final_target_names = NULL,
    store_suffix = NULL,
    prebuild_interpolation = FALSE,
    fresh_run = TRUE,
    run_sequence_function = run_sjsdm_tuning_sequence,
    run_pipeline_function = run_pipeline) {
  flag_valid_active_config <-
    base::is.character(active_config) &&
    base::length(active_config) == 1L &&
    !base::is.na(active_config) &&
    base::nzchar(active_config)

  assertthat::assert_that(
    flag_valid_active_config,
    msg = "active_config must be one non-empty string."
  )

  flag_valid_unit_pipeline <-
    base::is.character(unit_pipeline) &&
    base::length(unit_pipeline) == 1L &&
    !base::is.na(unit_pipeline) &&
    base::nzchar(unit_pipeline)

  assertthat::assert_that(
    flag_valid_unit_pipeline,
    msg = "unit_pipeline must be one non-empty string."
  )

  validate_target_names <-
    function(target_names, argument_name) {
      flag_valid_targets <-
        base::is.character(target_names) &&
        base::length(target_names) > 0L &&
        base::all(!base::is.na(target_names)) &&
        base::all(base::nzchar(target_names)) &&
        !base::any(base::duplicated(target_names))

      assertthat::assert_that(
        flag_valid_targets,
        msg = stringr::str_glue(
          "{argument_name} must contain unique non-empty strings."
        )
      )
    }

  validate_target_names(
    target_names = tuning_target_names,
    argument_name = "tuning_target_names"
  )
  validate_target_names(
    target_names = final_target_names,
    argument_name = "final_target_names"
  )

  flag_valid_store_suffix <-
    base::is.null(store_suffix) ||
    (
      base::is.character(store_suffix) &&
        base::length(store_suffix) == 1L &&
        !base::is.na(store_suffix) &&
        base::nzchar(store_suffix)
    )

  assertthat::assert_that(
    flag_valid_store_suffix,
    msg = "store_suffix must be NULL or one non-empty string."
  )
  assertthat::assert_that(
    assertthat::is.flag(prebuild_interpolation),
    msg = "prebuild_interpolation must be TRUE or FALSE."
  )
  assertthat::assert_that(
    assertthat::is.flag(fresh_run),
    msg = "fresh_run must be TRUE or FALSE."
  )
  assertthat::assert_that(
    base::is.function(run_sequence_function),
    base::is.function(run_pipeline_function),
    msg = "Validation execution dependencies must be functions."
  )

  withr::with_envvar(
    new = base::c(R_CONFIG_ACTIVE = active_config),
    code = {
      list_cross_validation <-
        load_active_config_value(
          base::c("model_fitting", "cross_validation")
        )

      vec_repeat_order <-
        purrr::chuck(
          list_cross_validation,
          "staged_search",
          "repeat_order"
        )

      run_sequence_function(
        unit_pipeline = unit_pipeline,
        tuning_target_names = tuning_target_names,
        unit_store_suffixes = store_suffix,
        prebuild_interpolation = prebuild_interpolation,
        fresh_run = fresh_run,
        tuning_strategy = purrr::chuck(
          list_cross_validation,
          "tuning_strategy"
        ),
        n_rounds = base::length(vec_repeat_order),
        run_pipeline_function = run_pipeline_function,
        vec_allowed_profile_roles = "one_time",
        vec_allowed_profile_statuses = "frozen"
      )

      run_pipeline_function(
        sel_script = unit_pipeline,
        store_suffix = store_suffix,
        target_names = final_target_names,
        fresh_run = FALSE,
        prebuild_interpolation = FALSE,
        vec_allowed_profile_roles = "one_time",
        vec_allowed_profile_statuses = "frozen"
      )
    }
  )

  return(base::invisible(NULL))
}

#' @title Run One sjSDM Tier Tuning Round
#' @description
#' Runs one explicit tier survivor or final artifact target without a nested
#' callr boundary.
#' @param tuning_strategy,tier_target_name
#' Strategy and optional staged tier target.
#' @param fresh_round,final_round
#' First- and final-round flags.
#' @param run_pipeline_function
#' Injectable pipeline runner.
#' @param vec_allowed_profile_roles,vec_allowed_profile_statuses
#' Allowed profile metadata forwarded to the runner.
#' @return
#' Invisible `NULL`.
#' @export
run_sjsdm_tuning_tier_round <- function(
    tuning_strategy = NULL,
    tier_target_name = NULL,
    fresh_round = FALSE,
    final_round = FALSE,
    run_pipeline_function = run_pipeline,
    vec_allowed_profile_roles = base::c("main", "smoke"),
    vec_allowed_profile_statuses = "active") {
  list_arguments <-
    base::list(
      sel_script = "R/Pipelines/pipeline_sjsdm_tier_tuning.R",
      fresh_run = fresh_round,
      vec_allowed_profile_roles = vec_allowed_profile_roles,
      vec_allowed_profile_statuses = vec_allowed_profile_statuses,
      plot_progress = final_round,
      callr_function = NULL
    )

  if (
    tuning_strategy == "staged"
  ) {
    list_arguments[["target_names"]] <- tier_target_name
  }

  rlang::exec(
    .fn = run_pipeline_function,
    !!!list_arguments
  )

  return(base::invisible(NULL))
}

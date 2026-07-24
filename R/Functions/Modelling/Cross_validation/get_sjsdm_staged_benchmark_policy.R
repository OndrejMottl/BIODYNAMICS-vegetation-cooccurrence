#' @title Get the Versioned sjSDM Staged Benchmark Policy
#' @description
#' Returns the frozen issue 138 runtime, resource, technical, and scientific
#' acceptance thresholds for paired staged-versus-exhaustive benchmarks.
#' @return
#' A named list containing the policy version and numeric gate thresholds.
#' @export
get_sjsdm_staged_benchmark_policy <- function() {
  list_policy <-
    base::list(
      policy_version = "issue138_staged_benchmark_v2",
      minimum_median_wall_reduction = 0.15,
      minimum_each_wall_reduction = 0.10,
      minimum_fit_reduction = 0.40,
      maximum_store_growth = 0.25,
      maximum_memory_growth = 0.10,
      maximum_log_loss_regression = 0.005,
      maximum_auc_regression = 0.01,
      maximum_tjur_r2_regression = 0.01,
      maximum_coverage_regression = 0.02
    )

  return(list_policy)
}

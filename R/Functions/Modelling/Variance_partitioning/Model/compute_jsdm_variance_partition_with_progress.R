#' @title Compute sjSDM Decomposition with Conditional Likelihood Progress
#' @description
#' Runs the installed sjSDM 1.0.7 ANOVA method unchanged in a private execution
#' environment with an instrumented conditional-likelihood iteration adapter.
#' No package namespace or installed file is modified.
#' @param mod Fitted sjSDM object.
#' @param n_samples Positive Monte Carlo sample count; passed unchanged.
#' @param verbose Logical; print per-taxon start and completion timestamps.
#' @param anova_function Injectable ANOVA method; defaults to installed sjSDM.
#' @return The installed ANOVA method's result, with unchanged scientific rules.
#' @details
#' This sensitivity-only adapter fails closed on unsupported dependency versions
#' or changed ANOVA and conditional-likelihood bodies. It does not change
#' prediction calls, RNG order, fitting settings, or batch size.
#' @examples
#' \dontrun{
#' compute_jsdm_variance_partition_with_progress(
#'   mod = mod_jsdm,
#'   n_samples = 1000L,
#'   verbose = TRUE
#' )
#' }
#' @export
compute_jsdm_variance_partition_with_progress <- function(
    mod,
    n_samples = 5000L,
    verbose = FALSE,
    anova_function = NULL) {
  assertthat::assert_that(
    base::inherits(mod, "sjSDM"),
    msg = "mod must be an sjSDM model."
  )
  assertthat::assert_that(
    assertthat::is.count(n_samples),
    msg = "n_samples must be a positive integer."
  )
  assertthat::assert_that(
    assertthat::is.flag(verbose),
    !base::is.na(verbose),
    base::is.null(anova_function) || base::is.function(anova_function),
    msg = "Supply logical verbose and an optional ANOVA function."
  )
  environment_dependency <-
    base::asNamespace("sjSDM")
  conditional_function <-
    base::get(x = "get_conditional_lls", envir = environment_dependency)
  method_installed <-
    base::get(x = "anova.sjSDM", envir = environment_dependency)
  if (
    base::as.character(utils::packageVersion(pkg = "sjSDM")) != "1.0.7" ||
      digest::digest(base::body(conditional_function)) !=
        "b33a20f0361ecb86038a18d79f6faa5c" ||
      digest::digest(base::body(method_installed)) !=
        "b6d1a86de1598ea3e439f2d4da6655fa"
  ) {
    cli::cli_abort(
      "Unsupported sjSDM likelihood implementation; review the adapter."
    )
  }
  # Clone closures, not package bindings. Every upstream mathematical
  #   expression and RNG call is retained; only ordered iteration reports.
  vec_phase_ids <-
    if (
      base::inherits(mod, "spatial")
    ) {
      base::c("full", "abiotic", "biotic", "spatial", "abiotic_biotic",
        "abiotic_spatial", "biotic_spatial", "saturated")
    } else {
      base::c("full", "abiotic", "biotic", "saturated")
    }
  environment_progress <-
    rlang::env(index_pass = 0L, phase_ids = vec_phase_ids)
  environment_likelihood <-
    rlang::env(
      environment_dependency,
      sapply = purrr::partial(
        run_sjsdm_likelihood_sequence,
        verbose = verbose,
        progress_state = environment_progress
      )
    )
  conditional_instrumented <-
    rlang::new_function(
      args = base::formals(conditional_function),
      body = base::body(conditional_function),
      env = environment_likelihood
    )
  method_original <-
    if (
      base::is.null(anova_function)
    ) {
      method_installed
    } else {
      anova_function
    }
  environment_anova <-
    rlang::env(
      base::environment(method_original),
      get_conditional_lls = conditional_instrumented
    )
  method_instrumented <-
    rlang::new_function(
      args = base::formals(method_original),
      body = base::body(method_original),
      env = environment_anova
    )
  res <-
    method_instrumented(
      object = mod,
      samples = n_samples,
      verbose = verbose
    )
  return(res)
}

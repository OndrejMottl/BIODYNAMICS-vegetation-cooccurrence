#' @title Build the sjSDM Variance-Partition Method for One Model
#' @description
#' Returns the installed sjSDM 1.0.7 ANOVA method, unchanged, but evaluated in
#' a private environment in which every sub-model inherits the association
#' penalty and the seed of the full model.
#' @param mod
#' Fitted sjSDM object whose variance is partitioned.
#' @param anova_function
#' Optional ANOVA method to evaluate instead of the installed
#' `sjSDM:::anova.sjSDM()`. Intended for tests.
#' @param fit_function
#' Optional model-fitting function called by the cloned update method instead
#' of the installed `sjSDM::sjSDM()`. Intended for tests.
#' @return
#' A function with the formals of `anova.sjSDM()` (`object`, `samples`,
#' `verbose`, `...`) that returns an `sjSDManova` object.
#' @details
#' `sjSDM:::anova.sjSDM()` refits each sub-model with
#' `update(object, ..., biotic = bioticStruct(diag = ...))`. A default
#' `bioticStruct()` has `lambda = 0`, so sub-models containing the association
#' component lose the association penalty of the full model, and
#' `update.sjSDM()` falls back to the default sjSDM seed (issue #203).
#'
#' This builder clones the ANOVA closure without editing its body. The clone's
#' environment is a child of the sjSDM namespace that binds:
#' - `bioticStruct` to a partial application carrying the full model's
#'   `lambda` (`l1_cov + l2_cov`), `alpha` (`l2_cov / lambda`, or the sjSDM
#'   default when `lambda` is zero), `on_diag`, `reg_on_Cov`, `inverse`, and
#'   `df`, while the caller still sets `diag`;
#' - `update` to a clone of `update.sjSDM()` whose own environment binds
#'   `sjSDM` to a partial application carrying the full model's `seed`.
#'   `update.sjSDM()` re-evaluates its arguments through `match.call()`, so a
#'   forwarding wrapper around it would pass unevaluable `..N` symbols.
#'
#' The function fails closed when the installed sjSDM version, the bodies of
#' `anova.sjSDM()` and `update.sjSDM()`, or the formals and body of
#' `bioticStruct()` differ from the versions this adapter was written for.
#' No package namespace or installed file is modified.
#' @seealso [compute_jsdm_variance_partition()],
#'   [compute_jsdm_variance_partition_with_progress()]
#' @examples
#' \dontrun{
#' method_partition <-
#'   build_jsdm_variance_partition_method(mod = mod_jsdm)
#' method_partition(object = mod_jsdm, samples = 1000L, verbose = FALSE)
#' }
#' @export
build_jsdm_variance_partition_method <- function(
    mod,
    anova_function = NULL,
    fit_function = NULL) {
  assertthat::assert_that(
    base::inherits(mod, "sjSDM"),
    msg = "mod must be an sjSDM model."
  )
  assertthat::assert_that(
    base::is.null(anova_function) || base::is.function(anova_function),
    base::is.null(fit_function) || base::is.function(fit_function),
    msg = "Optional ANOVA and fitting methods must be functions."
  )

  environment_dependency <-
    base::asNamespace("sjSDM")
  method_installed <-
    base::get(x = "anova.sjSDM", envir = environment_dependency)
  update_installed <-
    base::get(x = "update.sjSDM", envir = environment_dependency)
  biotic_installed <-
    base::get(x = "bioticStruct", envir = environment_dependency)
  fit_installed <-
    base::get(x = "sjSDM", envir = environment_dependency)

  if (
    base::as.character(utils::packageVersion(pkg = "sjSDM")) != "1.0.7" ||
      digest::digest(base::body(method_installed)) !=
        "b6d1a86de1598ea3e439f2d4da6655fa" ||
      digest::digest(base::body(update_installed)) !=
        "6728469383e812cad4062da4be149741" ||
      digest::digest(base::formals(biotic_installed)) !=
        "d60265a3ed55d9f3c286924582ab7b81" ||
      digest::digest(base::body(biotic_installed)) !=
        "369e1c7febb9f7a66e32654f693cce83"
  ) {
    cli::cli_abort(
      "Unsupported sjSDM ANOVA implementation; review the partition adapter."
    )
  }

  list_biotic <-
    mod[["settings"]][["biotic"]]
  seed_model <-
    mod[["seed"]]

  assertthat::assert_that(
    base::inherits(list_biotic, "bioticStruct"),
    base::is.numeric(list_biotic[["l1_cov"]]),
    base::is.numeric(list_biotic[["l2_cov"]]),
    msg = "The model does not store its association settings."
  )
  assertthat::assert_that(
    assertthat::is.number(seed_model),
    !base::is.na(seed_model),
    msg = "The model does not store its seed."
  )

  lambda_cov <-
    list_biotic[["l1_cov"]] + list_biotic[["l2_cov"]]
  alpha_cov <-
    if (
      lambda_cov > 0
    ) {
      list_biotic[["l2_cov"]] / lambda_cov
    } else {
      base::formals(biotic_installed)[["alpha"]]
    }

  method_original <-
    if (
      base::is.null(anova_function)
    ) {
      method_installed
    } else {
      anova_function
    }
  fit_original <-
    if (
      base::is.null(fit_function)
    ) {
      fit_installed
    } else {
      fit_function
    }

  # update.sjSDM() re-evaluates its arguments through match.call(), so it
  #   must be called directly by the ANOVA method. The seed is therefore
  #   injected one level down, into the sjSDM() call of a cloned update.
  update_seeded <-
    rlang::new_function(
      args = base::formals(update_installed),
      body = base::body(update_installed),
      env = rlang::env(
        base::environment(update_installed),
        sjSDM = purrr::partial(
          fit_original,
          seed = seed_model
        )
      )
    )

  # Clone the closure, not the package binding: every upstream expression and
  #   RNG call stays as installed; only the sub-model settings are carried.
  environment_partition <-
    rlang::env(
      base::environment(method_original),
      bioticStruct = purrr::partial(
        biotic_installed,
        lambda = lambda_cov,
        alpha = alpha_cov,
        on_diag = list_biotic[["on_diag"]],
        reg_on_Cov = list_biotic[["reg_on_Cov"]],
        inverse = list_biotic[["inverse"]],
        df = list_biotic[["df"]]
      ),
      update = update_seeded
    )

  res <-
    rlang::new_function(
      args = base::formals(method_original),
      body = base::body(method_original),
      env = environment_partition
    )

  return(res)
}

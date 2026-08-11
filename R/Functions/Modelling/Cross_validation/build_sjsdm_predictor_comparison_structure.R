#' @title Configure an sjSDM Predictor Structure
#' @description
#' Creates a model-fitting configuration and abiotic formula for a controlled
#' predictor-component comparison.
#' @param predictor_structure
#' One of `"intercept_only"`, `"abiotic_only"`, `"spatial_only"`,
#' `"abiotic_spatial"`, or `"abiotic_spatial_no_associations"`.
#' @param config_model_fitting
#' Base model-fitting configuration. It is copied before `use_spatial` is set.
#' @param model_formula
#' Full abiotic model formula. Intercept-only and spatial-only structures
#' replace it with `~ 1` because sjSDM requires an environmental component.
#' @return
#' Named list containing the structure identifier, component flags, modified
#' model-fitting configuration, and formula.
#' @details
#' This helper changes predictor inclusion only. Regularization, folds, seeds,
#' fitting device, response filtering, and all other settings remain controlled
#' by the caller. The intercept-only structure can retain sjSDM's biotic
#' covariance and is therefore distinct from a fold-prevalence null.
#' @examples
#' build_sjsdm_predictor_comparison_structure(
#'   predictor_structure = "abiotic_only",
#'   config_model_fitting = list(use_spatial = TRUE),
#'   model_formula = stats::as.formula("~ age")
#' )
#' @export
build_sjsdm_predictor_comparison_structure <- function(
    predictor_structure = NULL,
    config_model_fitting = NULL,
    model_formula = NULL) {
  vec_predictor_structures <-
    base::c(
      "intercept_only",
      "abiotic_only",
      "spatial_only",
      "abiotic_spatial",
      "abiotic_spatial_no_associations"
    )

  assertthat::assert_that(
    base::is.character(predictor_structure),
    base::length(predictor_structure) == 1L,
    !base::is.na(predictor_structure),
    predictor_structure %in% vec_predictor_structures,
    msg = "predictor_structure must identify one supported structure."
  )

  assertthat::assert_that(
    base::is.list(config_model_fitting),
    msg = "config_model_fitting must be a list."
  )

  assertthat::assert_that(
    base::inherits(model_formula, "formula"),
    msg = "model_formula must be a formula."
  )

  uses_abiotic <-
    predictor_structure %in%
    base::c(
      "abiotic_only",
      "abiotic_spatial",
      "abiotic_spatial_no_associations"
    )

  uses_spatial <-
    predictor_structure %in%
    base::c(
      "spatial_only",
      "abiotic_spatial",
      "abiotic_spatial_no_associations"
    )

  uses_associations <-
    predictor_structure != "abiotic_spatial_no_associations"

  config_model_fitting_structure <-
    purrr::list_modify(
      config_model_fitting,
      use_spatial = uses_spatial
    )

  model_formula_structure <-
    if (
      uses_abiotic
    ) {
      model_formula
    } else {
      stats::as.formula("~ 1")
    }

  res <-
    base::list(
      predictor_structure = predictor_structure,
      uses_abiotic = uses_abiotic,
      uses_spatial = uses_spatial,
      uses_associations = uses_associations,
      config_model_fitting = config_model_fitting_structure,
      model_formula = model_formula_structure
    )

  return(res)
}

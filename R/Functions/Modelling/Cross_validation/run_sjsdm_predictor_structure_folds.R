#' @title Run One sjSDM Predictor Structure Across Selected Folds
#' @description
#' Applies one controlled predictor structure to deterministic
#' selected-candidate folds and returns labelled predictions and diagnostics.
#' @param predictor_structure
#' Structure passed to [configure_sjsdm_predictor_structure()].
#' @param data_assignments,data_selected_candidate,data_community_matrix
#' Cross-validation assignments, selected regularization, and response matrix.
#' @param data_abiotic_wide,data_coords_projected,data_sample_ids
#' Abiotic predictors, projected coordinates, and aligned sample metadata.
#' @param config_model_fitting,config_data_processing
#' Model-fitting and data-processing configurations used by fold preparation.
#' @param model_formula
#' Full abiotic formula used when abiotic predictors are enabled.
#' @param device
#' Fitting device passed to [fit_sjsdm_regularization_candidate()].
#' @param seed
#' Base selected-fold seed passed to
#' [run_sjsdm_selected_candidate_folds()].
#' @param prepare_fold_function,fit_candidate_function,runner_function
#' Injectable functions for fold preparation, candidate fitting, and selected
#' fold orchestration.
#' @param predict_function
#' Injectable held-out prediction function.
#' @return
#' Named list containing labelled `data_predictions` and `data_diagnostics`.
#' @details
#' Regularization and assignments are fixed by the supplied reference inputs.
#' The helper changes predictor inclusion only. Intercept-only and spatial-only
#' structures use an environmental intercept because sjSDM requires an
#' environmental component.
#' @examples
#' \dontrun{
#' run_sjsdm_predictor_structure_folds(
#'   predictor_structure = "abiotic_only",
#'   data_assignments = data_assignments,
#'   data_selected_candidate = data_selected_candidate,
#'   data_community_matrix = data_community_matrix,
#'   data_abiotic_wide = data_abiotic_wide,
#'   data_coords_projected = data_coords_projected,
#'   data_sample_ids = data_sample_ids,
#'   config_model_fitting = config_model_fitting,
#'   config_data_processing = config_data_processing,
#'   model_formula = model_formula
#' )
#' }
#' @export
run_sjsdm_predictor_structure_folds <- function(
    predictor_structure = NULL,
    data_assignments = NULL,
    data_selected_candidate = NULL,
    data_community_matrix = NULL,
    data_abiotic_wide = NULL,
    data_coords_projected = NULL,
    data_sample_ids = NULL,
    config_model_fitting = NULL,
    config_data_processing = NULL,
    model_formula = NULL,
    device = "gpu",
    seed = 900723L,
    prepare_fold_function = prepare_sjsdm_cross_validation_fold,
    fit_candidate_function = fit_sjsdm_regularization_candidate,
    runner_function = run_sjsdm_selected_candidate_folds,
    predict_function = predict_sjsdm_probability_matrix) {
  assertthat::assert_that(
    base::is.matrix(data_community_matrix),
    !base::is.null(base::colnames(data_community_matrix)),
    msg = "data_community_matrix must be a named matrix."
  )

  assertthat::assert_that(
    base::is.function(prepare_fold_function),
    base::is.function(fit_candidate_function),
    base::is.function(runner_function),
    base::is.function(predict_function),
    msg = "All injected execution inputs must be functions."
  )

  list_structure <-
    configure_sjsdm_predictor_structure(
      predictor_structure = predictor_structure,
      config_model_fitting = config_model_fitting,
      model_formula = model_formula
    )

  config_model_fitting_structure <-
    list_structure[["config_model_fitting"]]

  model_formula_structure <-
    list_structure[["model_formula"]]

  list_fold_results <-
    runner_function(
      data_assignments = data_assignments,
      data_selected_candidate = data_selected_candidate,
      data_sample_ids = data_sample_ids,
      taxon_names = base::colnames(data_community_matrix),
      prepare_fold_function = function(
          train_indices,
          test_indices,
          repeat_id,
          fold_id) {
        prepare_fold_function(
          data_community_matrix = data_community_matrix,
          data_abiotic_wide = data_abiotic_wide,
          data_coords_projected = data_coords_projected,
          data_sample_ids = data_sample_ids,
          train_indices = train_indices,
          test_indices = test_indices,
          config_model_fitting = config_model_fitting_structure,
          config_data_processing = config_data_processing,
          repeat_id = repeat_id,
          fold_id = fold_id
        )
      },
      fit_function = function(data_train_input, candidate, seed) {
        fit_candidate_function(
          data_train_input = data_train_input,
          candidate = candidate,
          sel_abiotic_formula = model_formula_structure,
          config_model_fitting = config_model_fitting_structure,
          seed = seed,
          device = device
        )
      },
      predict_function = predict_function,
      seed = seed
    )

  assertthat::assert_that(
    base::is.list(list_fold_results),
    base::all(
      base::c("data_predictions", "data_diagnostics") %in%
        base::names(list_fold_results)
    ),
    base::is.data.frame(list_fold_results[["data_predictions"]]),
    base::is.data.frame(list_fold_results[["data_diagnostics"]]),
    msg = "runner_function must return prediction and diagnostic tables."
  )

  data_predictions <-
    list_fold_results[["data_predictions"]] |>
    dplyr::mutate(
      predictor_structure = predictor_structure,
      .before = 1L
    )

  data_diagnostics <-
    list_fold_results[["data_diagnostics"]] |>
    dplyr::mutate(
      predictor_structure = predictor_structure,
      .before = 1L
    )

  res <-
    base::list(
      data_predictions = data_predictions,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

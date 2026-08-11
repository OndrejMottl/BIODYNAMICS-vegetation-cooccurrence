#' @title Make Empty Selected sjSDM Fold Artifacts
#' @description
#' Creates schema-compatible empty selected-candidate OOF prediction and fold
#' diagnostic artifacts for scientifically inapplicable models.
#' @return
#' Named list with empty `data_predictions` and `data_diagnostics` tibbles
#' matching [run_sjsdm_selected_candidate_folds()].
#' @examples
#' build_sjsdm_empty_selected_fold_artifacts()
#' @export
build_sjsdm_empty_selected_fold_artifacts <- function() {
  res <-
    base::list(
      data_predictions = tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        row_index = base::integer(),
        location_id = base::character(),
        dataset_name = base::character(),
        age = base::numeric(),
        taxon = base::character(),
        observed = base::numeric(),
        predicted_probability = base::numeric(),
        null_probability = base::numeric(),
        prediction_status = base::character()
      ),
      data_diagnostics = tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        candidate_id = base::character(),
        fit_seed = base::integer(),
        n_train_samples = base::integer(),
        n_test_samples = base::integer(),
        n_taxa_retained = base::integer(),
        n_effective_mev = base::integer(),
        fit_status = base::character(),
        error_message = base::character(),
        cv_strategy = base::character(),
        regularization_source = base::character()
      )
    )

  return(res)
}

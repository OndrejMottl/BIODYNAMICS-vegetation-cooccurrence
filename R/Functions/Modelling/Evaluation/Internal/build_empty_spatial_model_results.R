#' @title Build an Empty Spatial Model Result
#' @description
#' Creates the typed zero-row schema returned when no model results can be
#' loaded.
#' @return
#' A zero-row tibble with the spatial model result schema.
#' @noRd
.build_empty_spatial_model_results <- function() {
  res <-
    tibble::tibble(
      data_source = base::character(),
      scale = base::character(),
      scale_id = base::character(),
      pipeline_name = base::character(),
      store_path = base::character(),
      resolution_id = base::character(),
      component = base::character(),
      R2_Nagelkerke_adjusted = base::numeric(),
      R2_Nagelkerke_percentage = base::numeric(),
      fitted_auc_mean = base::numeric(),
      fitted_auc_median = base::numeric(),
      fitted_auc_n = base::integer(),
      predictive_tjur_r2_mean = base::numeric(),
      predictive_auc_mean = base::numeric(),
      predictive_log_loss_mean = base::numeric(),
      cv_strategy = base::character(),
      effective_folds = base::integer(),
      cv_feasibility_status = base::character(),
      n_locations = base::integer(),
      n_samples = base::integer(),
      n_taxa = base::integer(),
      n_effective_mev = base::integer(),
      regularization_source = base::character(),
      source_tier = base::character(),
      candidate_id = base::character()
    )

  return(res)
}

#' @title Load Spatial Model Results
#' @description
#' Loads successful spatial model ANOVA and evaluation targets from indexed
#' targets stores and returns one summary row per
#' store-resolution-component combination.
#' @param store_index
#' Data frame returned by [build_spatial_model_store_index()].
#' @param resolution_ids
#' Character vector of model resolution identifiers.
#' @param read_target_fn
#' Function used to load one target. Defaults to
#' [targets::tar_read_raw()].
#' @param meta_fn
#' Function used to load target metadata. Defaults to
#' [targets::tar_meta()].
#' @param require_non_empty
#' Logical. If `TRUE`, error when no rows are loaded.
#' @return
#' A tibble with ANOVA component percentages, explicitly labelled fitted AUC,
#' and cross-validated predictive Tjur R2, AUC, and log loss.
#' @export
load_spatial_model_results <- function(
    store_index,
    resolution_ids,
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta,
    require_non_empty = FALSE) {
  assertthat::assert_that(
    base::is.data.frame(store_index),
    msg = "`store_index` must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "data_source",
      "scale",
      "scale_id",
      "pipeline_name",
      "store_path",
      "store_exists"
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(store_index)),
    msg = stringr::str_glue(
      "`store_index` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.character(resolution_ids) &&
      base::length(resolution_ids) > 0L,
    msg = "`resolution_ids` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  assertthat::assert_that(
    assertthat::is.flag(require_non_empty),
    msg = "`require_non_empty` must be a single logical value."
  )

  data_empty_result <-
    .build_empty_spatial_model_results()

  data_existing_stores <-
    store_index |>
    dplyr::filter(.data[["store_exists"]]) |>
    dplyr::mutate(
      row_id = dplyr::row_number(),
      data_meta = .data[["store_path"]] |>
        purrr::map(
          .f = function(store_path) {
            purrr::possibly(
              .f = function() {
                meta_fn(
                  fields = base::c("name", "error"),
                  complete_only = FALSE,
                  store = store_path
                )
              },
              otherwise = NULL
            )()
          }
        )
    )

  list_store_results <-
    data_existing_stores |>
    dplyr::group_split(.data[["row_id"]], .keep = FALSE) |>
    purrr::map(
      .f = function(store_row) {
        data_meta <-
          store_row |>
          dplyr::pull("data_meta") |>
          purrr::chuck(1L)

        store_path <-
          store_row |>
          dplyr::pull("store_path") |>
          purrr::chuck(1L)

        resolution_ids |>
          purrr::map(
            .f = function(resolution_id) {
              target_anova <-
                stringr::str_glue("model_anova_{resolution_id}") |>
                base::as.character()

              model_anova <-
                .load_successful_model_target(
                  data_meta = data_meta,
                  target_name = target_anova,
                  store_path = store_path,
                  read_target_fn = read_target_fn
                )

              if (
                base::is.null(model_anova)
              ) {
                return(data_empty_result)
              }

              data_anova <-
                extract_jsdm_variance_fractions(
                  anova_object = model_anova,
                  clamp_negative = TRUE
                ) |>
                dplyr::mutate(age = 0)

              if (
                base::nrow(data_anova) == 0L
              ) {
                return(data_empty_result)
              }

              target_evaluation_fitted <-
                stringr::str_glue(
                  "model_evaluation_fitted_{resolution_id}"
                ) |>
                base::as.character()

              model_evaluation_fitted <-
                if (
                  check_target_succeeded(
                    data_meta,
                    target_evaluation_fitted
                  )
                ) {
                  load_model_evaluation_target(
                    store_path = store_path,
                    resolution_id = resolution_id,
                    evaluation_type = "fitted",
                    read_target_fn = read_target_fn
                  )
                } else {
                  NULL
                }

              data_fitted_auc <-
                .summarise_fitted_auc(
                  model_evaluation_fitted = model_evaluation_fitted
                )

              target_evaluation_cross_validated <-
                stringr::str_glue(
                  "model_evaluation_cross_validated_{resolution_id}"
                ) |>
                base::as.character()

              model_evaluation_cross_validated <-
                if (
                  check_target_succeeded(
                    data_meta,
                    target_evaluation_cross_validated
                  )
                ) {
                  load_model_evaluation_target(
                    store_path = store_path,
                    resolution_id = resolution_id,
                    evaluation_type = "cross_validated",
                    read_target_fn = read_target_fn
                  )
                } else {
                  NULL
                }

              data_predictive_metrics <-
                .summarise_predictive_model_metrics(
                  model_evaluation_cross_validated =
                    model_evaluation_cross_validated
                )

              target_provenance <-
                stringr::str_glue(
                  "data_sjsdm_model_provenance_{resolution_id}"
                ) |>
                base::as.character()

              data_provenance <-
                .load_successful_model_target(
                  data_meta = data_meta,
                  target_name = target_provenance,
                  store_path = store_path,
                  read_target_fn = read_target_fn
                )

              data_provenance_summary <-
                .summarise_model_provenance(
                  data_provenance = data_provenance
                )

              data_anova |>
                compute_shapley_variance_components() |>
                dplyr::mutate(
                  data_source = store_row |>
                    dplyr::pull("data_source") |>
                    purrr::chuck(1L),
                  scale = store_row |>
                    dplyr::pull("scale") |>
                    purrr::chuck(1L),
                  scale_id = store_row |>
                    dplyr::pull("scale_id") |>
                    purrr::chuck(1L),
                  pipeline_name = store_row |>
                    dplyr::pull("pipeline_name") |>
                    purrr::chuck(1L),
                  store_path = store_path,
                  resolution_id = resolution_id,
                  fitted_auc_mean = data_fitted_auc |>
                    dplyr::pull("fitted_auc_mean") |>
                    purrr::chuck(1L),
                  fitted_auc_median = data_fitted_auc |>
                    dplyr::pull("fitted_auc_median") |>
                    purrr::chuck(1L),
                  fitted_auc_n = data_fitted_auc |>
                    dplyr::pull("fitted_auc_n") |>
                    purrr::chuck(1L),
                  predictive_tjur_r2_mean = data_predictive_metrics |>
                    dplyr::pull("predictive_tjur_r2_mean") |>
                    purrr::chuck(1L),
                  predictive_auc_mean = data_predictive_metrics |>
                    dplyr::pull("predictive_auc_mean") |>
                    purrr::chuck(1L),
                  predictive_log_loss_mean = data_predictive_metrics |>
                    dplyr::pull("predictive_log_loss_mean") |>
                    purrr::chuck(1L),
                  cv_strategy = data_provenance_summary |>
                    dplyr::pull("cv_strategy") |>
                    purrr::chuck(1L),
                  effective_folds = data_provenance_summary |>
                    dplyr::pull("effective_folds") |>
                    purrr::chuck(1L),
                  cv_feasibility_status = data_provenance_summary |>
                    dplyr::pull("cv_feasibility_status") |>
                    purrr::chuck(1L),
                  n_locations = data_provenance_summary |>
                    dplyr::pull("n_locations") |>
                    purrr::chuck(1L),
                  n_samples = data_provenance_summary |>
                    dplyr::pull("n_samples") |>
                    purrr::chuck(1L),
                  n_taxa = data_provenance_summary |>
                    dplyr::pull("n_taxa") |>
                    purrr::chuck(1L),
                  n_effective_mev = data_provenance_summary |>
                    dplyr::pull("n_effective_mev") |>
                    purrr::chuck(1L),
                  regularization_source = data_provenance_summary |>
                    dplyr::pull("regularization_source") |>
                    purrr::chuck(1L),
                  source_tier = data_provenance_summary |>
                    dplyr::pull("source_tier") |>
                    purrr::chuck(1L),
                  candidate_id = data_provenance_summary |>
                    dplyr::pull("candidate_id") |>
                    purrr::chuck(1L)
                ) |>
                dplyr::select(
                  "data_source",
                  "scale",
                  "scale_id",
                  "pipeline_name",
                  "store_path",
                  "resolution_id",
                  "component",
                  "R2_Nagelkerke_adjusted",
                  "R2_Nagelkerke_percentage",
                  "fitted_auc_mean",
                  "fitted_auc_median",
                  "fitted_auc_n",
                  "predictive_tjur_r2_mean",
                  "predictive_auc_mean",
                  "predictive_log_loss_mean",
                  "cv_strategy",
                  "effective_folds",
                  "cv_feasibility_status",
                  "n_locations",
                  "n_samples",
                  "n_taxa",
                  "n_effective_mev",
                  "regularization_source",
                  "source_tier",
                  "candidate_id"
                )
            }
          ) |>
          purrr::list_rbind()
      }
    )

  data_result <-
    list_store_results |>
    purrr::list_rbind()

  data_result_complete <-
    if (
      base::is.null(data_result)
    ) {
      data_empty_result
    } else {
      data_result
    }

  if (
    base::isTRUE(require_non_empty) &&
      base::nrow(data_result_complete) == 0L
  ) {
    cli::cli_abort(
      "No successful spatial model results were found in existing stores."
    )
  }

  return(data_result_complete)
}

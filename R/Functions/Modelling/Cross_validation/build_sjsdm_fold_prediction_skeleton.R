#' @title Build an sjSDM Fold Prediction Skeleton
#' @description
#' Constructs exact typed out-of-fold rows when selected-fold preparation
#' fails before aligned observations and predictions are available.
#' @param list_fold_context
#' Fold context with repeat, fold, and held-out row indices.
#' @param data_sample_ids
#' Normalized sample metadata with sample, row, and location identifiers.
#' @param taxon_names
#' Full ordered response-taxon names.
#' @param prediction_status
#' Failure status assigned to every skeleton row.
#' @return
#' Typed out-of-fold prediction tibble for the held-out fold.
#' @export
build_sjsdm_fold_prediction_skeleton <- function(
    list_fold_context = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    prediction_status = "preparation_error") {
  vec_context_names <-
    base::c("repeat_id", "fold_id", "test_indices")

  vec_sample_columns <-
    base::c(
      "sample_id",
      "row_index",
      "location_id",
      "dataset_name",
      "age"
    )

  assertthat::assert_that(
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    base::is.data.frame(data_sample_ids),
    base::all(vec_sample_columns %in% base::colnames(data_sample_ids)),
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    base::is.character(prediction_status),
    base::length(prediction_status) == 1L,
    !base::is.na(prediction_status),
    msg = "Fold prediction skeleton inputs are incomplete."
  )

  data_test_samples <-
    data_sample_ids |>
    dplyr::filter(
      .data[["row_index"]] %in%
        list_fold_context[["test_indices"]]
    )

  res <-
    tidyr::crossing(
      data_test_samples,
      taxon = taxon_names
    ) |>
    dplyr::mutate(
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]],
      observed = NA_real_,
      predicted_probability = NA_real_,
      null_probability = NA_real_,
      prediction_status = prediction_status
    ) |>
    dplyr::select(
      "repeat_id",
      "fold_id",
      "row_index",
      "location_id",
      "dataset_name",
      "age",
      "taxon",
      "observed",
      "predicted_probability",
      "null_probability",
      "prediction_status"
    )

  return(res)
}

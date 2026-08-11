#' @title Build Selected sjSDM Fold Artifacts
#' @description
#' Aligns prepared responses, selected-candidate probabilities, taxa, null
#' probabilities, and sample metadata into one fold's public prediction and
#' diagnostic artifacts. The function never fits a model.
#' @param list_prepared_fold
#' Valid prepared selected-fold inputs.
#' @param list_fold_context
#' Fold identifiers, held-out indices, sizes, and strategy.
#' @param data_sample_ids
#' Normalized sample metadata.
#' @param taxon_names
#' Full ordered response-taxon names.
#' @param candidate_id,fit_seed,regularization_source
#' Selected-candidate provenance.
#' @param data_predicted
#' Optional retained-taxon probability matrix. Missing for fit failures.
#' @param fold_status
#' `ok`, `fit_error`, or `prediction_error`.
#' @param error_message
#' Failure message, or a missing character value for successful predictions.
#' @return
#' Named list with `data_predictions` and `data_diagnostics`.
#' @export
build_sjsdm_selected_fold_artifacts <- function(
    list_prepared_fold = NULL,
    list_fold_context = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    candidate_id = NULL,
    fit_seed = NULL,
    regularization_source = NULL,
    data_predicted = NULL,
    fold_status = "ok",
    error_message = NA_character_) {
  vec_required_fold_elements <-
    base::c(
      "data_train_input",
      "data_test_input",
      "data_train_observed",
      "data_test_observed",
      "data_test_observed_full",
      "test_sample_ids",
      "data_taxa_mapping"
    )

  vec_context_names <-
    base::c("repeat_id", "fold_id", "test_indices", "cv_strategy")

  assertthat::assert_that(
    base::is.list(list_prepared_fold),
    base::all(
      vec_required_fold_elements %in% base::names(list_prepared_fold)
    ),
    base::is.list(list_fold_context),
    base::all(vec_context_names %in% base::names(list_fold_context)),
    base::is.data.frame(data_sample_ids),
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    base::is.character(candidate_id),
    base::length(candidate_id) == 1L,
    base::is.numeric(fit_seed),
    base::length(fit_seed) == 1L,
    base::is.character(regularization_source),
    base::length(regularization_source) == 1L,
    fold_status %in% base::c("ok", "fit_error", "prediction_error"),
    msg = "Selected-fold artifact inputs are incomplete."
  )

  data_train_observed <-
    list_prepared_fold[["data_train_observed"]]

  data_test_observed <-
    list_prepared_fold[["data_test_observed"]]

  data_test_observed_full <-
    list_prepared_fold[["data_test_observed_full"]]

  vec_test_sample_ids <-
    list_prepared_fold[["test_sample_ids"]]

  data_taxa_mapping <-
    list_prepared_fold[["data_taxa_mapping"]]

  vec_mapping_columns <-
    base::c("taxon", "retained", "status")

  flag_valid_fold <-
    base::is.matrix(data_train_observed) &&
    base::is.numeric(data_train_observed) &&
    base::is.matrix(data_test_observed) &&
    base::is.numeric(data_test_observed) &&
    base::is.matrix(data_test_observed_full) &&
    base::is.numeric(data_test_observed_full) &&
    base::is.character(vec_test_sample_ids) &&
    base::is.data.frame(data_taxa_mapping) &&
    base::all(
      vec_mapping_columns %in% base::colnames(data_taxa_mapping)
    ) &&
    base::identical(
      base::colnames(data_test_observed_full),
      taxon_names
    ) &&
    base::identical(
      base::rownames(data_test_observed_full),
      vec_test_sample_ids
    ) &&
    base::identical(data_taxa_mapping[["taxon"]], taxon_names)

  if (
    !flag_valid_fold
  ) {
    cli::cli_abort("Fold preparation outputs are not aligned.")
  }

  vec_retained_taxa <-
    data_taxa_mapping |>
    dplyr::filter(.data[["retained"]]) |>
    dplyr::pull("taxon")

  flag_retained_aligned <-
    base::identical(
      base::colnames(data_train_observed),
      vec_retained_taxa
    ) &&
    base::identical(
      base::colnames(data_test_observed),
      vec_retained_taxa
    ) &&
    base::identical(
      base::rownames(data_test_observed),
      vec_test_sample_ids
    ) &&
    base::all(data_train_observed %in% base::c(0, 1)) &&
    base::all(data_test_observed %in% base::c(0, 1)) &&
    base::all(data_test_observed_full %in% base::c(0, 1))

  if (
    !flag_retained_aligned
  ) {
    cli::cli_abort("Prepared response matrices are not aligned.")
  }

  vec_null_probability <-
    base::rep(NA_real_, base::length(taxon_names))

  base::names(vec_null_probability) <-
    taxon_names

  vec_null_probability[vec_retained_taxa] <-
    base::colMeans(data_train_observed)

  data_spatial_train <-
    list_prepared_fold[["data_train_input"]][[
      "data_spatial_to_fit"
    ]]

  n_effective_mev <-
    if (
      base::is.null(data_spatial_train)
    ) {
      0L
    } else {
      base::ncol(data_spatial_train)
    }

  data_predicted_full <-
    base::matrix(
      data = NA_real_,
      nrow = base::nrow(data_test_observed_full),
      ncol = base::ncol(data_test_observed_full),
      dimnames = base::dimnames(data_test_observed_full)
    )

  if (
    fold_status == "ok"
  ) {
    data_predicted_matrix <-
      base::as.matrix(data_predicted)

    if (
      base::is.null(base::rownames(data_predicted_matrix))
    ) {
      base::rownames(data_predicted_matrix) <-
        base::rownames(data_test_observed)
    }

    if (
      base::is.null(base::colnames(data_predicted_matrix))
    ) {
      base::colnames(data_predicted_matrix) <-
        base::colnames(data_test_observed)
    }

    flag_predictions_aligned <-
      base::is.numeric(data_predicted_matrix) &&
      base::identical(
        base::dim(data_predicted_matrix),
        base::dim(data_test_observed)
      ) &&
      base::identical(
        base::dimnames(data_predicted_matrix),
        base::dimnames(data_test_observed)
      ) &&
      base::all(base::is.finite(data_predicted_matrix)) &&
      base::all(data_predicted_matrix >= 0) &&
      base::all(data_predicted_matrix <= 1)

    if (
      !flag_predictions_aligned
    ) {
      fold_status <- "prediction_error"
      error_message <- "Predicted probabilities are not aligned."
    } else {
      data_predicted_full[, vec_retained_taxa] <-
        data_predicted_matrix
    }
  }

  data_observed_long <-
    data_test_observed_full |>
    tibble::as_tibble(rownames = "sample_id") |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(taxon_names),
      names_to = "taxon",
      values_to = "observed"
    )

  data_predicted_long <-
    data_predicted_full |>
    tibble::as_tibble(rownames = "sample_id") |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(taxon_names),
      names_to = "taxon",
      values_to = "predicted_probability"
    )

  data_fold_values <-
    data_observed_long |>
    dplyr::left_join(
      data_predicted_long,
      by = dplyr::join_by(sample_id, taxon),
      relationship = "one-to-one"
    )

  data_test_samples <-
    data_sample_ids |>
    dplyr::filter(
      .data[["row_index"]] %in% list_fold_context[["test_indices"]]
    )

  data_prediction_grid <-
    tidyr::crossing(data_test_samples, taxon = taxon_names)

  data_taxa_status <-
    data_taxa_mapping |>
    dplyr::select(
      "taxon",
      "retained",
      taxon_status = "status"
    )

  data_predictions <-
    data_prediction_grid |>
    dplyr::left_join(
      data_fold_values,
      by = dplyr::join_by(sample_id, taxon),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      data_taxa_status,
      by = dplyr::join_by(taxon),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      null_probability = base::unname(
        vec_null_probability[.data[["taxon"]]]
      ),
      prediction_status = dplyr::case_when(
        !.data[["sample_id"]] %in% vec_test_sample_ids ~
          "test_row_not_aligned",
        .data[["retained"]] & fold_status != "ok" ~ fold_status,
        .data[["retained"]] ~ "ok",
        .default = .data[["taxon_status"]]
      ),
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]]
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

  data_diagnostics <-
    tibble::tibble(
      repeat_id = list_fold_context[["repeat_id"]],
      fold_id = list_fold_context[["fold_id"]],
      candidate_id = candidate_id,
      fit_seed = base::as.integer(fit_seed),
      n_train_samples = base::nrow(data_train_observed),
      n_test_samples = base::nrow(data_test_observed_full),
      n_taxa_retained = base::length(vec_retained_taxa),
      n_effective_mev = base::as.integer(n_effective_mev),
      fit_status = fold_status,
      error_message = error_message,
      cv_strategy = list_fold_context[["cv_strategy"]],
      regularization_source = regularization_source
    )

  res <-
    base::list(
      data_predictions = data_predictions,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

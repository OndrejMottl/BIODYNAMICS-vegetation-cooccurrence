#' @title Run Selected sjSDM Candidate Across Folds
#' @description
#' Refits one selected regularization candidate independently in every fold
#' and materializes aligned out-of-fold probabilities.
#' @param data_assignments
#' Location-level assignment table accepted by
#' [run_sjsdm_tuning_candidates()].
#' @param data_selected_candidate
#' One-row selected candidate table containing the candidate identifier, the
#' six sjSDM regularization parameters, and regularization source.
#' @param data_sample_ids
#' Sample metadata with `dataset_name` and `age`. Optional sample, row, and
#' location identifiers are derived when absent.
#' @param taxon_names
#' Unique character vector defining the full response-taxon order.
#' @param prepare_fold_function
#' Injectable function called with training and test row indices plus repeat
#' and fold identifiers. It must return train/test inputs, retained train/test
#' response matrices, the full test response matrix, aligned test sample
#' identifiers, and the fold taxon mapping.
#' @param fit_function
#' Injectable function called with the prepared training input, selected
#' candidate, and deterministic fit seed.
#' @param predict_function
#' Injectable function called with the fitted object and prepared test input.
#' It must return probabilities aligned to retained test observations.
#' @param seed
#' Single non-negative integer used to derive stable fold fit seeds.
#' @return
#' Named list with data-prediction and data-diagnostic tibbles. Predictions
#' contain one row per repeat, sample, and full-response taxon, including
#' observed values, predictions, training-fold null probabilities, and explicit
#' status. Diagnostics record one structured fit status per fold.
#' @details
#' The prediction table deliberately omits the candidate identifier. Selected
#' candidate provenance remains in the separate fold diagnostics and selected
#' candidate artifact. Taxa not retained in a training fold remain as rows with
#' missing probabilities and their taxon-mapping status.
#' @examples
#' \dontrun{
#' run_sjsdm_selected_candidate_folds(
#'   data_assignments = data_assignments,
#'   data_selected_candidate = data_selected_candidate,
#'   data_sample_ids = data_sample_ids,
#'   taxon_names = taxon_names,
#'   prepare_fold_function = prepare_fold_function,
#'   fit_function = fit_function,
#'   predict_function = predict_function
#' )
#' }
#' @export
run_sjsdm_selected_candidate_folds <- function(
    data_assignments = NULL,
    data_selected_candidate = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    prepare_fold_function = NULL,
    fit_function = NULL,
    predict_function = NULL,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    msg = "data_assignments must be a data frame."
  )

  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  vec_selected_columns <-
    base::c(vec_candidate_columns, "regularization_source")

  assertthat::assert_that(
    base::is.data.frame(data_selected_candidate),
    base::nrow(data_selected_candidate) == 1L,
    base::all(
      vec_selected_columns %in%
        base::colnames(data_selected_candidate)
    ),
    msg = "data_selected_candidate must contain one complete candidate."
  )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        data_selected_candidate[vec_parameter_columns],
        base::is.numeric
      )
    ),
    base::all(
      base::is.finite(
        base::as.matrix(
          data_selected_candidate[vec_parameter_columns]
        )
      )
    ),
    msg = "Selected candidate parameters must be finite numbers."
  )

  assertthat::assert_that(
    base::is.data.frame(data_sample_ids),
    base::nrow(data_sample_ids) > 0L,
    base::all(
      base::c("dataset_name", "age") %in%
        base::colnames(data_sample_ids)
    ),
    msg = "data_sample_ids must contain dataset_name and age."
  )

  vec_sample_id <-
    if (
      "sample_id" %in% base::colnames(data_sample_ids)
    ) {
      base::as.character(data_sample_ids[["sample_id"]])
    } else {
      stringr::str_c(
        data_sample_ids[["dataset_name"]],
        "__",
        data_sample_ids[["age"]]
      )
    }

  vec_row_index <-
    if (
      "row_index" %in% base::colnames(data_sample_ids)
    ) {
      base::as.integer(data_sample_ids[["row_index"]])
    } else {
      base::seq_len(base::nrow(data_sample_ids))
    }

  vec_location_id <-
    if (
      "location_id" %in% base::colnames(data_sample_ids)
    ) {
      base::as.character(data_sample_ids[["location_id"]])
    } else {
      base::as.character(data_sample_ids[["dataset_name"]])
    }

  data_sample_ids_normalized <-
    data_sample_ids |>
    dplyr::mutate(
      sample_id = .env[["vec_sample_id"]],
      row_index = .env[["vec_row_index"]],
      location_id = .env[["vec_location_id"]]
    )

  assertthat::assert_that(
    base::is.character(data_sample_ids_normalized[["sample_id"]]),
    !base::any(base::is.na(data_sample_ids_normalized[["sample_id"]])),
    !base::any(base::duplicated(data_sample_ids_normalized[["sample_id"]])),
    base::is.numeric(data_sample_ids_normalized[["row_index"]]),
    base::all(base::is.finite(data_sample_ids_normalized[["row_index"]])),
    base::all(data_sample_ids_normalized[["row_index"]] >= 1L),
    base::all(
      data_sample_ids_normalized[["row_index"]] ==
        base::as.integer(data_sample_ids_normalized[["row_index"]])
    ),
    !base::any(
      base::duplicated(data_sample_ids_normalized[["row_index"]])
    ),
    msg = "Sample and row identifiers must be unique and non-missing."
  )

  assertthat::assert_that(
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    !base::any(base::is.na(taxon_names)),
    base::all(base::nzchar(taxon_names)),
    !base::any(base::duplicated(taxon_names)),
    msg = "taxon_names must contain unique non-missing strings."
  )

  assertthat::assert_that(
    base::is.function(prepare_fold_function),
    base::is.function(fit_function),
    base::is.function(predict_function),
    msg = "Preparation, fit, and prediction inputs must be functions."
  )

  flag_valid_seed <-
    base::is.numeric(seed) &&
    base::length(seed) == 1L &&
    base::is.finite(seed) &&
    seed >= 0L &&
    seed == base::as.integer(seed)

  assertthat::assert_that(
    flag_valid_seed,
    msg = "seed must be one non-negative integer."
  )

  if (
    base::nrow(data_assignments) == 0L
  ) {
    res_empty <-
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

    return(res_empty)
  }

  vec_assignment_indices <-
    data_assignments[["row_indices"]] |>
    base::unlist(use.names = FALSE) |>
    base::as.integer() |>
    base::unique()

  if (
    !base::all(
      vec_assignment_indices %in%
        data_sample_ids_normalized[["row_index"]]
    )
  ) {
    cli::cli_abort(
      "Every assigned row index must have sample metadata."
    )
  }

  candidate_id <-
    data_selected_candidate[["candidate_id"]][[1L]]

  regularization_source <-
    data_selected_candidate[["regularization_source"]][[1L]]

  data_candidate <-
    data_selected_candidate |>
    dplyr::select(dplyr::all_of(vec_candidate_columns))

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  make_prediction_skeleton <- function(
      list_fold_context,
      prediction_status) {
    data_test_samples <-
      data_sample_ids_normalized |>
      dplyr::filter(
        .data[["row_index"]] %in%
          list_fold_context[["test_indices"]]
      )

    res_skeleton <-
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

    return(res_skeleton)
  }

  list_fold_results <-
    purrr::map2(
      .x = data_fold_keys[["repeat_id"]],
      .y = data_fold_keys[["fold_id"]],
      .f = ~ {
        list_fold_context <-
          make_sjsdm_tuning_fold_context(
            data_assignments = data_assignments,
            repeat_id = .x,
            fold_id = .y
          )

        fit_seed <-
          (
            base::as.double(seed) +
              .x * 100000 +
              .y * 1000 +
              1L
          ) %% .Machine[["integer.max"]] |>
          base::as.integer()

        list_fold <-
          tryCatch(
            expr = {
              prepare_fold_function(
                train_indices = list_fold_context[["train_indices"]],
                test_indices = list_fold_context[["test_indices"]],
                repeat_id = .x,
                fold_id = .y
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

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

        if (
          base::inherits(list_fold, "error") ||
            !base::is.list(list_fold) ||
            !base::all(
              vec_required_fold_elements %in% base::names(list_fold)
            )
        ) {
          error_message <-
            if (
              base::inherits(list_fold, "error")
            ) {
              base::conditionMessage(list_fold)
            } else {
              "Fold preparation returned an invalid result."
            }

          data_predictions <-
            make_prediction_skeleton(
              list_fold_context = list_fold_context,
              prediction_status = "preparation_error"
            )

          data_diagnostics <-
            tibble::tibble(
              repeat_id = .x,
              fold_id = .y,
              candidate_id = candidate_id,
              fit_seed = fit_seed,
              n_train_samples =
                list_fold_context[["n_train_samples"]],
              n_test_samples = list_fold_context[["n_test_samples"]],
              n_taxa_retained = NA_integer_,
              n_effective_mev = NA_integer_,
              fit_status = "preparation_error",
              error_message = error_message,
              cv_strategy = list_fold_context[["cv_strategy"]],
              regularization_source = regularization_source
            )

          return(
            base::list(
              data_predictions = data_predictions,
              data_diagnostics = data_diagnostics
            )
          )
        }

        data_train_observed <-
          list_fold[["data_train_observed"]]

        data_test_observed <-
          list_fold[["data_test_observed"]]

        data_test_observed_full <-
          list_fold[["data_test_observed_full"]]

        vec_test_sample_ids <-
          list_fold[["test_sample_ids"]]

        data_taxa_mapping <-
          list_fold[["data_taxa_mapping"]]

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
            vec_mapping_columns %in%
              base::colnames(data_taxa_mapping)
          ) &&
          base::identical(
            base::colnames(data_test_observed_full),
            taxon_names
          ) &&
          base::identical(
            base::rownames(data_test_observed_full),
            vec_test_sample_ids
          ) &&
          base::identical(
            data_taxa_mapping[["taxon"]],
            taxon_names
          )

        if (
          !flag_valid_fold
        ) {
          data_predictions <-
            make_prediction_skeleton(
              list_fold_context = list_fold_context,
              prediction_status = "preparation_error"
            )

          data_diagnostics <-
            tibble::tibble(
              repeat_id = .x,
              fold_id = .y,
              candidate_id = candidate_id,
              fit_seed = fit_seed,
              n_train_samples =
                list_fold_context[["n_train_samples"]],
              n_test_samples = list_fold_context[["n_test_samples"]],
              n_taxa_retained = NA_integer_,
              n_effective_mev = NA_integer_,
              fit_status = "preparation_error",
              error_message =
                "Fold preparation outputs are not aligned.",
              cv_strategy = list_fold_context[["cv_strategy"]],
              regularization_source = regularization_source
            )

          return(
            base::list(
              data_predictions = data_predictions,
              data_diagnostics = data_diagnostics
            )
          )
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
          base::all(
            data_train_observed %in% base::c(0, 1)
          ) &&
          base::all(data_test_observed %in% base::c(0, 1)) &&
          base::all(
            data_test_observed_full %in% base::c(0, 1)
          )

        if (
          !flag_retained_aligned
        ) {
          cli::cli_abort(
            "Prepared response matrices are not aligned."
          )
        }

        vec_null_probability <-
          base::rep(NA_real_, base::length(taxon_names))

        base::names(vec_null_probability) <-
          taxon_names

        vec_null_probability[vec_retained_taxa] <-
          base::colMeans(data_train_observed)

        data_spatial_train <-
          list_fold[["data_train_input"]][["data_spatial_to_fit"]]

        n_effective_mev <-
          if (
            base::is.null(data_spatial_train)
          ) {
            0L
          } else {
            base::ncol(data_spatial_train)
          }

        mod_fit <-
          tryCatch(
            expr = {
              fit_function(
                data_train_input = list_fold[["data_train_input"]],
                candidate = data_candidate,
                seed = fit_seed
              )
            },
            error = function(error_condition) {
              error_condition
            }
          )

        data_predicted <-
          if (
            base::inherits(mod_fit, "error")
          ) {
            mod_fit
          } else {
            tryCatch(
              expr = {
                predict_function(
                  object = mod_fit,
                  data_test_input = list_fold[["data_test_input"]]
                )
              },
              error = function(error_condition) {
                error_condition
              }
            )
          }

        fold_status <-
          if (
            base::inherits(mod_fit, "error")
          ) {
            "fit_error"
          } else if (
            base::inherits(data_predicted, "error")
          ) {
            "prediction_error"
          } else {
            "ok"
          }

        error_message <-
          if (
            base::inherits(mod_fit, "error")
          ) {
            base::conditionMessage(mod_fit)
          } else if (
            base::inherits(data_predicted, "error")
          ) {
            base::conditionMessage(data_predicted)
          } else {
            NA_character_
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
            error_message <-
              "Predicted probabilities are not aligned."
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
          data_sample_ids_normalized |>
          dplyr::filter(
            .data[["row_index"]] %in%
              list_fold_context[["test_indices"]]
          )

        data_prediction_grid <-
          tidyr::crossing(
            data_test_samples,
            taxon = taxon_names
          )

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
              .data[["retained"]] & fold_status != "ok" ~
                fold_status,
              .data[["retained"]] ~ "ok",
              .default = .data[["taxon_status"]]
            ),
            repeat_id = .x,
            fold_id = .y
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
            repeat_id = .x,
            fold_id = .y,
            candidate_id = candidate_id,
            fit_seed = fit_seed,
            n_train_samples = base::nrow(data_train_observed),
            n_test_samples = base::nrow(data_test_observed_full),
            n_taxa_retained = base::length(vec_retained_taxa),
            n_effective_mev = base::as.integer(n_effective_mev),
            fit_status = fold_status,
            error_message = error_message,
            cv_strategy = list_fold_context[["cv_strategy"]],
            regularization_source = regularization_source
          )

        res_fold <-
          base::list(
            data_predictions = data_predictions,
            data_diagnostics = data_diagnostics
          )

        return(res_fold)
      }
    )

  data_predictions <-
    list_fold_results |>
    purrr::map("data_predictions") |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["row_index"]],
      base::match(.data[["taxon"]], taxon_names)
    )

  data_diagnostics <-
    list_fold_results |>
    purrr::map("data_diagnostics") |>
    purrr::list_rbind() |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  data_coverage <-
    data_predictions |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["row_index"]],
      .data[["taxon"]],
      name = "n_rows"
    )

  n_expected_rows <-
    base::sum(
      purrr::map_int(
        data_assignments[["row_indices"]],
        base::length
      )
    )

  if (
    base::nrow(data_coverage) !=
      n_expected_rows * base::length(taxon_names) ||
      base::any(data_coverage[["n_rows"]] != 1L)
  ) {
    cli::cli_abort(
      "Out-of-fold predictions do not provide complete row coverage."
    )
  }

  res <-
    base::list(
      data_predictions = data_predictions,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

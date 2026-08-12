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
    return(build_sjsdm_empty_selected_fold_artifacts())
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

  regularization_source <-
    data_selected_candidate[["regularization_source"]][[1L]]

  data_candidate <-
    data_selected_candidate |>
    dplyr::select(dplyr::all_of(vec_candidate_columns))

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  list_fold_results <-
    purrr::map2(
      .x = data_fold_keys[["repeat_id"]],
      .y = data_fold_keys[["fold_id"]],
      .f = function(repeat_id, fold_id) {
        list_fold_context <-
          build_sjsdm_tuning_fold_context(
            data_assignments = data_assignments,
            repeat_id = repeat_id,
            fold_id = fold_id
          )

        return(
          run_sjsdm_selected_fold(
            list_fold_context = list_fold_context,
            data_candidate = data_candidate,
            data_sample_ids = data_sample_ids_normalized,
            taxon_names = taxon_names,
            regularization_source = regularization_source,
            prepare_fold_function = prepare_fold_function,
            fit_function = fit_function,
            predict_function = predict_function,
            seed = seed
          )
        )
      }
    )

  res <-
    combine_sjsdm_selected_fold_artifacts(
      list_fold_results = list_fold_results,
      data_assignments = data_assignments,
      taxon_names = taxon_names
    )

  return(res)
}

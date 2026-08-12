#' @title Build Cached Selected sjSDM Folds
#' @description
#' Reconstructs the established selected-candidate OOF prediction and
#' diagnostic artifacts from tuning-time probabilities without fitting the
#' selected candidate again.
#' @param data_assignments,data_selected_candidate,data_sample_ids,taxon_names
#' Inputs accepted by [run_sjsdm_selected_candidate_folds()].
#' @param list_prediction_cache
#' Fold caches returned by [run_sjsdm_tuning_candidates()] when
#' `retain_prediction_cache = TRUE`.
#' @return
#' Named list with the unchanged `data_predictions` and `data_diagnostics`
#' public schemas. Diagnostic fit seeds identify the tuning fits that produced
#' the reused probabilities.
#' @examples
#' \dontrun{
#' build_sjsdm_cached_selected_folds(
#'   data_assignments = data_assignments,
#'   data_selected_candidate = data_selected_candidate,
#'   data_sample_ids = data_sample_ids,
#'   taxon_names = taxon_names,
#'   list_prediction_cache = list_prediction_cache
#' )
#' }
#' @export
build_sjsdm_cached_selected_folds <- function(
    data_assignments = NULL,
    data_selected_candidate = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    list_prediction_cache = NULL) {
  vec_selected_columns <-
    base::c(
      "candidate_id",
      "regularization_source"
    )

  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::is.data.frame(data_selected_candidate),
    base::nrow(data_selected_candidate) == 1L,
    base::all(
      vec_selected_columns %in%
        base::colnames(data_selected_candidate)
    ),
    base::is.data.frame(data_sample_ids),
    base::all(
      base::c("dataset_name", "age") %in%
        base::colnames(data_sample_ids)
    ),
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    base::is.list(list_prediction_cache),
    msg = "Cached selected-fold inputs are incomplete."
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

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  if (
    base::length(list_prediction_cache) !=
      base::nrow(data_fold_keys)
  ) {
    cli::cli_abort(
      "Prediction reuse requires one cache entry for every fold."
    )
  }

  if (
    base::nrow(data_fold_keys) == 0L
  ) {
    return(
      combine_sjsdm_selected_fold_artifacts(
        list_fold_results = base::list(),
        data_assignments = data_assignments,
        taxon_names = taxon_names
      )
    )
  }

  candidate_id <-
    data_selected_candidate[["candidate_id"]][[1L]]

  regularization_source <-
    data_selected_candidate[["regularization_source"]][[1L]]

  list_cache_records <-
    list_prediction_cache |>
    purrr::map(
      .f = function(list_cache) {
        vec_required_names <-
          base::c(
            "list_fold_context",
            "list_prepared_fold",
            "list_candidate_predictions"
          )

        if (
          !base::is.list(list_cache) ||
            !base::all(
              vec_required_names %in% base::names(list_cache)
            ) ||
            base::is.null(list_cache[["list_prepared_fold"]])
        ) {
          cli::cli_abort("A prediction-cache entry is incomplete.")
        }

        list_context <-
          list_cache[["list_fold_context"]]

        list_candidates <-
          list_cache[["list_candidate_predictions"]]

        if (
          !base::is.list(list_candidates)
        ) {
          cli::cli_abort("Cached candidate records must be a list.")
        }

        vec_cache_candidate_ids <-
          list_candidates |>
          purrr::map_chr("candidate_id")

        candidate_index <-
          base::which(vec_cache_candidate_ids == candidate_id)

        if (
          base::length(candidate_index) != 1L
        ) {
          cli::cli_abort(
            "Every fold cache must contain the selected candidate once."
          )
        }

        list_candidate <-
          list_candidates[[candidate_index]]

        vec_candidate_record_names <-
          base::c(
            "candidate_id",
            "fit_seed",
            "fit_status",
            "data_predicted"
          )

        if (
          !base::all(
            vec_candidate_record_names %in%
              base::names(list_candidate)
          ) ||
            !base::identical(list_candidate[["fit_status"]], "ok") ||
            !base::is.matrix(list_candidate[["data_predicted"]])
        ) {
          cli::cli_abort(
            "Selected cached predictions require successful tuning fits."
          )
        }

        return(
          base::list(
            repeat_id = list_context[["repeat_id"]],
            fold_id = list_context[["fold_id"]],
            list_fold_context = list_context,
            list_prepared_fold =
              list_cache[["list_prepared_fold"]],
            list_candidate = list_candidate
          )
        )
      }
    )

  data_cache_keys <-
    tibble::tibble(
      repeat_id = purrr::map_int(list_cache_records, "repeat_id"),
      fold_id = purrr::map_int(list_cache_records, "fold_id"),
      cache_index = base::seq_along(list_cache_records)
    )

  if (
    base::any(
      base::duplicated(data_cache_keys[base::c("repeat_id", "fold_id")])
    )
  ) {
    cli::cli_abort("Prediction-cache keys must be unique.")
  }

  data_cache_match <-
    data_fold_keys |>
    dplyr::left_join(
      data_cache_keys,
      by = dplyr::join_by(repeat_id, fold_id),
      relationship = "one-to-one"
    )

  if (
    base::any(base::is.na(data_cache_match[["cache_index"]]))
  ) {
    cli::cli_abort("Prediction-cache repeat and fold keys do not match.")
  }

  list_fold_results <-
    data_cache_match[["cache_index"]] |>
    purrr::map(
      .f = function(cache_index) {
        list_record <-
          list_cache_records[[cache_index]]

        list_prepared_fold <-
          list_record[["list_prepared_fold"]]

        n_effective_mev <-
          list_prepared_fold[["n_effective_mev"]]

        data_spatial_train <-
          if (
            base::is.null(n_effective_mev) ||
              n_effective_mev == 0L
          ) {
            NULL
          } else {
            base::matrix(
              data = 0,
              nrow = 1L,
              ncol = n_effective_mev
            )
          }

        list_prepared_fold[["data_train_input"]] <-
          base::list(data_spatial_to_fit = data_spatial_train)

        list_prepared_fold[["data_test_input"]] <-
          base::list()

        list_candidate <-
          list_record[["list_candidate"]]

        return(
          build_sjsdm_selected_fold_artifacts(
            list_prepared_fold = list_prepared_fold,
            list_fold_context =
              list_record[["list_fold_context"]],
            data_sample_ids = data_sample_ids_normalized,
            taxon_names = taxon_names,
            candidate_id = candidate_id,
            fit_seed = list_candidate[["fit_seed"]],
            regularization_source = regularization_source,
            data_predicted = list_candidate[["data_predicted"]],
            fold_status = "ok",
            error_message = NA_character_
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

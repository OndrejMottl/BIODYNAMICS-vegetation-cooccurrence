#' @title Assemble Cached Selected sjSDM Folds
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
#' assemble_sjsdm_cached_selected_folds(
#'   data_assignments = data_assignments,
#'   data_selected_candidate = data_selected_candidate,
#'   data_sample_ids = data_sample_ids,
#'   taxon_names = taxon_names,
#'   list_prediction_cache = list_prediction_cache
#' )
#' }
#' @export
assemble_sjsdm_cached_selected_folds <- function(
    data_assignments = NULL,
    data_selected_candidate = NULL,
    data_sample_ids = NULL,
    taxon_names = NULL,
    list_prediction_cache = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::is.data.frame(data_selected_candidate),
    base::nrow(data_selected_candidate) == 1L,
    "candidate_id" %in% base::colnames(data_selected_candidate),
    base::is.data.frame(data_sample_ids),
    base::is.character(taxon_names),
    base::length(taxon_names) > 0L,
    base::is.list(list_prediction_cache),
    msg = "Cached selected-fold inputs are incomplete."
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

  candidate_id <-
    data_selected_candidate[["candidate_id"]][[1L]]

  list_cache_records <-
    list_prediction_cache |>
    purrr::map(
      .f = ~ {
        vec_required_names <-
          base::c(
            "list_fold_context",
            "list_prepared_fold",
            "list_candidate_predictions"
          )

        if (
          !base::is.list(.x) ||
            !base::all(vec_required_names %in% base::names(.x)) ||
            base::is.null(.x[["list_prepared_fold"]])
        ) {
          cli::cli_abort("A prediction-cache entry is incomplete.")
        }

        list_context <-
          .x[["list_fold_context"]]

        list_candidates <-
          .x[["list_candidate_predictions"]]

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

        if (
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
            list_prepared_fold = .x[["list_prepared_fold"]],
            list_candidate = list_candidate
          )
        )
      }
    )

  data_cache_keys <-
    tibble::tibble(
      repeat_id = list_cache_records |>
        purrr::map_int("repeat_id"),
      fold_id = list_cache_records |>
        purrr::map_int("fold_id"),
      cache_index = base::seq_along(list_cache_records)
    )

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

  get_cache_record <- function(repeat_id, fold_id) {
    repeat_id_value <-
      repeat_id

    fold_id_value <-
      fold_id

    cache_index <-
      data_cache_keys |>
      dplyr::filter(
        .data[["repeat_id"]] == .env[["repeat_id_value"]],
        .data[["fold_id"]] == .env[["fold_id_value"]]
      ) |>
      dplyr::pull("cache_index")

    if (
      base::length(cache_index) != 1L
    ) {
      cli::cli_abort("Prediction-cache keys must be unique.")
    }

    return(list_cache_records[[cache_index]])
  }

  prepare_fold_function <- function(
      train_indices,
      test_indices,
      repeat_id,
      fold_id) {
    list_record <-
      get_cache_record(
        repeat_id = repeat_id,
        fold_id = fold_id
      )

    list_prepared <-
      list_record[["list_prepared_fold"]]

    n_effective_mev <-
      list_prepared[["n_effective_mev"]]

    data_spatial_train <-
      if (
        base::is.null(n_effective_mev) || n_effective_mev == 0L
      ) {
        NULL
      } else {
        base::matrix(
          data = 0,
          nrow = 1L,
          ncol = n_effective_mev
        )
      }

    list_prepared[["data_train_input"]] <-
      base::list(
        data_spatial_to_fit = data_spatial_train,
        list_cached_candidate = list_record[["list_candidate"]]
      )

    list_prepared[["data_test_input"]] <-
      base::list()

    return(list_prepared)
  }

  fit_function <- function(data_train_input, candidate, seed) {
    return(data_train_input[["list_cached_candidate"]])
  }

  predict_function <- function(object, data_test_input) {
    return(object[["data_predicted"]])
  }

  res <-
    run_sjsdm_selected_candidate_folds(
      data_assignments = data_assignments,
      data_selected_candidate = data_selected_candidate,
      data_sample_ids = data_sample_ids,
      taxon_names = taxon_names,
      prepare_fold_function = prepare_fold_function,
      fit_function = fit_function,
      predict_function = predict_function,
      seed = 0L
    )

  data_fit_seeds <-
    list_cache_records |>
    purrr::map(
      .f = ~ tibble::tibble(
        repeat_id = .x[["repeat_id"]],
        fold_id = .x[["fold_id"]],
        cached_fit_seed =
          .x[["list_candidate"]][["fit_seed"]]
      )
    ) |>
    purrr::list_rbind()

  res[["data_diagnostics"]] <-
    res[["data_diagnostics"]] |>
    dplyr::select(-"fit_seed") |>
    dplyr::left_join(
      data_fit_seeds,
      by = dplyr::join_by(repeat_id, fold_id),
      relationship = "one-to-one"
    ) |>
    dplyr::rename(fit_seed = "cached_fit_seed") |>
    dplyr::relocate("fit_seed", .after = "candidate_id")

  return(res)
}

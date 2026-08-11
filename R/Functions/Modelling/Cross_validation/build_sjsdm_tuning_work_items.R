#' @title Build sjSDM Tuning Work Items
#' @description
#' Builds deterministic repeat, fold, and candidate work items for granular
#' cross-validation execution and restart.
#' @param data_assignments
#' Cross-validation assignments accepted by
#' [run_sjsdm_tuning_candidates()].
#' @param data_candidates
#' Candidate table returned by
#' [build_sjsdm_regularization_candidates()].
#' @param seed
#' Non-negative base integer used by the tuning engine.
#' @return
#' Tibble with one row per repeat, fold, and candidate. `work_item_id` is a
#' deterministic digest of the fold membership, candidate parameters, and
#' base seed.
#' @export
build_sjsdm_tuning_work_items <- function(
    data_assignments = NULL,
    data_candidates = NULL,
    seed = 900723L) {
  vec_assignment_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "location_id",
      "n_samples",
      "row_indices"
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

  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::all(
      vec_assignment_columns %in% base::colnames(data_assignments)
    ),
    base::is.data.frame(data_candidates),
    base::nrow(data_candidates) > 0L,
    base::all(
      base::c("candidate_id", vec_parameter_columns) %in%
        base::colnames(data_candidates)
    ),
    msg = "Tuning work-item inputs are incomplete."
  )

  flag_valid_seed <-
    base::is.numeric(seed) &&
    base::length(seed) == 1L &&
    base::is.finite(seed) &&
    seed >= 0L &&
    seed <= .Machine[["integer.max"]] &&
    seed == base::as.integer(seed)

  assertthat::assert_that(
    flag_valid_seed,
    msg = "seed must be one non-negative integer."
  )

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  if (
    base::nrow(data_fold_keys) == 0L
  ) {
    return(
      tibble::tibble(
        work_item_id = base::character(),
        fold_key = base::character(),
        repeat_id = base::integer(),
        fold_id = base::integer(),
        candidate_id = base::character(),
        alpha_cov = base::numeric(),
        alpha_coef = base::numeric(),
        alpha_spatial = base::numeric(),
        lambda_cov = base::numeric(),
        lambda_coef = base::numeric(),
        lambda_spatial = base::numeric(),
        tuning_seed = base::integer()
      )
    )
  }

  data_candidates_ordered <-
    data_candidates |>
    dplyr::arrange(.data[["candidate_id"]]) |>
    dplyr::select("candidate_id", dplyr::all_of(vec_parameter_columns))

  data_work_items <-
    tidyr::crossing(
      data_fold_keys,
      data_candidates_ordered
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::mutate(
      fold_key = stringr::str_glue(
        "repeat_{stringr::str_pad(.data[['repeat_id']], 3L, 'left', '0')}__",
        "fold_{stringr::str_pad(.data[['fold_id']], 3L, 'left', '0')}"
      ),
      tuning_seed = base::as.integer(seed),
      work_item_id = purrr::pmap_chr(
        dplyr::pick(dplyr::everything()),
        .f = function(...) {
          list_item <-
            base::list(...)

          repeat_id <-
            list_item[["repeat_id"]]

          fold_id <-
            list_item[["fold_id"]]

          data_fold_assignments <-
            data_assignments |>
            dplyr::filter(
              .data[["repeat_id"]] == .env[["repeat_id"]],
              .data[["fold_id"]] == .env[["fold_id"]]
            ) |>
            dplyr::arrange(.data[["location_id"]])

          identity_payload <-
            base::list(
              strategy_version = "sjsdm_cv_work_item_v1",
              seed = base::as.integer(seed),
              repeat_id = repeat_id,
              fold_id = fold_id,
              candidate_id = list_item[["candidate_id"]],
              candidate_parameters = base::unlist(
                list_item[vec_parameter_columns],
                use.names = TRUE
              ),
              held_out_locations =
                data_fold_assignments[["location_id"]],
              held_out_rows = data_fold_assignments[["row_indices"]]
            )

          return(
            stringr::str_c(
              "sjsdm_cv_",
              digest::digest(
                identity_payload,
                algo = "xxhash64"
              )
            )
          )
        }
      ),
      .before = 1L
    )

  return(data_work_items)
}

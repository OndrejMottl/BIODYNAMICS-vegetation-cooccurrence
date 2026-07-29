#' @title Interpolate Paleo Community Data with Age Uncertainty
#' @description
#' Interpolates paleo community proportions to a regular time grid while
#' incorporating per-sample age-model iterations for fossil pollen archives.
#' Datasets without age-uncertainty records are interpolated using consensus
#' ages. Fossil pollen archives are interpolated across their age-model
#' iterations and reduced to the median proportion at each grid point.
#' @param data_community
#' A data frame with columns `dataset_name`, `sample_name`, `taxon`,
#' `age`, and `value`. Must already be in proportion form — see
#' [prepare_community_proportions()].
#' @param data_age_uncertainty
#' A tibble produced by [extract_age_uncertainty_from_vegvault()],
#' with columns `dataset_name` (character), `sample_name` (character),
#' `iteration` (integer), and `age_uncertainty` (double). Rows for
#' dataset names absent from `data_community` are silently ignored.
#' @param n_cores
#' Number of workers to use for consensus-age interpolation. Fossil-core
#' parallelism is handled by dynamic `{targets}` branches in the paleo
#' pipeline; use `1` for branched fossil inputs.
#' @param max_expanded_rows
#' Maximum approximate number of expanded fossil observation rows
#' processed in one interpolation batch (default: `4e6`). Lower
#' values reduce peak memory use at the cost of more interpolation
#' calls.
#' @param ...
#' Additional arguments passed to [interpolate_grouped_time_series()], such as
#' `time_step`, `age_min`, and `age_max`.
#' @return
#' A data frame with columns `dataset_name`, `taxon`, `age`, and
#' `value` at regular time intervals. For fossil pollen archive
#' datasets, `value` is the median across age-model iterations.
#' @details
#' Datasets present in `data_community` that have no matching rows in
#' `data_age_uncertainty` are treated as gridpoints and interpolated
#' using consensus ages. This ensures the function degrades gracefully
#' when age uncertainty data are partially available.
#'
#' The uncertainty-aware interpolation proceeds as follows for each
#' fossil core:
#'   1. The consensus `age` column is dropped and replaced with
#'      `age_uncertainty` (renamed to `age`) from
#'      `data_age_uncertainty`, expanding the data to one row per
#'      original observation per age-model iteration.
#'   2. [interpolate_grouped_time_series()] is called grouped by
#'      `c("dataset_name", "taxon", "iteration")`.
#'   3. The median `value` across iterations is computed for
#'      each `(dataset_name, taxon, age)` combination.
#'
#' Fossil cores are joined and interpolated one dataset at a time, in
#' bounded batches of age-model iterations, before each core is reduced.
#' This bounds the expansion in continental runs, where joining all cores
#' simultaneously can exceed available memory.
#'
#' In the paleo pipelines, inputs are split into one dynamic target branch
#' per dataset before this function is called. `{targets}` therefore
#' caches reduced core outputs and schedules parallel work externally.
#' @examples
#' data_community <- tibble::tibble(
#'   dataset_name = base::rep("core_a", 2L),
#'   sample_name = base::c("sample_1", "sample_2"),
#'   taxon = base::rep("Taxon", 2L),
#'   age = base::c(0, 100),
#'   value = base::c(0.25, 0.75)
#' )
#' data_age_uncertainty <- tibble::tibble(
#'   dataset_name = base::character(),
#'   sample_name = base::character(),
#'   iteration = base::integer(),
#'   age_uncertainty = base::numeric()
#' )
#' interpolate_paleo_community_with_age_uncertainty(
#'   data_community = data_community,
#'   data_age_uncertainty = data_age_uncertainty,
#'   age_min = 0,
#'   age_max = 100,
#'   time_step = 100
#' )
#' @seealso
#'   [extract_age_uncertainty_from_vegvault()],
#'   [interpolate_grouped_time_series()]
#' @export
interpolate_paleo_community_with_age_uncertainty <- function(
    data_community,
    data_age_uncertainty,
    n_cores = 1L,
    max_expanded_rows = 4e06,
    ...) {
  #-- Validate community data -------------------------------------------------

  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  vec_required_community_columns <-
    base::c(
      "dataset_name", "sample_name", "taxon", "age", "value"
    )

  vec_missing_community_columns <-
    base::setdiff(
      vec_required_community_columns,
      base::colnames(data_community)
    )

  assertthat::assert_that(
    base::length(vec_missing_community_columns) == 0L,
    msg = stringr::str_glue(
      "data_community must contain columns: ",
      "{stringr::str_c(vec_required_community_columns, collapse = ', ')}"
    )
  )

  #-- Validate data_age_uncertainty -------------------------------------------

  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty),
    msg = "'data_age_uncertainty' must be a data frame"
  )

  vec_required_uncertainty_columns <-
    base::c(
      "dataset_name", "sample_name", "iteration", "age_uncertainty"
    )

  vec_missing_uncertainty_columns <-
    base::setdiff(
      vec_required_uncertainty_columns,
      base::colnames(data_age_uncertainty)
    )

  assertthat::assert_that(
    base::length(vec_missing_uncertainty_columns) == 0L,
    msg = stringr::str_glue(
      "data_age_uncertainty must contain columns: ",
      "{stringr::str_c(vec_required_uncertainty_columns, collapse = ', ')}"
    )
  )

  assertthat::assert_that(
    base::is.numeric(max_expanded_rows) &&
      base::length(max_expanded_rows) == 1L &&
      base::is.finite(max_expanded_rows) &&
      max_expanded_rows >= 1 &&
      max_expanded_rows == base::as.integer(max_expanded_rows),
    msg = "max_expanded_rows must be a single positive integer"
  )

  assertthat::assert_that(
    base::is.numeric(n_cores) &&
      base::length(n_cores) == 1L &&
      base::is.finite(n_cores) &&
      n_cores >= 1 &&
      n_cores == base::as.integer(n_cores),
    msg = "n_cores must be a single positive integer"
  )

  n_cores_integer <-
    base::as.integer(n_cores)

  max_expanded_rows_integer <-
    base::as.integer(max_expanded_rows)

  #-- Split into gridpoints and fossil cores ----------------------------------

  vec_uncertain_age_datasets <-
    dplyr::pull(data_age_uncertainty, dataset_name) |>
    base::unique()

  data_community_consensus_age <-
    data_community |>
    dplyr::filter(!dataset_name %in% vec_uncertain_age_datasets)

  data_community_uncertain_age <-
    data_community |>
    dplyr::filter(dataset_name %in% vec_uncertain_age_datasets)

  list_interpolation_arguments <-
    rlang::list2(...)

  #-- Interpolate gridpoints using consensus ages -----------------------------

  empty_result <-
    tibble::tibble(
      dataset_name = base::character(),
      taxon = base::character(),
      age = base::numeric(),
      value = base::numeric()
    )

  data_community_consensus_age_interpolated <-
    if (
      base::nrow(data_community_consensus_age) > 0L
    ) {
      interpolate_grouped_time_series(
        data_time_series = data_community_consensus_age,
        grouping_variables = base::c("dataset_name", "taxon"),
        n_cores = n_cores_integer,
        ...
      )
    } else {
      empty_result
    }

  #-- Interpolate fossil cores using per-iteration age estimates --------------

  data_community_uncertain_age_interpolated <-
    if (
      base::nrow(data_community_uncertain_age) > 0L
    ) {
      data_community_uncertain_age_nested <-
        data_community_uncertain_age |>
        dplyr::select(
          "dataset_name", "sample_name", "taxon", "value"
        ) |>
        tidyr::nest(
          data_community = -dataset_name
        ) |>
        dplyr::inner_join(
          data_age_uncertainty |>
            tidyr::nest(data_age_uncertainty = -dataset_name),
          by = dplyr::join_by(dataset_name)
        )

      list_community_uncertain_age_interpolated <-
        purrr::pmap(
          .l = base::list(
            dataset_name = dplyr::pull(
              data_community_uncertain_age_nested,
              dataset_name
            ),
            data_community = dplyr::pull(
              data_community_uncertain_age_nested,
              data_community
            ),
            data_age_uncertainty = dplyr::pull(
              data_community_uncertain_age_nested,
              data_age_uncertainty
            )
          ),
          .f = .summarise_fossil_core_age_iterations,
          max_expanded_rows = max_expanded_rows_integer,
          list_interpolation_arguments = list_interpolation_arguments,
          interpolate_grouped_time_series_function =
            interpolate_grouped_time_series
        )

      data_community_uncertain_age_nested |>
        dplyr::mutate(
          data_interpolated =
            list_community_uncertain_age_interpolated
        ) |>
        dplyr::select(data_interpolated) |>
        tidyr::unnest(data_interpolated)
    } else {
      empty_result
    }

  #-- Combine and return ------------------------------------------------------

  dplyr::bind_rows(
    data_community_consensus_age_interpolated,
    data_community_uncertain_age_interpolated
  ) |>
    base::return()
}

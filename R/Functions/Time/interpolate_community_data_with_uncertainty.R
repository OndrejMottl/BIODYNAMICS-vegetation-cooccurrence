#' @title Interpolate Community Data with Age Uncertainty
#' @description
#' Interpolates community proportion data to a regular time grid,
#' incorporating per-sample age-model iteration data for fossil pollen
#' archive datasets. Gridpoint datasets (which have no age uncertainty)
#' are interpolated using their consensus ages via
#' [interpolate_community_data()]. Fossil pollen archive datasets are
#' interpolated across all age-model iterations and the median
#' proportion is returned at each grid point.
#' @param data
#' A data frame with columns `dataset_name`, `sample_name`, `taxon`,
#' `age`, and `value`. Must already be in proportion form — see
#' [make_community_proportions()].
#' @param data_age_uncertainty
#' A tibble produced by [extract_age_uncertainty_from_vegvault()],
#' with columns `dataset_name` (character), `sample_name` (character),
#' `iteration` (integer), and `age_uncertainty` (double). Rows for
#' dataset names absent from `data` are silently ignored.
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
#' Additional arguments passed to [interpolate_data()] and
#' [interpolate_community_data()], such as `timestep`, `age_min`,
#' and `age_max`.
#' @return
#' A data frame with columns `dataset_name`, `taxon`, `age`, and
#' `value` at regular time intervals. For fossil pollen archive
#' datasets, `value` is the median across age-model iterations.
#' @details
#' Datasets present in `data` that have no matching rows in
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
#'   2. [interpolate_data()] is called grouped by
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
#' @seealso
#'   [interpolate_community_data()],
#'   [extract_age_uncertainty_from_vegvault()],
#'   [interpolate_data()]
#' @export
interpolate_community_data_with_uncertainty <- function(
    data,
    data_age_uncertainty,
    n_cores = 1,
    max_expanded_rows = 4e06,
    ...) {
  #-- Validate data -----------------------------------------------------------

  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame"
  )

  vec_required_data_cols <-
    base::c(
      "dataset_name", "sample_name", "taxon", "age", "value"
    )

  for (col in vec_required_data_cols) {
    assertthat::assert_that(
      col %in% base::colnames(data),
      msg = base::paste0(
        "'data' must contain a '", col, "' column"
      )
    )
  }

  #-- Validate data_age_uncertainty -------------------------------------------

  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty),
    msg = "'data_age_uncertainty' must be a data frame"
  )

  vec_required_unc_cols <-
    base::c(
      "dataset_name", "sample_name", "iteration", "age_uncertainty"
    )

  for (col in vec_required_unc_cols) {
    assertthat::assert_that(
      col %in% base::colnames(data_age_uncertainty),
      msg = base::paste0(
        "'data_age_uncertainty' must contain a '", col, "' column"
      )
    )
  }

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

  n_cores <-
    base::as.integer(n_cores)

  #-- Split into gridpoints and fossil cores ----------------------------------

  vec_core_datasets <-
    dplyr::pull(data_age_uncertainty, dataset_name) |>
    base::unique()

  data_gridpoints <-
    data |>
    dplyr::filter(!dataset_name %in% vec_core_datasets)

  data_cores <-
    data |>
    dplyr::filter(dataset_name %in% vec_core_datasets)

  list_interpolation_arguments <-
    rlang::list2(...)

  interpolate_fossil_core <- function(
      dataset_name_i,
      data_community_i,
      data_uncertainty_i) {
    n_iterations_per_batch <-
      base::max(
        1L,
        base::as.integer(
          max_expanded_rows /
            base::nrow(data_community_i)
        )
      )

    vec_iterations <-
      data_uncertainty_i |>
      dplyr::pull(iteration) |>
      base::unique()

    list_iteration_batches <-
      vec_iterations |>
      base::split(
        base::ceiling(
          base::seq_along(vec_iterations) /
            n_iterations_per_batch
        )
      )

    res_core <-
      list_iteration_batches |>
      purrr::map(
        .f = ~ {
          data_core_expanded <-
            data_community_i |>
            dplyr::inner_join(
              data_uncertainty_i |>
                dplyr::filter(iteration %in% .x),
              by = dplyr::join_by(sample_name),
              relationship = "many-to-many"
            ) |>
            dplyr::mutate(dataset_name = dataset_name_i) |>
            dplyr::rename(age = age_uncertainty) |>
            dplyr::filter(!base::is.na(age))

          rlang::exec(
            .fn = interpolate_data_function,
            data = data_core_expanded,
            !!!list_interpolation_arguments,
            by = base::c(
              "dataset_name", "taxon", "iteration"
            ),
            n_cores = 1L
          )
        }
      ) |>
      purrr::list_rbind() |>
      dplyr::summarise(
        value = stats::median(value, na.rm = TRUE),
        .by = dplyr::all_of(
          base::c("dataset_name", "taxon", "age")
        )
      ) |>
      dplyr::filter(!base::is.na(value))

    base::return(res_core)
  }

  # Avoid retaining the complete target environment when this helper runs
  # inside a dynamic branch.
  base::environment(interpolate_fossil_core) <-
    rlang::env(
      base::baseenv(),
      interpolate_data_function = interpolate_data,
      list_interpolation_arguments = list_interpolation_arguments,
      max_expanded_rows = max_expanded_rows
    )

  #-- Interpolate gridpoints using consensus ages -----------------------------

  empty_result <-
    tibble::tibble(
      dataset_name = base::character(),
      taxon = base::character(),
      age = base::numeric(),
      value = base::numeric()
    )

  result_gridpoints <-
    if (
      base::nrow(data_gridpoints) > 0L
    ) {
      interpolate_community_data(
        data = data_gridpoints,
        n_cores = n_cores,
        ...
      )
    } else {
      empty_result
    }

  #-- Interpolate fossil cores using per-iteration age estimates --------------

  result_cores <-
    if (
      base::nrow(data_cores) > 0L
    ) {
      data_cores_nested <-
        data_cores |>
        dplyr::select(
          "dataset_name", "sample_name", "taxon", "value"
        ) |>
        tidyr::nest(
          data_community = -dataset_name
        ) |>
        dplyr::inner_join(
          data_age_uncertainty |>
            tidyr::nest(data_uncertainty = -dataset_name),
          by = dplyr::join_by(dataset_name)
        )

      list_interpolated_cores <-
        purrr::pmap(
          .l = base::list(
            dplyr::pull(data_cores_nested, dataset_name),
            dplyr::pull(data_cores_nested, data_community),
            dplyr::pull(data_cores_nested, data_uncertainty)
          ),
          .f = interpolate_fossil_core
        )

      data_cores_nested |>
        dplyr::mutate(data_interpolated = list_interpolated_cores) |>
        dplyr::select(data_interpolated) |>
        tidyr::unnest(data_interpolated)
    } else {
      empty_result
    }

  #-- Combine and return ------------------------------------------------------

  dplyr::bind_rows(
    result_gridpoints,
    result_cores
  ) |>
    base::return()
}

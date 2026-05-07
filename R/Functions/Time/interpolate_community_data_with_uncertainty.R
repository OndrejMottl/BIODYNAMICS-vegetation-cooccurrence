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
#' @seealso
#'   [interpolate_community_data()],
#'   [extract_age_uncertainty_from_vegvault()],
#'   [interpolate_data()]
#' @export
interpolate_community_data_with_uncertainty <- function(
    data,
    data_age_uncertainty,
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
      interpolate_community_data(data = data_gridpoints, ...)
    } else {
      empty_result
    }

  #-- Interpolate fossil cores using per-iteration age estimates --------------

  result_cores <-
    if (
      base::nrow(data_cores) > 0L
    ) {
      data_cores |>
        dplyr::select(
          "dataset_name", "sample_name", "taxon", "value"
        ) |>
        dplyr::inner_join(
          data_age_uncertainty,
          by = base::c("dataset_name", "sample_name"),
          relationship = "many-to-many"
        ) |>
        dplyr::rename(age = age_uncertainty) |>
        dplyr::filter(!base::is.na(age)) |>
        interpolate_data(
          by = base::c("dataset_name", "taxon", "iteration"),
          ...
        ) |>
        dplyr::summarise(
          value = stats::median(value, na.rm = TRUE),
          .by = dplyr::all_of(
            base::c("dataset_name", "taxon", "age")
          )
        ) |>
        dplyr::filter(!base::is.na(value))
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

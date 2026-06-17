#' @title Extract Age Uncertainty from VegVault
#' @description
#' Retrieves per-sample age-model iteration data from a pre-built
#' vaultkeepr query plan and joins the result to a caller-supplied
#' sample-to-dataset mapping.
#' @param plan
#' A vaultkeepr plan object scoped to fossil pollen archive datasets,
#' typically created by `build_vegvault_plan()` with
#' `sel_dataset_type = "fossil_pollen_archive"`.
#' @param data_sample_mapping
#' A data frame with at least the columns `dataset_name` and
#' `sample_name`, used to attach dataset identifiers to the
#' per-iteration age estimates (e.g. `data_community_proportions`).
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`.
#' @return
#' A tibble with columns `dataset_name` (character), `sample_name`
#' (character), `iteration` (integer), and `age_uncertainty`
#' (numeric). Each row is one age-model iteration estimate for one
#' sample. Returns an empty tibble with those columns when no age
#' uncertainty data are available.
#' @details
#' The function performs the following steps:
#'   1. Validates inputs.
#'   2. Retrieves age uncertainty via
#'      `vaultkeepr::get_age_uncertainty()`.
#'   3. Pivots the wide output (one column per iteration) to long
#'      format and filters NA age estimates.
#'   4. Joins with `data_sample_mapping` to attach `dataset_name`.
#'
#' Input validation and plan construction (geographic/temporal
#' filters, dataset type selection) are handled by
#' `build_vegvault_plan()`. Only `fossil_pollen_archive` datasets
#' carry per-iteration age estimates; modern plot/gridpoint datasets
#' have no age uncertainty.
#' @seealso
#'   [build_vegvault_plan()],
#'   [extract_data_from_vegvault()],
#'   [interpolate_community_data_with_uncertainty()]
#' @export
extract_age_uncertainty_from_vegvault <- function(
    plan,
    data_sample_mapping,
    verbose = TRUE) {
  #-- Validate inputs ----------------------------------------------------------

  assertthat::assert_that(
    !base::is.null(plan),
    msg = stringr::str_c(
      "'plan' must not be NULL;",
      " use build_vegvault_plan() to create one"
    )
  )

  assertthat::assert_that(
    base::inherits(data_sample_mapping, "data.frame"),
    msg = "'data_sample_mapping' must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "sample_name") %in%
        base::colnames(data_sample_mapping)
    ),
    msg = stringr::str_c(
      "'data_sample_mapping' must contain columns",
      " 'dataset_name' and 'sample_name'"
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) && base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value"
  )

  #-- Empty result template ----------------------------------------------------

  empty_result <-
    tibble::tibble(
      dataset_name = base::character(),
      sample_name = base::character(),
      iteration = base::integer(),
      age_uncertainty = base::numeric()
    )

  #-- Retrieve age uncertainty -------------------------------------------------

  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform("Retrieving age-model iterations")
  }

  data_unc_wide <-
    suppressMessages(
      vaultkeepr::get_age_uncertainty(con = plan)
    )

  if (
    base::nrow(data_unc_wide) == 0L
  ) {
    return(empty_result)
  }

  #-- Pivot to long format and drop NA age estimates ---------------------------

  data_unc_long <-
    data_unc_wide |>
    tidyr::pivot_longer(
      cols = -sample_name,
      names_to = "iteration",
      names_prefix = "iteration_",
      values_to = "age_uncertainty"
    ) |>
    dplyr::mutate(
      iteration = base::as.integer(iteration),
      age_uncertainty = base::as.double(age_uncertainty)
    ) |>
    dplyr::filter(!base::is.na(age_uncertainty))

  if (
    base::nrow(data_unc_long) == 0L
  ) {
    return(empty_result)
  }

  #-- Extract distinct sample-to-dataset mapping -------------------------------

  data_mapping_distinct <-
    data_sample_mapping |>
    dplyr::select("dataset_name", "sample_name") |>
    dplyr::distinct()

  #-- Join dataset_name and return ---------------------------------------------

  data_result <-
    data_unc_long |>
    dplyr::inner_join(
      data_mapping_distinct,
      by = dplyr::join_by(sample_name),
      multiple = "all",
      unmatched = "drop"
    ) |>
    dplyr::select(
      "dataset_name",
      "sample_name",
      "iteration",
      "age_uncertainty"
    )

  if (
    isTRUE(verbose)
  ) {
    n_rows <-
      base::nrow(data_result)

    n_datasets <-
      dplyr::n_distinct(
        dplyr::pull(data_result, "dataset_name")
      )

    cli::cli_inform(
      c(
        "v" = stringr::str_glue(
          "Retrieved {n_rows} rows for {n_datasets} dataset(s)."
        )
      )
    )
  }

  return(data_result)
}

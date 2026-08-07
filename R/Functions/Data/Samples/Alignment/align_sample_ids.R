#' @title Align Sample IDs Across Data Streams
#' @description
#' Computes the intersection of valid `(dataset_name, age)` pairs
#' present in all three data sources: community (long format),
#' abiotic (long format), and coordinate data. The returned table
#' serves as the canonical sample index used by all subsequent
#' data-preparation functions.
#' @param data_community_long
#' A data frame in long format containing at least the columns
#' `dataset_name` and `age`.
#' @param data_abiotic_long
#' A data frame in long format containing at least the columns
#' `dataset_name` and `age`.
#' @param data_coords
#' A data frame of spatial coordinates with `dataset_name` stored
#' as row names and columns `coord_long` and `coord_lat`.
#' @param subset_age
#' Optional numeric vector specifying age(s) to retain. If `NULL`
#' (default) all intersecting ages are kept.
#' @return
#' A data frame with columns `dataset_name` and `age`, containing
#' only the `(dataset_name, age)` pairs present in all three
#' inputs, arranged by `dataset_name` then `age`. When
#' `subset_age` is supplied the result is further filtered to
#' those ages.
#' @details
#' All three-way intersection logic is performed while the data
#' remain in long (tidy) format, so no rowname parsing is needed.
#' Passing a `subset_age` value here — rather than inside a
#' downstream modelling function — makes the subsetting explicit
#' and cacheable as a pipeline target.
#' @seealso [prepare_community_for_fit()],
#'   [prepare_abiotic_for_fit()], [prepare_coords_for_fit()]
#' @export
align_sample_ids <- function(
    data_community_long = NULL,
    data_abiotic_long = NULL,
    data_coords = NULL,
    subset_age = NULL) {
  assertthat::assert_that(
    is.data.frame(data_community_long),
    msg = "data_community_long must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_abiotic_long),
    msg = "data_abiotic_long must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_coords),
    msg = "data_coords must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_community_long)),
    msg = paste0(
      "data_community_long must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_abiotic_long)),
    msg = paste0(
      "data_abiotic_long must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  # 1. Extract distinct (dataset_name, age) pairs -----

  data_community_ids <-
    data_community_long |>
    dplyr::distinct(dataset_name, age)

  data_abiotic_ids <-
    data_abiotic_long |>
    dplyr::distinct(dataset_name, age)

  data_coords_ids <-
    data_coords |>
    tibble::rownames_to_column("dataset_name") |>
    dplyr::distinct(dataset_name)

  # 2. Three-way intersection -----

  res <-
    dplyr::inner_join(
      data_community_ids,
      data_abiotic_ids,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    dplyr::inner_join(
      data_coords_ids,
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(dataset_name, age)

  # 3. Optionally subset by age -----

  if (
    !is.null(subset_age)
  ) {
    assertthat::assert_that(
      is.numeric(subset_age),
      msg = "subset_age must be numeric"
    )

    res <-
      res |>
      dplyr::filter(age %in% subset_age)
  }

  return(res)
}

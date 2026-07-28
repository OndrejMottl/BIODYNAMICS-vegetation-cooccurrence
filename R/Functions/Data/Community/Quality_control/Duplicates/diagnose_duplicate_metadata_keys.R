#' @title Diagnose Duplicate Modern Metadata Keys
#' @description
#' Returns duplicated modern community, sample-age, and coordinate keys.
#' @param data_community
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_sample_ages
#' A sample-age data frame with `dataset_name`, `sample_name`, and `age`
#' columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names.
#' @return
#' A tibble describing duplicated metadata keys. Returns a zero-row tibble
#' when no duplicate keys are detected.
#' @export
diagnose_duplicate_metadata_keys <- function(
    data_community = NULL,
    data_sample_ages = NULL,
    data_coordinates = NULL) {
  validate_community_source(
    data_source = data_community,
    check_numeric = FALSE
  )

  assertthat::assert_that(
    base::is.data.frame(data_sample_ages),
    msg = "data_sample_ages must be a data frame."
  )
  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "sample_name", "age") %in%
        base::names(data_sample_ages)
    ),
    msg = stringr::str_c(
      "data_sample_ages must contain columns: ",
      "dataset_name, sample_name, and age."
    )
  )

  data_coordinates_named <-
    normalize_coordinates(data_source = data_coordinates)

  data_duplicate_community_keys <-
    data_community |>
    dplyr::group_by(dataset_name, sample_name, age, taxon) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::filter(n_records > 1L) |>
    dplyr::mutate(source = "community_record") |>
    dplyr::select(
      source,
      dataset_name,
      sample_name,
      age,
      taxon,
      n_records
    )

  data_duplicate_sample_age_keys <-
    data_sample_ages |>
    dplyr::group_by(dataset_name, sample_name) |>
    dplyr::summarise(
      age = dplyr::first(age),
      n_records = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::filter(n_records > 1L) |>
    dplyr::mutate(
      source = "sample_age",
      taxon = NA_character_
    ) |>
    dplyr::select(
      source,
      dataset_name,
      sample_name,
      age,
      taxon,
      n_records
    )

  data_duplicate_coordinate_keys <-
    data_coordinates_named |>
    dplyr::group_by(dataset_name) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::filter(n_records > 1L) |>
    dplyr::mutate(
      source = "coordinate",
      sample_name = NA_character_,
      age = NA_real_,
      taxon = NA_character_
    ) |>
    dplyr::select(
      source,
      dataset_name,
      sample_name,
      age,
      taxon,
      n_records
    )

  res_duplicate_metadata_keys <-
    dplyr::bind_rows(
      data_duplicate_community_keys,
      data_duplicate_sample_age_keys,
      data_duplicate_coordinate_keys
    ) |>
    dplyr::mutate(
      source = base::factor(
        source,
        levels = base::c(
          "community_record", "sample_age", "coordinate"
        )
      )
    ) |>
    dplyr::arrange(source, dataset_name, sample_name, age, taxon) |>
    dplyr::mutate(source = base::as.character(source))

  return(res_duplicate_metadata_keys)
}

#' @title Check Modern Data Impossible Values
#' @description
#' Checks modern community and coordinate data for impossible values before
#' modelling.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_coordinates
#' A coordinate data frame with `coord_long` and `coord_lat` columns. Dataset
#' names may be stored either in a `dataset_name` column or row names.
#' @return
#' A tibble describing impossible values. Returns a zero-row tibble when no
#' impossible values are detected.
#' @export
check_modern_data_impossible_values <- function(
    data_source = NULL,
    data_coordinates = NULL) {
  validate_community_source(data_source = data_source)

  data_coordinates_named <-
    normalize_coordinates(data_source = data_coordinates)

  assertthat::assert_that(
    base::is.numeric(dplyr::pull(data_coordinates_named, coord_long)),
    msg = "coord_long must be numeric."
  )
  assertthat::assert_that(
    base::is.numeric(dplyr::pull(data_coordinates_named, coord_lat)),
    msg = "coord_lat must be numeric."
  )

  data_bad_pollen <-
    data_source |>
    dplyr::filter(
      base::is.na(pollen_count) |
        !base::is.finite(pollen_count) |
        pollen_count < 0
    ) |>
    dplyr::mutate(
      source = "community",
      issue = dplyr::case_when(
        base::is.na(pollen_count) ~ "missing_pollen_count",
        !base::is.finite(pollen_count) ~ "non_finite_pollen_count",
        pollen_count < 0 ~ "negative_pollen_count",
        TRUE ~ "unknown_pollen_count_issue"
      ),
      value = pollen_count
    ) |>
    dplyr::select(
      source,
      issue,
      dataset_name,
      sample_name,
      taxon,
      value
    )

  data_bad_age <-
    data_source |>
    dplyr::distinct(dataset_name, sample_name, age) |>
    dplyr::filter(
      base::is.na(age) |
        !base::is.finite(age) |
        age < 0 |
        age != 0
    ) |>
    dplyr::mutate(
      source = "community",
      issue = dplyr::case_when(
        base::is.na(age) ~ "missing_age",
        !base::is.finite(age) ~ "non_finite_age",
        age < 0 ~ "negative_age",
        age != 0 ~ "non_zero_modern_age",
        TRUE ~ "unknown_age_issue"
      ),
      taxon = NA_character_,
      value = age
    ) |>
    dplyr::select(
      source,
      issue,
      dataset_name,
      sample_name,
      taxon,
      value
    )

  data_bad_coordinates <-
    data_coordinates_named |>
    tidyr::pivot_longer(
      cols = c(coord_long, coord_lat),
      names_to = "coordinate",
      values_to = "value"
    ) |>
    dplyr::filter(
      base::is.na(value) |
        !base::is.finite(value) |
        (
          coordinate == "coord_long" &
            (value < -180 | value > 180)
        ) |
        (
          coordinate == "coord_lat" &
            (value < -90 | value > 90)
        )
    ) |>
    dplyr::mutate(
      source = "coords",
      issue = dplyr::case_when(
        base::is.na(value) ~ "missing_coordinate",
        !base::is.finite(value) ~ "non_finite_coordinate",
        coordinate == "coord_long" ~ "longitude_out_of_range",
        coordinate == "coord_lat" ~ "latitude_out_of_range",
        TRUE ~ "unknown_coordinate_issue"
      ),
      sample_name = NA_character_,
      taxon = NA_character_
    ) |>
    dplyr::select(
      source,
      issue,
      dataset_name,
      sample_name,
      taxon,
      value
    )

  res <-
    dplyr::bind_rows(
      data_bad_pollen,
      data_bad_age,
      data_bad_coordinates
    ) |>
    dplyr::arrange(source, issue, dataset_name, sample_name, taxon)

  return(res)
}

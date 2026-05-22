#' @title Deduplicate Modern Community Data
#' @description
#' Drops exact duplicated modern community records using a deterministic
#' lexicographic keep rule.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names and `coord_long`, `coord_lat` columns.
#' @param data_quality_report
#' Optional modern QA report. Used by targets pipelines to make the QA gate an
#' explicit upstream dependency before deduplication.
#' @return
#' A named list with `data_community` and `data_dropped_records` elements.
#' @export
deduplicate_modern_community_data <- function(
    data_source = NULL,
    data_coordinates = NULL,
    data_quality_report = NULL) {
  if (
    !base::is.null(data_quality_report)
  ) {
    assertthat::assert_that(
      base::is.list(data_quality_report),
      msg = "data_quality_report must be NULL or a list."
    )
  }

  validate_community_source(data_source = data_source)

  data_coordinates_named <-
    normalize_coordinates(data_source = data_coordinates)

  data_record_signatures <-
    make_community_record_signatures(data_source = data_source)

  data_record_coordinates <-
    data_record_signatures |>
    dplyr::left_join(
      data_coordinates_named,
      by = dplyr::join_by(dataset_name)
    )

  data_missing_coordinates <-
    data_record_coordinates |>
    dplyr::filter(
      base::is.na(coord_long) | base::is.na(coord_lat)
    )

  if (
    base::nrow(data_missing_coordinates) > 0L
  ) {
    cli::cli_abort(
      c(
        "Cannot deduplicate modern community data without coordinates.",
        "i" = stringr::str_glue(
          "Missing coordinates for {base::nrow(data_missing_coordinates)} ",
          "sample record(s)."
        )
      )
    )
  }

  data_duplicate_records <-
    data_record_coordinates |>
    dplyr::group_by(coord_long, coord_lat, age, community_signature) |>
    dplyr::mutate(
      n_records = dplyr::n(),
      duplicate_group = dplyr::cur_group_id()
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(n_records > 1L) |>
    dplyr::arrange(
      coord_long,
      coord_lat,
      age,
      community_signature,
      dataset_name,
      sample_name
    ) |>
    dplyr::group_by(coord_long, coord_lat, age, community_signature) |>
    dplyr::mutate(
      keep_record = dplyr::row_number() == 1L,
      kept_dataset_name = dplyr::first(dataset_name),
      kept_sample_name = dplyr::first(sample_name)
    ) |>
    dplyr::ungroup()

  data_dropped_records <-
    data_duplicate_records |>
    dplyr::filter(!keep_record) |>
    dplyr::transmute(
      duplicate_group,
      dropped_dataset_name = dataset_name,
      dropped_sample_name = sample_name,
      age,
      coord_long,
      coord_lat,
      kept_dataset_name,
      kept_sample_name,
      community_signature
    )

  data_community <-
    data_source |>
    dplyr::anti_join(
      data_dropped_records |>
        dplyr::transmute(
          dataset_name = dropped_dataset_name,
          sample_name = dropped_sample_name,
          age
        ),
      by = dplyr::join_by(dataset_name, sample_name, age)
    )

  res <-
    base::list(
      data_community = data_community,
      data_dropped_records = data_dropped_records
    )

  return(res)
}

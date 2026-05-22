#' @title Aggregate Colocated Community Records
#' @description
#' Aggregates same-prefix colocated modern records and keeps cross-database
#' colocations for inspection.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names and `coord_long`, `coord_lat` columns.
#' @param data_abiotic_long
#' A long-format abiotic table with columns `dataset_name`, `age`,
#' `abiotic_variable_name`, and `abiotic_value`.
#' @return
#' A named list containing aggregated analysis streams and traceability tables.
#' @export
aggregate_colocated_community_records <- function(
    data_source = NULL,
    data_coordinates = NULL,
    data_abiotic_long = NULL) {
  validate_community_source(data_source = data_source)

  assertthat::assert_that(
    base::is.data.frame(data_abiotic_long),
    msg = "data_abiotic_long must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c(
        "dataset_name",
        "age",
        "abiotic_variable_name",
        "abiotic_value"
      ) %in% base::names(data_abiotic_long)
    ),
    msg = paste0(
      "data_abiotic_long must contain columns: dataset_name, age, ",
      "abiotic_variable_name, and abiotic_value."
    )
  )

  data_coordinates_named <-
    normalize_coordinates(data_source = data_coordinates)

  data_colocated_report <-
    detect_colocated_community_records(
      data_source = data_source,
      data_coordinates = data_coordinates_named
    )

  data_cross_database_colocations <-
    data_colocated_report |>
    dplyr::filter(flag_cross_database_bien_splot) |>
    dplyr::mutate(retained_unchanged = TRUE)

  data_same_prefix_groups <-
    data_colocated_report |>
    dplyr::filter(flag_same_prefix_eligible) |>
    dplyr::arrange(source_prefix_single, coord_long, coord_lat, age) |>
    dplyr::mutate(
      aggregation_group_id = dplyr::row_number(),
      synthetic_dataset_name = stringr::str_glue(
        "{source_prefix_single}_agg_",
        "{stringr::str_pad(aggregation_group_id, width = 6, pad = '0')}"
      ),
      synthetic_sample_name = synthetic_dataset_name
    )

  if (
    base::nrow(data_same_prefix_groups) == 0L
  ) {
    data_aggregation_map <-
      tibble::tibble(
        aggregation_group_id = base::integer(),
        source_prefix = base::character(),
        age = base::numeric(),
        coord_long = base::numeric(),
        coord_lat = base::numeric(),
        original_dataset_name = base::character(),
        original_sample_name = base::character(),
        synthetic_dataset_name = base::character(),
        synthetic_sample_name = base::character()
      )

    res <-
      base::list(
        data_community_analysis = data_source,
        data_coords_analysis = data_coordinates,
        data_abiotic_analysis = data_abiotic_long,
        data_aggregation_map = data_aggregation_map,
        data_cross_database_colocations = data_cross_database_colocations,
        data_colocated_report = data_colocated_report
      )

    return(res)
  }

  data_record_signatures <-
    make_community_record_signatures(data_source = data_source)

  data_aggregation_map <-
    data_record_signatures |>
    dplyr::left_join(
      data_coordinates_named,
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::mutate(source_prefix = classify_dataset_prefix(dataset_name)) |>
    dplyr::inner_join(
      data_same_prefix_groups |>
        dplyr::select(
          coord_long,
          coord_lat,
          age,
          source_prefix_single,
          aggregation_group_id,
          synthetic_dataset_name,
          synthetic_sample_name
        ),
      by = dplyr::join_by(
        coord_long,
        coord_lat,
        age,
        source_prefix == source_prefix_single
      )
    ) |>
    dplyr::transmute(
      aggregation_group_id,
      source_prefix,
      age,
      coord_long,
      coord_lat,
      original_dataset_name = dataset_name,
      original_sample_name = sample_name,
      synthetic_dataset_name,
      synthetic_sample_name
    )

  data_record_mapping <-
    data_aggregation_map |>
    dplyr::distinct(
      original_dataset_name,
      original_sample_name,
      age,
      synthetic_dataset_name,
      synthetic_sample_name
    )

  data_community_unaffected <-
    data_source |>
    dplyr::anti_join(
      data_record_mapping |>
        dplyr::transmute(
          dataset_name = original_dataset_name,
          sample_name = original_sample_name,
          age
        ),
      by = dplyr::join_by(dataset_name, sample_name, age)
    )

  data_community_aggregated <-
    data_source |>
    dplyr::inner_join(
      data_record_mapping,
      by = dplyr::join_by(
        dataset_name == original_dataset_name,
        sample_name == original_sample_name,
        age
      )
    ) |>
    dplyr::group_by(synthetic_dataset_name, synthetic_sample_name, age, taxon) |>
    dplyr::summarise(
      pollen_count = dplyr::if_else(
        base::all(base::is.na(pollen_count)),
        NA_real_,
        base::mean(pollen_count, na.rm = TRUE)
      ),
      .groups = "drop"
    ) |>
    dplyr::rename(
      dataset_name = synthetic_dataset_name,
      sample_name = synthetic_sample_name
    )

  data_community_analysis <-
    dplyr::bind_rows(data_community_unaffected, data_community_aggregated) |>
    dplyr::arrange(dataset_name, sample_name, age, taxon)

  data_abiotic_mapping <-
    data_aggregation_map |>
    dplyr::distinct(original_dataset_name, age, synthetic_dataset_name)

  data_abiotic_unaffected <-
    data_abiotic_long |>
    dplyr::anti_join(
      data_abiotic_mapping |>
        dplyr::transmute(dataset_name = original_dataset_name, age),
      by = dplyr::join_by(dataset_name, age)
    )

  data_abiotic_aggregated <-
    data_abiotic_long |>
    dplyr::inner_join(
      data_abiotic_mapping,
      by = dplyr::join_by(dataset_name == original_dataset_name, age)
    ) |>
    dplyr::group_by(synthetic_dataset_name, age, abiotic_variable_name) |>
    dplyr::summarise(
      abiotic_value = dplyr::if_else(
        base::all(base::is.na(abiotic_value)),
        NA_real_,
        base::mean(abiotic_value, na.rm = TRUE)
      ),
      .groups = "drop"
    ) |>
    dplyr::rename(dataset_name = synthetic_dataset_name)

  data_abiotic_analysis <-
    dplyr::bind_rows(data_abiotic_unaffected, data_abiotic_aggregated) |>
    dplyr::arrange(dataset_name, age, abiotic_variable_name)

  data_coords_unaffected <-
    data_coordinates_named |>
    dplyr::anti_join(
      data_aggregation_map |>
        dplyr::distinct(original_dataset_name) |>
        dplyr::rename(dataset_name = original_dataset_name),
      by = dplyr::join_by(dataset_name)
    )

  data_coords_aggregated <-
    data_same_prefix_groups |>
    dplyr::transmute(
      dataset_name = synthetic_dataset_name,
      coord_long,
      coord_lat
    )

  data_coords_analysis <-
    dplyr::bind_rows(data_coords_unaffected, data_coords_aggregated) |>
    dplyr::distinct(dataset_name, .keep_all = TRUE) |>
    dplyr::arrange(dataset_name) |>
    tibble::column_to_rownames("dataset_name")

  res <-
    base::list(
      data_community_analysis = data_community_analysis,
      data_coords_analysis = data_coords_analysis,
      data_abiotic_analysis = data_abiotic_analysis,
      data_aggregation_map = data_aggregation_map,
      data_cross_database_colocations = data_cross_database_colocations,
      data_colocated_report = data_colocated_report
    )

  return(res)
}

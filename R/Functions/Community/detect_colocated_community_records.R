#' @title Detect Colocated Community Records
#' @description
#' Reports same-coordinate, same-age community colocations with source-prefix
#' and community-signature flags.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names and `coord_long`, `coord_lat` columns.
#' @return
#' A tibble with one row per colocated group and diagnostic flags used by
#' modern preprocessing.
#' @export
detect_colocated_community_records <- function(
    data_source = NULL,
    data_coordinates = NULL) {
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
    ) |>
    dplyr::mutate(
      source_prefix = classify_dataset_prefix(dataset_name),
      record_key = stringr::str_glue("{dataset_name}::{sample_name}")
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
        "Cannot detect colocations without coordinates.",
        "i" = stringr::str_glue(
          "Missing coordinates for {base::nrow(data_missing_coordinates)} ",
          "sample record(s)."
        )
      )
    )
  }

  res <-
    data_record_coordinates |>
    dplyr::group_by(coord_long, coord_lat, age) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      n_prefixes = dplyr::n_distinct(source_prefix),
      n_bien_records = base::sum(source_prefix == "bien"),
      n_splot_records = base::sum(source_prefix == "splot"),
      n_other_records = base::sum(source_prefix == "other"),
      source_prefixes = stringr::str_c(
        base::sort(base::unique(source_prefix)),
        collapse = "|"
      ),
      source_prefix_single = dplyr::if_else(
        n_prefixes == 1L,
        dplyr::first(source_prefix),
        NA_character_
      ),
      n_community_signatures = dplyr::n_distinct(community_signature),
      flag_community_signatures_differ = n_community_signatures > 1L,
      original_dataset_names = stringr::str_c(
        base::sort(base::unique(dataset_name)),
        collapse = "|"
      ),
      original_sample_names = stringr::str_c(
        base::sort(base::unique(sample_name)),
        collapse = "|"
      ),
      original_record_keys = stringr::str_c(
        base::sort(base::unique(record_key)),
        collapse = "|"
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(n_records > 1L) |>
    dplyr::mutate(
      flag_same_prefix_eligible =
        n_prefixes == 1L &
          source_prefix_single %in% base::c("bien", "splot")
    ) |>
    dplyr::mutate(
      flag_cross_database_bien_splot =
        n_bien_records > 0L & n_splot_records > 0L
    ) |>
    dplyr::arrange(coord_long, coord_lat, age)

  return(res)
}

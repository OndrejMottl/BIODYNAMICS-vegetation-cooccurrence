#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Diagnose modern spatial preprocessing quality
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Runs the extraction targets needed for modern preprocessing QA, reads the
#   inputs, and prints reproducible diagnostic summaries without aborting on
#   impossible values.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

if (
  config::is_active("default")
) {
  Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_continental")
}

sel_config <- base::Sys.getenv("R_CONFIG_ACTIVE")

if (
  !stringr::str_detect(sel_config, "project_modern_spatial")
) {
  cli::cli_abort(
    "The active config must be one of the project_modern_spatial configs."
  )
}


#----------------------------------------------------------#
# 1. Select spatial unit -----
#----------------------------------------------------------#

sel_scale_id <-
  base::Sys.getenv("MODERN_QA_SCALE_ID", unset = NA_character_)

if (
  base::is.na(sel_scale_id) || sel_scale_id == ""
) {
  sel_scale <-
    dplyr::case_when(
      stringr::str_detect(sel_config, "continental") ~ "continental",
      stringr::str_detect(sel_config, "regional") ~ "regional",
      stringr::str_detect(sel_config, "local") ~ "local",
      TRUE ~ NA_character_
    )

  sel_scale_id <-
    readr::read_csv(
      here::here("Data/Input/spatial_grid.csv"),
      show_col_types = FALSE
    ) |>
    dplyr::filter(.data[["scale"]] == sel_scale) |>
    dplyr::slice(1L) |>
    dplyr::pull(scale_id)
}

if (
  base::length(sel_scale_id) != 1L ||
    base::is.na(sel_scale_id) ||
    sel_scale_id == ""
) {
  cli::cli_abort("Could not resolve a modern spatial unit for QA.")
}

base::message(
  stringr::str_glue(
    "Running modern preprocessing QA for {sel_config}: {sel_scale_id}"
  )
)


#----------------------------------------------------------#
# 2. Build extraction targets -----
#----------------------------------------------------------#

sel_script <-
  here::here("R/Pipelines/pipeline_modern_spatial_resolution.R")

sel_store <-
  here::here(
    get_active_config("target_store"),
    sel_scale_id,
    "pipeline_modern_spatial_resolution"
  )

targets::tar_make(
  names = tidyselect::any_of(
    c(
      "data_community_long_ages",
      "data_sample_ages",
      "data_coords",
      "data_abiotic_interpolated"
    )
  ),
  script = sel_script,
  store = sel_store,
  reporter = "verbose"
)

data_community_long_ages <-
  targets::tar_read(
    data_community_long_ages,
    store = sel_store
  )

data_sample_ages <-
  targets::tar_read(
    data_sample_ages,
    store = sel_store
  )

data_coords <-
  targets::tar_read(
    data_coords,
    store = sel_store
  )

data_abiotic_interpolated <-
  targets::tar_read(
    data_abiotic_interpolated,
    store = sel_store
  )


#----------------------------------------------------------#
# 3. Report QA and deduplication -----
#----------------------------------------------------------#

list_quality_report <-
  make_modern_data_quality_report(
    data_source = data_community_long_ages,
    data_sample_ages = data_sample_ages,
    data_coordinates = data_coords,
    abort_on_impossible = FALSE
  )

list_deduplication <-
  deduplicate_modern_community_data(
    data_source = data_community_long_ages,
    data_coordinates = data_coords,
    data_quality_report = list_quality_report
  )

list_colocated <-
  aggregate_colocated_community_records(
    data_source = purrr::chuck(list_deduplication, "data_community"),
    data_coordinates = data_coords,
    data_abiotic_long = data_abiotic_interpolated
  )

base::print(
  purrr::chuck(list_quality_report, "data_summary")
)

c(
  "data_duplicate_sites",
  "data_duplicate_communities",
  "data_duplicate_metadata_keys",
  "data_impossible_values"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ {
      data_issue <-
        purrr::chuck(list_quality_report, .x)

      if (
        base::nrow(data_issue) > 0L
      ) {
        base::message(stringr::str_glue("\n{.x}:"))
        base::print(data_issue)
      }
    }
  )

base::message("\ndata_modern_dropped_duplicate_records:")
base::print(
  purrr::chuck(list_deduplication, "data_dropped_records")
)

data_aggregation_map <-
  purrr::chuck(list_colocated, "data_aggregation_map")

data_cross_database_colocations <-
  purrr::chuck(list_colocated, "data_cross_database_colocations")

n_records_before <-
  dplyr::distinct(
    data_community_long_ages,
    dataset_name,
    sample_name,
    age
  ) |>
  base::nrow()

n_records_after_dedup <-
  dplyr::distinct(
    purrr::chuck(list_deduplication, "data_community"),
    dataset_name,
    sample_name,
    age
  ) |>
  base::nrow()

n_records_after_aggregation <-
  dplyr::distinct(
    purrr::chuck(
      list_colocated,
      "data_community_analysis"
    ),
    dataset_name,
    sample_name,
    age
  ) |>
  base::nrow()

base::message("\nModern preprocessing summary:")
base::print(
  tibble::tibble(
    metric = c(
      "exact_duplicates_dropped",
      "same_prefix_colocated_groups_aggregated",
      "records_before_aggregation",
      "records_after_exact_dedup",
      "records_after_colocated_aggregation",
      "cross_database_bien_splot_groups_retained"
    ),
    value = c(
      base::nrow(purrr::chuck(list_deduplication, "data_dropped_records")),
      dplyr::n_distinct(data_aggregation_map$aggregation_group_id),
      n_records_before,
      n_records_after_dedup,
      n_records_after_aggregation,
      base::nrow(data_cross_database_colocations)
    )
  )
)

if (
  base::nrow(data_aggregation_map) > 0L
) {
  base::message("\nSame-prefix aggregation map:")
  base::print(data_aggregation_map)
}

if (
  base::nrow(data_cross_database_colocations) > 0L
) {
  base::message("\nCross-database BIEN+sPlot colocations retained:")
  base::print(data_cross_database_colocations)
}

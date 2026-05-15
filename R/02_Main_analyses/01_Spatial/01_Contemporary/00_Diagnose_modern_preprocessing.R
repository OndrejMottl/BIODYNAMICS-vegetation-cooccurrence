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
      "data_coords"
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

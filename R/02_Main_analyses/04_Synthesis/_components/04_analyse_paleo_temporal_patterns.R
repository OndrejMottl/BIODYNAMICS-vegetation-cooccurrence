#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Analyse paleo temporal patterns
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Publishes the cached temporal ANOVA, network, and time-slice sample-density
# evidence needed by stage 05. It reads accepted temporal stores but never
# runs fitting or changes target metadata.
# Workflow contract:
#   Run after the paleo temporal continental runners complete in normal mode.
#   Reads accepted cached targets without updating their stores or refitting.
#   Target-level failures remain explicit availability statuses in the output.
#   Writes dated plot-ready result, density, and model-status CSV tables.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output_tables <-
  here::here("Outputs/Tables")
base::dir.create(
  path = path_output_tables,
  showWarnings = FALSE,
  recursive = TRUE
)

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Build temporal-store inventory -----
#----------------------------------------------------------#

data_temporal_stores <-
  load_continental_spatial_grid_rows(
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
  ) |>
  dplyr::select(continent_id = "scale_id") |>
  dplyr::mutate(
    store_path = here::here(
      stringr::str_glue(
        "Data/targets/paleo_temporal_{continent_id}/",
        "pipeline_paleo_temporal"
      )
    ),
    store_exists = fs::dir_exists(.data$store_path)
  ) |>
  dplyr::filter(.data$store_exists)

if (
  base::nrow(data_temporal_stores) == 0L
) {
  cli::cli_abort(
    "Temporal synthesis requires at least one paleo temporal store."
  )
}


#----------------------------------------------------------#
# 2. Load accepted temporal results -----
#----------------------------------------------------------#

data_temporal_anova <-
  data_temporal_stores |>
  purrr::pmap(
    function(continent_id, store_path, store_exists) {
      targets::tar_read_raw(
        name = "data_anova_components_by_age_percentage",
        store = store_path
      ) |>
        dplyr::mutate(
          age = .data$age,
          continent_id = continent_id,
          scale = "temporal",
          scale_id = stringr::str_glue(
            "{continent_id}_timeslice_{.data$age}"
          ),
          resolution_id = "genus",
          result_type = "variance_component",
          series = .data$component,
          value = .data$R2_Nagelkerke_percentage,
          .keep = "none"
        )
    }
  ) |>
  purrr::list_rbind()

data_temporal_network <-
  data_temporal_stores |>
  purrr::pmap(
    function(continent_id, store_path, store_exists) {
      targets::tar_read_raw(
        name = "data_network_metrics_by_age",
        store = store_path
      ) |>
        dplyr::mutate(
          age = stringr::str_extract(.data$age, "[0-9]+$") |>
            base::as.numeric(),
          continent_id = continent_id,
          scale = "temporal",
          scale_id = stringr::str_glue(
            "{continent_id}_timeslice_{.data$age}"
          ),
          resolution_id = "genus",
          result_type = "network_metric",
          series = .data$metric,
          value = .data$value,
          .keep = "none"
        )
    }
  ) |>
  purrr::list_rbind()

data_temporal_unit <-
  dplyr::bind_rows(
    data_temporal_anova,
    data_temporal_network
  ) |>
  dplyr::filter(
    base::is.finite(.data$age),
    base::is.finite(.data$value)
  ) |>
  dplyr::mutate(availability_status = "available") |>
  dplyr::select(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "result_type",
    "series",
    "value",
    "availability_status"
  ) |>
  dplyr::arrange(
    .data$continent_id,
    dplyr::desc(.data$age),
    .data$result_type,
    .data$series
  )

validate_manuscript_plot_data(
  data_plot = data_temporal_unit,
  required_columns = base::c(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "result_type",
    "series",
    "value",
    "availability_status"
  )
)


#----------------------------------------------------------#
# 3. Summarize time-slice sample density -----
#----------------------------------------------------------#

data_temporal_density <-
  data_temporal_stores |>
  purrr::pmap(
    function(continent_id, store_path, store_exists) {
      data_target_meta_all <-
        targets::tar_meta(
          store = store_path,
          fields = base::c("name", "error")
        )
      data_target_meta <-
        data_target_meta_all |>
        dplyr::filter(
          stringr::str_detect(
            .data$name,
            "^data_sample_ids_timeslice_[0-9]+$"
          )
        )

      data_target_meta |>
        dplyr::mutate(
          age = stringr::str_extract(.data$name, "[0-9]+$") |>
            base::as.numeric(),
          timeslice_id = stringr::str_extract(
            .data$name,
            "timeslice_[0-9]+$"
          ),
          sample_error_classification = purrr::map2(
            .data$timeslice_id,
            .data$error,
            ~ {
              if (
                base::is.na(.y) ||
                  !base::nzchar(.y)
              ) {
                return(
                  base::list(
                    status = "available",
                    reason_code = NA_character_,
                    root_target = NA_character_,
                    root_error = NA_character_
                  )
                )
              }
              data_slice_errors <-
                data_target_meta_all |>
                dplyr::filter(
                  stringr::str_ends(.data$name, .env$.x),
                  !base::is.na(.data$error),
                  base::nzchar(.data$error)
                )
              classify_sjsdm_unit_pipeline_error(
                data_target_errors = data_slice_errors
              )
            }
          ),
          model_error_classification = purrr::map(
            .data$timeslice_id,
            ~ {
              target_name <-
                stringr::str_glue("model_anova_{.x}")
              data_model_target <-
                data_target_meta_all |>
                dplyr::filter(.data$name == .env$target_name)
              if (
                base::nrow(data_model_target) == 0L
              ) {
                return(
                  base::list(
                    status = "missing_model",
                    reason_code = NA_character_,
                    root_target = target_name,
                    root_error = NA_character_
                  )
                )
              }
              model_error <-
                data_model_target[["error"]][[1L]]
              if (
                base::is.na(model_error) ||
                  !base::nzchar(model_error)
              ) {
                return(
                  base::list(
                    status = "available",
                    reason_code = NA_character_,
                    root_target = NA_character_,
                    root_error = NA_character_
                  )
                )
              }
              data_slice_errors <-
                data_target_meta_all |>
                dplyr::filter(
                  stringr::str_ends(.data$name, .env$.x),
                  !base::is.na(.data$error),
                  base::nzchar(.data$error)
                )
              classify_sjsdm_unit_pipeline_error(
                data_target_errors = data_slice_errors
              )
            }
          ),
          data_sample_ids = purrr::map2(
            .data$name,
            .data$error,
            ~ {
              if (
                !base::is.na(.y)
              ) {
                return(NULL)
              }
              targets::tar_read_raw(
                name = .x,
                store = store_path
              )
            }
          ),
          n_samples = purrr::map_int(
            .data$data_sample_ids,
            ~ {
              if (
                base::is.null(.x)
              ) {
                return(0L)
              }
              if (
                base::is.data.frame(.x)
              ) {
                return(base::nrow(.x))
              }
              return(base::length(.x))
            }
          ),
          n_locations = purrr::map_int(
            .data$data_sample_ids,
            ~ if (
              base::is.null(.x) ||
                !"dataset_name" %in% base::names(.x)
            ) {
              0L
            } else {
              dplyr::n_distinct(.x[["dataset_name"]])
            }
          ),
          sample_availability_status = purrr::map_chr(
            .data$sample_error_classification,
            ~ .x[["status"]]
          ),
          availability_status = purrr::map_chr(
            .data$model_error_classification,
            ~ .x[["status"]]
          ),
          infeasibility_reason = purrr::map_chr(
            .data$model_error_classification,
            ~ .x[["reason_code"]]
          ),
          root_target = purrr::map_chr(
            .data$model_error_classification,
            ~ .x[["root_target"]]
          ),
          model_error = purrr::map_chr(
            .data$model_error_classification,
            ~ .x[["root_error"]]
          ),
          continent_id = continent_id,
          scale = "temporal",
          scale_id = stringr::str_glue(
            "{continent_id}_{.data$timeslice_id}"
          ),
          resolution_id = "genus"
        ) |>
        dplyr::select(
          "continent_id",
          "scale",
          "scale_id",
          "resolution_id",
          "age",
          "n_samples",
          "n_locations",
          "sample_availability_status",
          "availability_status",
          "infeasibility_reason",
          "root_target",
          "model_error",
          sample_target_error = "error"
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::arrange(
    .data$continent_id,
    dplyr::desc(.data$age)
  )

validate_manuscript_plot_data(
  data_plot = data_temporal_density,
  required_columns = base::c(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "n_samples",
    "n_locations",
    "availability_status"
  )
)


#----------------------------------------------------------#
# 4. Save synthesis tables -----
#----------------------------------------------------------#

file_temporal_unit <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_temporal_patterns_unit_{tag_date}.csv")
  )
file_temporal_density <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_temporal_density_{tag_date}.csv")
  )

readr::write_csv(data_temporal_unit, file_temporal_unit)
readr::write_csv(data_temporal_density, file_temporal_density)

base::message("Saved paleo temporal unit table: ", file_temporal_unit)
base::message("Saved paleo temporal density: ", file_temporal_density)

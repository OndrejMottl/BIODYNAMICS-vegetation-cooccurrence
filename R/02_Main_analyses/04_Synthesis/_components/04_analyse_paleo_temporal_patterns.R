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

# Regularisation provenance, build times and VegVault release per slice, so
#   published rows show which fit, partition and database they come from.
data_temporal_provenance <-
  data_temporal_stores |>
  purrr::pmap(
    function(continent_id, store_path, store_exists) {
      load_paleo_temporal_slice_provenance(store_path = store_path) |>
        dplyr::mutate(continent_id = continent_id) |>
        dplyr::select(
          "continent_id",
          "age",
          "cv_strategy",
          "regularization_source",
          "candidate_id",
          "final_model_built_at",
          "variance_partition_built_at",
          "vegvault_version"
        )
    }
  ) |>
  purrr::list_rbind()

data_temporal_anova <-
  data_temporal_stores |>
  purrr::pmap(
    function(continent_id, store_path, store_exists) {
      targets::tar_read_raw(
        name = "data_anova_components_by_age",
        store = store_path
      ) |>
        compute_predictor_inclusive_variance_components() |>
        dplyr::mutate(
          age = .data$age,
          continent_id = continent_id,
          scale = "temporal",
          scale_id = stringr::str_glue(
            "{continent_id}_timeslice_{.data$age}"
          ),
          resolution_id = "genus",
          result_type =
            "predictor_inclusive_variance_component",
          series = .data$component,
          value =
            .data$R2_Nagelkerke_predictor_inclusive_percentage,
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
  dplyr::left_join(
    data_temporal_provenance,
    by = dplyr::join_by(continent_id, age),
    relationship = "many-to-one"
  ) |>
  dplyr::select(
    "continent_id",
    "scale",
    "scale_id",
    "resolution_id",
    "age",
    "result_type",
    "series",
    "value",
    "availability_status",
    "cv_strategy",
    "regularization_source",
    "candidate_id",
    "final_model_built_at",
    "variance_partition_built_at",
    "vegvault_version"
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

      # Slices outside the profile's modelled window (issue #181) stay in
      #   the density table but are not models; label them explicitly.
      data_window_slices <-
        load_temporal_slice_ages(
          config_id = stringr::str_glue(
            "project_paleo_temporal_{continent_id}"
          ),
          flag_modelled_only = FALSE
        )
      vec_window_slice_ids <-
        dplyr::pull(data_window_slices, "age_name")
      # Slices excluded in the profile are known to be infeasible.
      vec_excluded_slice_ids <-
        data_window_slices |>
        dplyr::filter(!.data$flag_modelled) |>
        dplyr::pull("age_name")
      data_slice_status <-
        classify_sjsdm_timeslice_status(
          data_target_errors = data_target_meta_all,
          vec_slice_ids = stringr::str_extract(
            data_target_meta[["name"]],
            "timeslice_[0-9]+$"
          ),
          vec_window_slice_ids = vec_window_slice_ids
        ) |>
        dplyr::filter(!base::is.na(.data$slice_id))

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
              timeslice_id <- .x
              target_name <-
                stringr::str_glue("list_jsdm_variance_partition_{.x}")
              list_slice_status <-
                data_slice_status |>
                dplyr::filter(.data$slice_id == .env$timeslice_id) |>
                base::as.list()
              data_model_target <-
                data_target_meta_all |>
                dplyr::filter(.data$name == .env$target_name)
              if (
                timeslice_id %in% vec_excluded_slice_ids
              ) {
                return(
                  base::list(
                    status = "expected_infeasible",
                    reason_code = "excluded_in_configuration",
                    root_target = NA_character_,
                    root_error = NA_character_
                  )
                )
              }
              if (
                list_slice_status[["status"]] == "outside_window"
              ) {
                return(
                  base::list(
                    status = "outside_window",
                    reason_code = list_slice_status[["reason_code"]],
                    root_target = NA_character_,
                    root_error = NA_character_
                  )
                )
              }
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
              return(
                list_slice_status[
                  base::c("status", "reason_code", "root_target", "root_error")
                ]
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
  dplyr::left_join(
    data_temporal_provenance,
    by = dplyr::join_by(continent_id, age),
    relationship = "one-to-one"
  ) |>
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

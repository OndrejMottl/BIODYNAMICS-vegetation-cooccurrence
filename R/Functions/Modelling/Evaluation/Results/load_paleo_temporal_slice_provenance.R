#' @title Load Paleo Temporal Slice Provenance
#' @description
#' Reads, for every time slice of one temporal store, the regularisation
#' provenance of its model and the build times of its final model and
#' variance partition.
#' @param store_path
#' Path to one `pipeline_paleo_temporal` targets store.
#' @param read_target_fn
#' Function used to load one target. Defaults to [targets::tar_read_raw()].
#' @param meta_fn
#' Function used to load target metadata. Defaults to [targets::tar_meta()].
#' @return
#' A tibble with one row per time slice found in the store metadata and
#' columns `timeslice_id`, `age`, `cv_strategy`, `regularization_source`,
#' `candidate_id`, `final_model_built_at`, `variance_partition_built_at`, and
#' `vegvault_version`.
#' Values are `NA` when a slice has no successful provenance, final model, or
#' partition target. `vegvault_version` is the VegVault release of the whole
#' store, read with [load_store_vegvault_version()]; it is `NA` for stores
#' built before the `config_vegvault_release` target existed.
#' @details
#' Slices are taken from the `data_sample_ids_timeslice_<age>` targets.
#' Provenance comes from `data_sjsdm_cv_model_provenance_timeslice_<age>`;
#' build times are the metadata `time` of `mod_jsdm_selected_timeslice_<age>`
#' and `list_jsdm_variance_partition_timeslice_<age>`. Targets that errored
#' are treated as absent.
#' @seealso [load_spatial_model_results()]
#' @examples
#' \dontrun{
#' load_paleo_temporal_slice_provenance(
#'   store_path = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal"
#' )
#' }
#' @export
load_paleo_temporal_slice_provenance <- function(
    store_path,
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta) {
  assertthat::assert_that(
    assertthat::is.string(store_path),
    msg = "`store_path` must be one path."
  )
  assertthat::assert_that(
    base::is.function(read_target_fn),
    base::is.function(meta_fn),
    msg = "`read_target_fn` and `meta_fn` must be functions."
  )

  data_meta <-
    meta_fn(
      store = store_path,
      fields = base::c("name", "error", "time")
    )

  vec_successful_targets <-
    data_meta[["name"]][
      base::is.na(data_meta[["error"]]) | !base::nzchar(data_meta[["error"]])
    ]

  vec_timeslice_ids <-
    data_meta[["name"]] |>
    stringr::str_subset("^data_sample_ids_timeslice_[0-9]+$") |>
    stringr::str_remove("^data_sample_ids_")

  sel_vegvault_version <-
    load_store_vegvault_version(
      store_path = store_path,
      data_meta = data_meta,
      read_target_fn = read_target_fn
    )

  res <-
    vec_timeslice_ids |>
    purrr::map(
      .f = ~ {
        timeslice_id <- .x

        target_provenance <-
          stringr::str_c("data_sjsdm_cv_model_provenance_", timeslice_id)
        vec_target_times <-
          base::c(
            stringr::str_c("mod_jsdm_selected_", timeslice_id),
            stringr::str_c("list_jsdm_variance_partition_", timeslice_id)
          ) |>
          purrr::map(
            .f = ~ {
              vec_time <-
                data_meta[["time"]][
                  data_meta[["name"]] == .x &
                    data_meta[["name"]] %in% vec_successful_targets
                ]
              if (
                base::length(vec_time) == 1L
              ) {
                base::as.POSIXct(vec_time, tz = "UTC")
              } else {
                base::as.POSIXct(NA_character_, tz = "UTC")
              }
            }
          )

        data_provenance <-
          if (
            target_provenance %in% vec_successful_targets
          ) {
            read_target_fn(name = target_provenance, store = store_path)
          } else {
            NULL
          }

        vec_provenance_values <-
          base::c("cv_strategy", "regularization_source", "candidate_id") |>
          rlang::set_names() |>
          purrr::map_chr(
            .f = ~ {
              if (
                base::is.data.frame(data_provenance) &&
                  .x %in% base::names(data_provenance) &&
                  base::nrow(data_provenance) >= 1L
              ) {
                base::as.character(data_provenance[[.x]][[1L]])
              } else {
                NA_character_
              }
            }
          )

        tibble::tibble(
          timeslice_id = timeslice_id,
          age = stringr::str_extract(timeslice_id, "[0-9]+$") |>
            base::as.numeric(),
          cv_strategy = vec_provenance_values[["cv_strategy"]],
          regularization_source =
            vec_provenance_values[["regularization_source"]],
          candidate_id = vec_provenance_values[["candidate_id"]],
          final_model_built_at = vec_target_times[[1L]],
          variance_partition_built_at = vec_target_times[[2L]],
          vegvault_version = sel_vegvault_version
        )
      }
    ) |>
    purrr::list_rbind()

  if (
    base::is.null(res) ||
      base::nrow(res) == 0L
  ) {
    res <-
      tibble::tibble(
        timeslice_id = base::character(),
        age = base::numeric(),
        cv_strategy = base::character(),
        regularization_source = base::character(),
        candidate_id = base::character(),
        final_model_built_at = base::as.POSIXct(
          base::character(),
          tz = "UTC"
        ),
        variance_partition_built_at = base::as.POSIXct(
          base::character(),
          tz = "UTC"
        ),
        vegvault_version = base::character()
      )
  }

  return(res)
}

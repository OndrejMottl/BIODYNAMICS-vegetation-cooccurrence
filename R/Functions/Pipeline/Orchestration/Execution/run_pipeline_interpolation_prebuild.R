#' @title Run a Pipeline Interpolation Prebuild
#' @description
#' Repairs failed interpolation targets and prebuilds shared interpolation
#' branches with the configured preprocessing workers.
#' @param pipeline_script
#' Path to the selected targets pipeline script.
#' @param pipeline_store
#' Path to the selected targets store.
#' @param workers
#' Positive integer number of preprocessing workers.
#' @return
#' `NULL`, invisibly. The function is called for targets side effects.
#' @export
run_pipeline_interpolation_prebuild <- function(
    pipeline_script,
    pipeline_store,
    workers) {
  assertthat::assert_that(
    base::is.numeric(workers) &&
      base::length(workers) == 1L &&
      base::is.finite(workers) &&
      workers >= 1L &&
      workers == base::as.integer(workers),
    msg = "`workers` must be one positive integer."
  )

  workers <-
    base::as.integer(workers)

  withr::with_envvar(
    new = base::c(
      BIODYNAMICS_PREPROCESSING_WORKER = "true",
      BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
      BIODYNAMICS_PREPROCESSING_WORKERS = base::as.character(workers)
    ),
    code = {
      data_prebuild_target_meta <-
        load_targets_store_metadata(
          store_path = pipeline_store,
          fields = base::c("name", "error")
        )

      if (
        base::is.null(data_prebuild_target_meta)
      ) {
        data_prebuild_target_meta <-
          tibble::tibble(
            name = base::character(),
            error = base::character()
          )
      }

      if (
        !"error" %in% base::colnames(data_prebuild_target_meta)
      ) {
        data_prebuild_target_meta[["error"]] <-
          NA_character_
      }

      vec_prebuild_target_name <-
        data_prebuild_target_meta[["name"]]
      vec_prebuild_error <-
        data_prebuild_target_meta[["error"]]

      vec_shared_target_names <-
        base::c(
          "data_community_proportions_shared",
          "data_age_uncertainty_shared"
        )

      vec_shared_targets_to_refresh <-
        base::intersect(
          vec_shared_target_names,
          vec_prebuild_target_name
        )

      if (
        base::length(vec_shared_targets_to_refresh) > 0L
      ) {
        targets::tar_invalidate(
          names = tidyselect::all_of(vec_shared_targets_to_refresh),
          store = pipeline_store
        )
      }

      flag_prebuild_interpolation_target <-
        stringr::str_detect(
          string = vec_prebuild_target_name,
          pattern = stringr::str_c(
            "^(data_community_proportions_shared|",
            "data_age_uncertainty_shared|",
            "data_community_interpolated_dataset|",
            "data_community_interpolated)"
          )
        )

      flag_prebuild_target_errored <-
        !base::is.na(vec_prebuild_error) &
        base::nzchar(vec_prebuild_error)

      vec_errored_prebuild_targets <-
        vec_prebuild_target_name[
          flag_prebuild_interpolation_target &
            flag_prebuild_target_errored
        ]

      if (
        base::length(vec_errored_prebuild_targets) > 0L
      ) {
        vec_targets_to_invalidate <-
          base::unique(
            base::c(
              vec_errored_prebuild_targets,
              "data_community_interpolated"
            )
          )

        targets::tar_invalidate(
          names = tidyselect::any_of(vec_targets_to_invalidate),
          store = pipeline_store
        )
      }

      base::tryCatch(
        targets::tar_make(
          names = tidyselect::all_of("data_community_interpolated"),
          script = pipeline_script,
          store = pipeline_store,
          reporter = "verbose",
          callr_function = NULL
        ),
        finally = targets::tar_unblock_process(
          store = pipeline_store
        )
      )
    }
  )

  return(base::invisible(NULL))
}

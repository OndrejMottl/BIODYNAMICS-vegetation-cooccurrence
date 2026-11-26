build_test_temporal_meta <- function() {
  tibble::tibble(
    name = base::c(
      "data_sample_ids_timeslice_0",
      "data_sample_ids_timeslice_500",
      "data_sjsdm_cv_model_provenance_timeslice_500",
      "mod_jsdm_selected_timeslice_500",
      "list_jsdm_variance_partition_timeslice_500",
      "data_sjsdm_cv_model_provenance_timeslice_0",
      "mod_jsdm_selected_timeslice_0"
    ),
    error = base::c(
      NA_character_,
      NA_character_,
      NA_character_,
      NA_character_,
      NA_character_,
      "failed",
      "failed"
    ),
    time = base::as.POSIXct(
      base::c(
        "2026-11-01 10:00:00",
        "2026-11-01 10:00:00",
        "2026-11-02 10:00:00",
        "2026-11-03 10:00:00",
        "2026-11-04 10:00:00",
        "2026-11-02 10:00:00",
        "2026-11-03 10:00:00"
      ),
      tz = "UTC"
    )
  )
}

testthat::test_that(
  "load_paleo_temporal_slice_provenance() reads provenance per slice",
  {
    res <-
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = function(...) build_test_temporal_meta(),
        read_target_fn = function(name, store) {
          tibble::tibble(
            cv_strategy = "spatially_stratified_group_kfold",
            regularization_source = "unit_cv",
            candidate_id = "candidate_008",
            n_taxa = 10L
          )
        }
      )

    testthat::expect_equal(res[["timeslice_id"]], base::c(
      "timeslice_0",
      "timeslice_500"
    ))
    testthat::expect_equal(res[["age"]], base::c(0, 500))

    data_available <-
      res |>
      dplyr::filter(.data[["age"]] == 500)
    testthat::expect_equal(data_available[["candidate_id"]], "candidate_008")
    testthat::expect_equal(data_available[["regularization_source"]], "unit_cv")
    testthat::expect_equal(
      data_available[["final_model_built_at"]],
      base::as.POSIXct("2026-11-03 10:00:00", tz = "UTC")
    )
    testthat::expect_equal(
      data_available[["variance_partition_built_at"]],
      base::as.POSIXct("2026-11-04 10:00:00", tz = "UTC")
    )

    # Errored targets count as absent.
    data_failed <-
      res |>
      dplyr::filter(.data[["age"]] == 0)
    testthat::expect_true(base::is.na(data_failed[["candidate_id"]]))
    testthat::expect_true(base::is.na(data_failed[["final_model_built_at"]]))
  }
)

testthat::test_that(
  "load_paleo_temporal_slice_provenance() returns a typed empty table",
  {
    res <-
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = function(...) {
          tibble::tibble(
            name = "config_x",
            error = NA_character_,
            time = base::as.POSIXct("2026-11-01", tz = "UTC")
          )
        },
        read_target_fn = function(...) NULL
      )

    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_s3_class(res[["final_model_built_at"]], "POSIXct")
  }
)

testthat::test_that(
  "load_paleo_temporal_slice_provenance() validates its arguments",
  {
    testthat::expect_error(
      load_paleo_temporal_slice_provenance(store_path = 1),
      "store_path"
    )
    testthat::expect_error(
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = "tar_meta"
      ),
      "functions"
    )
  }
)

testthat::test_that(
  "load_paleo_temporal_slice_provenance() records the VegVault version",
  {
    res <-
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = function(...) {
          build_test_temporal_meta() |>
            dplyr::bind_rows(
              tibble::tibble(
                name = "config_vegvault_release",
                error = NA_character_,
                time = base::as.POSIXct("2026-11-01 09:00:00", tz = "UTC")
              )
            )
        },
        read_target_fn = function(name, store) {
          if (
            name == "config_vegvault_release"
          ) {
            return(
              tibble::tibble(
                vegvault_version = "2.0.0",
                git_commit = "f19d588",
                manifest_sha256 = "hash_accepted"
              )
            )
          }

          tibble::tibble(
            cv_strategy = "spatially_stratified_group_kfold",
            regularization_source = "unit_cv",
            candidate_id = "candidate_008"
          )
        }
      )

    res_without_release <-
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = function(...) build_test_temporal_meta(),
        read_target_fn = function(name, store) {
          tibble::tibble(
            cv_strategy = "spatially_stratified_group_kfold",
            regularization_source = "unit_cv",
            candidate_id = "candidate_008"
          )
        }
      )

    res_empty <-
      load_paleo_temporal_slice_provenance(
        store_path = "store",
        meta_fn = function(...) {
          tibble::tibble(
            name = "config_x",
            error = NA_character_,
            time = base::as.POSIXct("2026-11-01", tz = "UTC")
          )
        },
        read_target_fn = function(...) NULL
      )

    testthat::expect_equal(
      res[["vegvault_version"]],
      base::c("2.0.0", "2.0.0")
    )
    testthat::expect_equal(
      res_without_release[["vegvault_version"]],
      base::c(NA_character_, NA_character_)
    )
    testthat::expect_type(res_empty[["vegvault_version"]], "character")
  }
)

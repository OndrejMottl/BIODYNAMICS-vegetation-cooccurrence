testthat::test_that(
  "CV preparation runs spatial units without fitting targets",
  {
    list_calls <- base::list()
    run_pipeline_stub <- function(...) {
      list_calls[[base::length(list_calls) + 1L]] <<- base::list(...)
      base::invisible(NULL)
    }

    testthat::expect_invisible(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = base::c("folds_genus", "folds_family"),
        unit_store_suffixes = base::c("europe", "america"),
        prebuild_interpolation = TRUE,
        run_pipeline_function = run_pipeline_stub
      )
    )

    testthat::expect_length(list_calls, 2L)
    testthat::expect_identical(
      purrr::map_chr(list_calls, "store_suffix"),
      base::c("europe", "america")
    )
    testthat::expect_true(
      base::all(
        purrr::map_lgl(list_calls, "prebuild_interpolation")
      )
    )
    testthat::expect_identical(
      list_calls[[1L]][["target_names"]],
      base::c("folds_genus", "folds_family")
    )
    testthat::expect_true(
      base::all(!purrr::map_lgl(list_calls, "plot_progress"))
    )
  }
)

testthat::test_that(
  "CV preparation supports a non-nested temporal store",
  {
    list_call <- NULL
    run_pipeline_stub <- function(...) {
      list_call <<- base::list(...)
      base::invisible(NULL)
    }

    run_sjsdm_cv_preparation_sequence(
      unit_pipeline = "temporal.R",
      preparation_target_names = "folds_timeslice_0",
      run_pipeline_function = run_pipeline_stub
    )

    testthat::expect_false("store_suffix" %in% base::names(list_call))
    testthat::expect_identical(
      list_call[["target_names"]],
      "folds_timeslice_0"
    )
  }
)

testthat::test_that(
  "CV preparation records expected temporal target errors",
  {
    n_metadata_calls <- 0L
    load_metadata_stub <- function(...) {
      n_metadata_calls <<- n_metadata_calls + 1L
      if (
        n_metadata_calls == 1L
      ) {
        return(NULL)
      }
      tibble::tibble(
        name = "data_sample_ids_checked_timeslice_1000",
        error = paste(
          "Too few samples in this time slice to proceed with data",
          "preparation and model fitting. Found 4 sample(s) but at least",
          "10 are required."
        ),
        time = base::Sys.time()
      )
    }

    res <-
      testthat::expect_message(
        run_sjsdm_cv_preparation_sequence(
          unit_pipeline = "temporal.R",
          preparation_target_names = "folds_timeslice_1000",
          run_pipeline_function = function(...) {
            base::stop("targets recorded an error")
          },
          target_store = "stores",
          resolve_store_function = function(...) "temporal_store",
          load_metadata_function = load_metadata_stub
        ),
        "Skipping failed non-nested preparation component"
      )

    testthat::expect_identical(
      res[["preparation_status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(
      res[["reason_code"]],
      "insufficient_samples"
    )
    testthat::expect_identical(res[["observed_count"]], 4L)
    testthat::expect_identical(res[["required_count"]], 10L)
  }
)

testthat::test_that(
  "CV preparation rejects stale temporal errors after current failure",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "data_sample_ids_checked_timeslice_1000",
        error = paste(
          "Too few samples in this time slice to proceed with data",
          "preparation and model fitting. Found 4 sample(s) but at least",
          "10 are required."
        ),
        time = base::as.POSIXct(
          "2026-06-04 11:07:01",
          tz = "UTC"
        )
      )

    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "temporal.R",
        preparation_target_names = "folds_timeslice_1000",
        run_pipeline_function = function(...) {
          base::stop("runner setup failed")
        },
        target_store = "stores",
        resolve_store_function = function(...) "temporal_store",
        load_metadata_function = function(...) {
          data_previous_errors
        },
        diagnose_endpoints_function = function(...) {
          tibble::tibble(
            target_name = "folds_timeslice_1000",
            endpoint_status = "missing",
            data_hash = NA_character_,
            error_message = "Target metadata are missing."
          )
        },
        validate_endpoints = TRUE
      ),
      "unexplained target-level errors"
    )
  }
)

testthat::test_that(
  "CV preparation reuses matching temporal infeasibility",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "data_sample_ids_checked_timeslice_1000",
        error = paste(
          "Too few samples in this time slice to proceed with data",
          "preparation and model fitting. Found 4 sample(s) but at least",
          "10 are required."
        ),
        time = base::as.POSIXct(
          "2026-06-04 11:07:01",
          tz = "UTC"
        )
      )

    result <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "temporal.R",
        preparation_target_names = "folds_timeslice_1000",
        run_pipeline_function = function(...) {
          base::stop(
            paste(
              "Too few samples in this time slice to proceed with data",
              "preparation and model fitting."
            )
          )
        },
        target_store = "stores",
        resolve_store_function = function(...) "temporal_store",
        load_metadata_function = function(...) {
          data_previous_errors
        },
        diagnose_endpoints_function = function(...) {
          tibble::tibble(
            target_name = "folds_timeslice_1000",
            endpoint_status = "missing",
            data_hash = NA_character_,
            error_message = "Target metadata are missing."
          )
        },
        validate_endpoints = TRUE
      )

    testthat::expect_identical(
      result[["preparation_status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(
      result[["reason_code"]],
      "insufficient_samples"
    )
  }
)

testthat::test_that(
  "CV preparation rejects duplicate targets and units",
  {
    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = base::c("folds", "folds")
      ),
      "unique non-empty"
    )
    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("europe", "europe")
      ),
      "unique non-empty"
    )
  }
)

testthat::test_that(
  "CV preparation continues after expected-infeasible spatial units",
  {
    vec_calls <-
      base::character()
    environment_metadata_calls <-
      base::new.env(parent = base::emptyenv())
    environment_metadata_calls[["unit_b"]] <-
      0L
    run_pipeline_stub <- function(store_suffix, ...) {
      vec_calls <<-
        base::c(vec_calls, store_suffix)
      if (
        store_suffix == "unit_b"
      ) {
        base::stop("cannot branch over empty target")
      }
      base::invisible(NULL)
    }
    load_metadata_stub <- function(store_path, fields) {
      if (
        store_path != "unit_b"
      ) {
        return(NULL)
      }
      environment_metadata_calls[["unit_b"]] <-
        environment_metadata_calls[["unit_b"]] + 1L
      if (
        environment_metadata_calls[["unit_b"]] == 1L
      ) {
        return(NULL)
      }
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "data_community"
        ),
        error = base::c(
          "Not enough cores in this spatial window. Found 1; need 5.",
          "could not load dependency flag_available_core_count_validated"
        ),
        time = base::Sys.time()
      )
    }

    res <-
      testthat::expect_message(
        run_sjsdm_cv_preparation_sequence(
          unit_pipeline = "pipeline.R",
          preparation_target_names = "folds",
          unit_store_suffixes = base::c("unit_a", "unit_b", "unit_c"),
          run_pipeline_function = run_pipeline_stub,
          target_store = "stores",
          resolve_store_function = function(store_suffix, ...) {
            store_suffix
          },
          load_metadata_function = load_metadata_stub
        ),
        "Skipping failed unit unit_b"
      )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_a", "unit_b", "unit_c")
    )
    testthat::expect_identical(
      res[["preparation_status"]],
      base::c("prepared", "expected_infeasible", "prepared")
    )
    testthat::expect_identical(
      res[["reason_code"]],
      base::c(NA_character_, "insufficient_cores", NA_character_)
    )
  }
)

testthat::test_that(
  "CV preparation attempts all units before reporting unexpected errors",
  {
    vec_calls <- base::character()
    load_metadata_stub <- function(...) {
      tibble::tibble(
        name = "data_traits",
        error = "Trait file is corrupt.",
        time = base::Sys.time()
      )
    }
    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        run_pipeline_function = function(store_suffix, ...) {
          vec_calls <<- base::c(vec_calls, store_suffix)
          if (
            store_suffix == "unit_a"
          ) {
            base::stop("unexpected failure")
          }
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = load_metadata_stub
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(vec_calls, base::c("unit_a", "unit_b"))
  }
)

testthat::test_that(
  "CV preparation attempts later units after an unrecorded unit failure",
  {
    vec_calls <- base::character()
    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        run_pipeline_function = function(store_suffix, ...) {
          vec_calls <<- base::c(vec_calls, store_suffix)
          if (
            store_suffix == "unit_a"
          ) {
            base::stop("runner setup failed")
          }
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) NULL
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_a", "unit_b")
    )
  }
)

testthat::test_that(
  "CV preparation reuses a repeated expected-infeasibility diagnosis",
  {
    vec_calls <-
      base::character()
    data_previous_errors <-
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "data_community"
        ),
        error = base::c(
          "Not enough cores in this spatial window. Found 1; need 5.",
          "could not load dependency flag_available_core_count_validated"
        ),
        time = base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
      )

    res <-
      testthat::expect_message(
        run_sjsdm_cv_preparation_sequence(
          unit_pipeline = "pipeline.R",
          preparation_target_names = "folds",
          unit_store_suffixes = base::c("unit_b", "unit_c"),
          run_pipeline_function = function(store_suffix, ...) {
            vec_calls <<- base::c(vec_calls, store_suffix)
            if (
              store_suffix == "unit_b"
            ) {
              base::stop(
                paste(
                  "cannot branch over empty target",
                  "(list_community_interpolation_index)"
                )
              )
            }
          },
          target_store = "stores",
          resolve_store_function = function(store_suffix, ...) {
            store_suffix
          },
          load_metadata_function = function(...) {
            data_previous_errors
          }
        ),
        "Skipping failed unit unit_b"
      )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_b", "unit_c")
    )
    testthat::expect_identical(
      res[["preparation_status"]],
      base::c("expected_infeasible", "prepared")
    )
    testthat::expect_identical(
      res[["reason_code"]],
      base::c("insufficient_cores", NA_character_)
    )
  }
)

testthat::test_that(
  "CV preparation reuses expected roots for empty community branches",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "data_vegvault_extracted",
        error = paste(
          "Failed to extract VegVault data for this spatial unit.",
          "The upstream backend returned an empty/opaque error message."
        ),
        time = base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
      )

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          base::stop(
            paste(
              "Error in tar_make(): cannot branch over empty target",
              "(vec_community_taxa_checked)"
            )
          )
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          data_previous_errors
        }
      )

    testthat::expect_identical(
      res[["preparation_status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(res[["reason_code"]], "no_spatial_records")
  }
)

testthat::test_that(
  "CV preparation does not hide unrelated failures behind old errors",
  {
    vec_calls <- base::character()
    data_previous_errors <-
      tibble::tibble(
        name = "flag_available_core_count_validated",
        error = paste(
          "Not enough cores in this spatial window.",
          "Found 1; need 5."
        ),
        time = base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
      )

    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("unit_b", "unit_c"),
        run_pipeline_function = function(store_suffix, ...) {
          vec_calls <<- base::c(vec_calls, store_suffix)
          if (
            store_suffix == "unit_b"
          ) {
            base::stop("runner setup failed")
          }
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          data_previous_errors
        }
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_b", "unit_c")
    )
  }
)

testthat::test_that(
  "CV preparation continues after a cached target dependency failure",
  {
    vec_calls <- base::character()
    data_previous_errors <-
      tibble::tibble(
        name = base::c(
          "data_vegvault_extracted",
          "data_coords"
        ),
        error = base::c(
          paste(
            "Failed to extract VegVault data for this spatial unit.",
            "The upstream backend returned an empty/opaque error message."
          ),
          paste(
            "could not load dependency data_vegvault_extracted of target",
            "data_coords. there is no package called 'qs'"
          )
        ),
        time = base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
      )

    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("unit_b", "unit_c"),
        run_pipeline_function = function(store_suffix, ...) {
          vec_calls <<- base::c(vec_calls, store_suffix)
          if (
            store_suffix == "unit_b"
          ) {
            base::stop(
              paste(
                "could not load dependency data_coords of target",
                "flag_available_core_count_validated.",
                "there is no package called 'qs'"
              )
            )
          }
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          data_previous_errors
        }
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_b", "unit_c")
    )
  }
)

testthat::test_that(
  "CV preparation reuses an unchanged expected core-guard error",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "flag_available_core_count_validated",
        error = paste(
          "Not enough cores in this spatial window.",
          "Found 1; need 5."
        ),
        time = base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
      )

    res <-
      testthat::expect_message(
        run_sjsdm_cv_preparation_sequence(
          unit_pipeline = "pipeline.R",
          preparation_target_names = "folds",
          unit_store_suffixes = "unit_b",
          run_pipeline_function = function(...) {
            base::stop(
              "Not enough cores in this spatial window."
            )
          },
          target_store = "stores",
          resolve_store_function = function(store_suffix, ...) {
            store_suffix
          },
          load_metadata_function = function(...) {
            data_previous_errors
          }
        ),
        "Skipping failed unit unit_b"
      )

    testthat::expect_identical(
      res[["preparation_status"]],
      "expected_infeasible"
    )
  }
)

testthat::test_that(
  "CV preparation rejects false success when an endpoint is missing",
  {
    vec_calls <- base::character()
    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds",
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        run_pipeline_function = function(store_suffix, ...) {
          vec_calls <<- base::c(vec_calls, store_suffix)
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) NULL,
        diagnose_endpoints_function = function(store_path, ...) {
          tibble::tibble(
            target_name = "folds",
            endpoint_status = if (
              store_path == "unit_a"
            ) {
              "missing"
            } else {
              "prepared"
            },
            data_hash = if (
              store_path == "unit_a"
            ) {
              NA_character_
            } else {
              "hash"
            },
            error_message = if (
              store_path == "unit_a"
            ) {
              "Target metadata are missing."
            } else {
              NA_character_
            }
          )
        },
        validate_endpoints = TRUE
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(
      vec_calls,
      base::c("unit_a", "unit_b")
    )
  }
)

testthat::test_that(
  "CV preparation preserves partial expected-infeasible endpoints",
  {
    n_metadata_calls <- 0L
    load_metadata_stub <- function(...) {
      n_metadata_calls <<- n_metadata_calls + 1L
      if (
        n_metadata_calls == 1L
      ) {
        return(NULL)
      }
      tibble::tibble(
        name = "list_sjsdm_prepared_tuning_folds_functional_type",
        error = paste(
          "Too few taxa remain after filtering to run the model.",
          "Found 2 taxa but at least 3 are required."
        ),
        time = base::Sys.time()
      )
    }

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = base::c("folds_genus", "folds_ft"),
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          base::stop("targets recorded an error")
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = load_metadata_stub,
        diagnose_endpoints_function = function(...) {
          tibble::tibble(
            target_name = base::c("folds_genus", "folds_ft"),
            endpoint_status = base::c("prepared", "errored"),
            data_hash = base::c("hash", NA_character_),
            error_message = base::c(
              NA_character_,
              "Too few taxa remain after filtering to run the model."
            )
          )
        },
        validate_endpoints = TRUE
      )

    testthat::expect_identical(
      res[["preparation_status"]],
      base::c("prepared", "expected_infeasible")
    )
  }
)

testthat::test_that(
  "CV preparation does not retry cache cascades after expected roots",
  {
    n_pipeline_calls <- 0L
    n_metadata_calls <- 0L
    vec_invalidated <- base::character()
    time_root <-
      base::as.POSIXct("2026-09-04 13:09:45", tz = "UTC")
    data_errors_before <-
      tibble::tibble(
        name = "data_vegvault_extracted",
        error = paste(
          "Failed to extract VegVault data for this spatial unit.",
          "The upstream backend returned an empty/opaque error message."
        ),
        time = time_root
      )
    data_errors_after <-
      dplyr::bind_rows(
        data_errors_before,
        tibble::tibble(
          name = "folds_genus",
          error = paste(
            "could not load dependency data_vegvault_extracted of target",
            "folds_genus. there is no package called 'qs'"
          ),
          time = time_root + 1
        )
      )

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          n_pipeline_calls <<- n_pipeline_calls + 1L
          base::stop("targets recorded an error")
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          n_metadata_calls <<- n_metadata_calls + 1L
          if (
            n_metadata_calls == 1L
          ) {
            return(data_errors_before)
          }
          data_errors_after
        },
        diagnose_endpoints_function = function(...) {
          tibble::tibble(
            target_name = "folds_genus",
            endpoint_status = "cache_format_incompatible",
            data_hash = NA_character_,
            error_message = data_errors_after[["error"]][[2L]]
          )
        },
        invalidate_target_function = function(names, ...) {
          vec_invalidated <<- base::c(vec_invalidated, names)
        },
        validate_endpoints = TRUE
      )

    testthat::expect_identical(n_pipeline_calls, 1L)
    testthat::expect_length(vec_invalidated, 0L)
    testthat::expect_identical(
      res[["preparation_status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(res[["reason_code"]], "no_spatial_records")
  }
)

testthat::test_that(
  "CV preparation stops a cache recovery cycle without progress",
  {
    n_pipeline_calls <- 0L
    n_metadata_calls <- 0L
    n_diagnoses <- 0L
    list_invalidated <- base::list()
    data_cache_error <-
      tibble::tibble(
        name = "data_sample_ids_checked_genus",
        error = paste(
          "could not load dependency data_sample_ids_genus of target",
          "data_sample_ids_checked_genus. there is no package called 'qs'"
        ),
        time = base::Sys.time()
      )

    testthat::expect_error(
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          n_pipeline_calls <<- n_pipeline_calls + 1L
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          n_metadata_calls <<- n_metadata_calls + 1L
          if (
            n_metadata_calls == 1L
          ) {
            return(NULL)
          }
          data_cache_error
        },
        diagnose_endpoints_function = function(...) {
          n_diagnoses <<- n_diagnoses + 1L
          tibble::tibble(
            target_name = "folds_genus",
            endpoint_status = "cache_format_incompatible",
            data_hash = NA_character_,
            error_message = data_cache_error[["error"]][[1L]]
          )
        },
        invalidate_target_function = function(names, ...) {
          list_invalidated[[base::length(list_invalidated) + 1L]] <<-
            names
        },
        validate_endpoints = TRUE
      ),
      "unexplained target-level errors"
    )

    testthat::expect_identical(n_pipeline_calls, 2L)
    testthat::expect_length(list_invalidated, 1L)
    testthat::expect_gte(n_diagnoses, 2L)
  }
)

testthat::test_that(
  "CV preparation selectively retries a legacy qs endpoint",
  {
    n_diagnoses <- 0L
    vec_invalidated <- base::character()
    n_pipeline_calls <- 0L

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          n_pipeline_calls <<- n_pipeline_calls + 1L
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) NULL,
        diagnose_endpoints_function = function(...) {
          n_diagnoses <<- n_diagnoses + 1L
          tibble::tibble(
            target_name = "folds_genus",
            endpoint_status = if (
              n_diagnoses == 1L
            ) {
              "cache_format_incompatible"
            } else {
              "prepared"
            },
            data_hash = "hash",
            error_message = if (
              n_diagnoses == 1L
            ) {
              "there is no package called 'qs'"
            } else {
              NA_character_
            }
          )
        },
        invalidate_target_function = function(names, ...) {
          vec_invalidated <<- base::c(vec_invalidated, names)
        },
        validate_endpoints = TRUE
      )

    testthat::expect_identical(n_pipeline_calls, 2L)
    testthat::expect_identical(vec_invalidated, "folds_genus")
    testthat::expect_identical(res[["preparation_status"]], "prepared")
  }
)

testthat::test_that(
  "CV preparation invalidates the unreadable dependency chain",
  {
    n_diagnoses <- 0L
    n_metadata_calls <- 0L
    list_invalidated <- base::list()

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          base::invisible(NULL)
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          n_metadata_calls <<- n_metadata_calls + 1L
          if (
            n_metadata_calls == 1L
          ) {
            return(NULL)
          }
          tibble::tibble(
            name = "data_sample_ids_checked_genus",
            error = paste(
              "could not load dependency data_sample_ids_genus of target",
              "data_sample_ids_checked_genus. there is no package called 'qs'"
            ),
            time = base::Sys.time()
          )
        },
        diagnose_endpoints_function = function(...) {
          n_diagnoses <<- n_diagnoses + 1L
          tibble::tibble(
            target_name = "folds_genus",
            endpoint_status = if (
              n_diagnoses == 1L
            ) {
              "cache_format_incompatible"
            } else {
              "prepared"
            },
            data_hash = "hash",
            error_message = if (
              n_diagnoses == 1L
            ) {
              paste(
                "could not load dependency data_sample_ids_checked_genus",
                "of target folds_genus. there is no package called 'qs'"
              )
            } else {
              NA_character_
            }
          )
        },
        invalidate_target_function = function(names, ...) {
          list_invalidated[[base::length(list_invalidated) + 1L]] <<-
            names
        },
        validate_endpoints = TRUE
      )

    testthat::expect_setequal(
      list_invalidated[[1L]],
      base::c(
        "folds_genus",
        "data_sample_ids_checked_genus",
        "data_sample_ids_genus"
      )
    )
    testthat::expect_identical(res[["preparation_status"]], "prepared")
  }
)

testthat::test_that(
  "CV preparation ignores stale model errors for expected missing folds",
  {
    data_previous_errors <-
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "model_jsdm_genus"
        ),
        error = base::c(
          paste(
            "Not enough cores in this spatial window.",
            "Found 2 core(s); at least 5 required."
          ),
          "Final model did not converge."
        ),
        time = base::as.POSIXct(
          base::c(
            "2026-09-04 13:09:45",
            "2026-08-01 10:00:00"
          ),
          tz = "UTC"
        )
      )

    res <-
      run_sjsdm_cv_preparation_sequence(
        unit_pipeline = "pipeline.R",
        preparation_target_names = "folds_genus",
        unit_store_suffixes = "unit_a",
        run_pipeline_function = function(...) {
          base::invisible(NULL)
        },
        target_store = "stores",
        resolve_store_function = function(store_suffix, ...) {
          store_suffix
        },
        load_metadata_function = function(...) {
          data_previous_errors
        },
        diagnose_endpoints_function = function(...) {
          tibble::tibble(
            target_name = "folds_genus",
            endpoint_status = "missing",
            data_hash = NA_character_,
            error_message = "Target metadata are missing."
          )
        },
        validate_endpoints = TRUE
      )

    testthat::expect_identical(
      res[["preparation_status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(res[["reason_code"]], "insufficient_cores")
  }
)

testthat::test_that(
  "CV preparation reports unexpected failures once per unit",
  {
    error_captured <-
      testthat::expect_error(
        run_sjsdm_cv_preparation_sequence(
          unit_pipeline = "pipeline.R",
          preparation_target_names = base::c(
            "folds_genus",
            "folds_family",
            "folds_ft"
          ),
          unit_store_suffixes = base::c("unit_a", "unit_b"),
          run_pipeline_function = function(...) {
            base::stop("pipeline failed")
          },
          target_store = "stores",
          resolve_store_function = function(store_suffix, ...) {
            store_suffix
          },
          load_metadata_function = function(...) {
            tibble::tibble(
              name = "data_traits",
              error = "Trait file is corrupt.",
              time = base::Sys.time()
            )
          },
          diagnose_endpoints_function = function(...) {
            tibble::tibble(
              target_name = base::c(
                "folds_genus",
                "folds_family",
                "folds_ft"
              ),
              endpoint_status = base::rep("missing", 3L),
              data_hash = base::rep(NA_character_, 3L),
              error_message = base::rep(
                "Target metadata are missing.",
                3L
              )
            )
          },
          validate_endpoints = TRUE
        ),
        "unexplained target-level errors"
      )
    error_message <-
      base::conditionMessage(error_captured)

    testthat::expect_match(error_message, "2 affected units")
    testthat::expect_identical(
      stringr::str_count(error_message, "unit_a"),
      1L
    )
    testthat::expect_identical(
      stringr::str_count(error_message, "unit_b"),
      1L
    )
  }
)

testthat::test_that(
  "prepare_sjsdm_tuning_folds() prepares each fold once",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["count"]] <- 0L

    prepare_fold_function <- function(...) {
      environment_calls[["count"]] <-
        environment_calls[["count"]] + 1L

      return(base::list(prepared = TRUE))
    }

    list_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = prepare_fold_function
      )

    testthat::expect_length(list_folds, 2L)
    testthat::expect_identical(environment_calls[["count"]], 2L)
    testthat::expect_identical(
      purrr::map_chr(list_folds, "preparation_status") |>
        base::unname(),
      base::rep("ok", 2L)
    )
    testthat::expect_identical(
      purrr::map_chr(list_folds, "fold_key") |>
        base::unname(),
      base::c("repeat_001__fold_001", "repeat_001__fold_002")
    )
  }
)

testthat::test_that(
  "prepare_sjsdm_tuning_folds() retains preparation failures",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L)
      )

    list_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = function(...) {
          base::stop("cannot prepare")
        }
      )

    testthat::expect_identical(
      list_folds[[1L]][["preparation_status"]],
      "preparation_error"
    )
    testthat::expect_match(
      list_folds[[1L]][["error_message"]],
      "cannot prepare"
    )
  }
)
testthat::test_that("prepared folds preserve verified cached records", {
  data_assignments <-
    tibble::tibble(
      repeat_id = 1L,
      fold_id = 1:2,
      location_id = base::c("a", "b"),
      n_samples = 1L,
      row_indices = base::list(1L, 2L)
    )
  prepare_fold_function <- function(...) {
    return(base::list(
      mat_response = base::matrix(1:4, nrow = 2L),
      data_spatial_provenance = tibble::tibble(
        strategy = "exact",
        elapsed_seconds = 9,
        basis_bytes = 100,
        estimated_dense_matrix_bytes = 200
      )
    ))
  }
  list_cached <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = prepare_fold_function
    )
  list_cached[[1L]][["preparation_seconds"]] <- 123
  list_cached[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["elapsed_seconds"]] <- 456
  list_cached[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["basis_bytes"]] <- 999
  list_cached[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["estimated_dense_matrix_bytes"]] <- 888
  list_result <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = prepare_fold_function,
      cached_folds_function = function() list_cached
    )
  testthat::expect_identical(list_result, list_cached)
  list_runtime_malformed <-
    list_cached
  list_runtime_malformed[[1L]][["preparation_seconds"]] <- "invalid"
  list_result_malformed <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = prepare_fold_function,
      cached_folds_function = function() list_runtime_malformed
    )
  testthat::expect_false(base::identical(
    list_result_malformed, list_runtime_malformed
  ))

  for (
    field_name in base::c(
      "mat_response", "mat_predictors", "sample_ids", "scaling",
      "unknown_scientific_field"
    )
  ) {
    list_changed <-
      list_cached
    list_changed[[1L]][["list_prepared_fold"]][[field_name]] <- 99
    list_result_changed <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = prepare_fold_function,
        cached_folds_function = function() list_changed
      )
    testthat::expect_false(base::identical(list_result_changed, list_changed))
    testthat::expect_identical(
      prepare_sjsdm_cv_calibration_hash_folds(list_result_changed),
      prepare_sjsdm_cv_calibration_hash_folds(list_cached)
    )
  }
  list_assignments_changed <-
    list_cached
  list_assignments_changed[[1L]][["list_fold_context"]][[
    "test_indices"
  ]] <- 9L
  list_result_assignments <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = prepare_fold_function,
      cached_folds_function = function() list_assignments_changed
    )
  testthat::expect_false(base::identical(
    list_result_assignments, list_assignments_changed
  ))
  list_strategy_changed <-
    list_cached
  list_strategy_changed[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["strategy"]] <- "approximate"
  list_result_strategy <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = prepare_fold_function,
      cached_folds_function = function() list_strategy_changed
    )
  testthat::expect_false(base::identical(
    list_result_strategy, list_strategy_changed
  ))
})

testthat::test_that("prepared folds fail closed on unusable caches", {
  data_assignments <-
    tibble::tibble(
      repeat_id = 1L,
      fold_id = 1:2,
      location_id = base::c("a", "b"),
      n_samples = 1L,
      row_indices = base::list(1L, 2L)
    )
  for (
    cached_folds_function in base::list(
      function() NULL,
      function() "malformed",
      function() base::list(bad = "record"),
      function() base::stop("unreadable")
    )
  ) {
    list_result <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = function(...) base::list(value = 1),
        cached_folds_function = cached_folds_function
      )
    testthat::expect_identical(
      list_result[[1L]][["preparation_status"]], "ok"
    )
  }
  list_failed <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = function(...) base::stop("cannot prepare")
    )
  list_failed[[1L]][["preparation_seconds"]] <- 123
  list_result_failed <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = function(...) base::stop("cannot prepare"),
      cached_folds_function = function() list_failed
    )
  testthat::expect_false(base::identical(list_result_failed, list_failed))
  testthat::expect_identical(
    list_result_failed[[1L]][["preparation_status"]], "preparation_error"
  )
  list_result_recovered <-
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = function(...) base::list(value = 1),
      cached_folds_function = function() list_failed
    )
  testthat::expect_identical(
    list_result_recovered[[1L]][["preparation_status"]], "ok"
  )
  testthat::expect_length(
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments[0L, , drop = FALSE],
      prepare_fold_function = function(...) base::stop("must not run"),
      cached_folds_function = function() base::list()
    ),
    0L
  )
  testthat::expect_error(
    prepare_sjsdm_tuning_folds(
      data_assignments = data_assignments,
      prepare_fold_function = function(...) base::list(),
      cached_folds_function = 1L
    ),
    "reader"
  )
})

testthat::test_that("verified fold reuse preserves downstream target cache", {
  path_project <-
    here::here()
  path_test <-
    withr::local_tempdir()
  withr::local_dir(new = path_test)
  withr::local_options(biodynamics_cache_test_root = path_project)
  targets::tar_script(
    code = {
      path_root <-
        base::getOption("biodynamics_cache_test_root")
      base::source(base::file.path(
        path_root,
        "R/Functions/Modelling/Cross_validation/",
        "prepare_sjsdm_tuning_folds.R"
      ))
      base::source(base::file.path(
        path_root,
        "R/Functions/Modelling/Cross_validation/",
        "prepare_sjsdm_cv_calibration_hash_folds.R"
      ))
      base::source(base::file.path(
        path_root,
        "R/Functions/Modelling/Cross_validation/",
        "build_sjsdm_tuning_fold_context.R"
      ))
      base::source(base::file.path(
        path_root,
        "R/Functions/Modelling/Cross_validation/",
        "load_sjsdm_prepared_fold_cache.R"
      ))
      data_assignments <-
        tibble::tibble(
          repeat_id = 1L,
          fold_id = 1:2,
          location_id = base::c("a", "b"),
          n_samples = 1L,
          row_indices = base::list(1L, 2L)
        )
      base::list(
        targets::tar_target(
          name = response,
          command = base::readRDS("response.rds"),
          format = "rds",
          cue = targets::tar_cue(mode = "always")
        ),
        targets::tar_target(
          name = prepared,
          format = "rds",
          cue = targets::tar_cue(mode = "thorough"),
          command = prepare_sjsdm_tuning_folds(
            data_assignments = data_assignments,
            prepare_fold_function = function(...) {
              return(base::list(
                response = response,
                data_spatial_provenance = tibble::tibble(
                  strategy = "exact",
                  elapsed_seconds = base::as.numeric(base::Sys.time())
                )
              ))
            },
            cached_folds_function = function() {
              load_sjsdm_prepared_fold_cache(
                read_cache_function = base::readRDS
              )
            }
          )
        ),
        targets::tar_target(
          name = fitted,
          format = "rds",
          cue = targets::tar_cue(mode = "thorough"),
          command = {
            count <-
              if (base::file.exists("count.rds")) {
                base::readRDS("count.rds")
              } else {
                0L
              }
            base::saveRDS(count + 1L, file = "count.rds")
            prepared
          }
        )
      )
    }
  )
  base::saveRDS(1L, file = "response.rds")
  targets::tar_make(callr_function = NULL, reporter = "silent")
  list_cached <-
    targets::tar_read_raw(name = "prepared")
  vec_script_changed <-
    readr::read_lines("_targets.R") |>
    stringr::str_replace(
      pattern = stringr::fixed("response = response"),
      replacement = "response = base::identity(response)"
    )
  readr::write_lines(vec_script_changed, file = "_targets.R")
  targets::tar_make(callr_function = NULL, reporter = "silent")
  testthat::expect_identical(base::readRDS("count.rds"), 1L)
  testthat::expect_identical(
    targets::tar_read_raw(name = "prepared"), list_cached
  )
  base::saveRDS(2L, file = "response.rds")
  targets::tar_make(callr_function = NULL, reporter = "silent")
  testthat::expect_identical(base::readRDS("count.rds"), 2L)
  testthat::expect_identical(
    targets::tar_read_raw(name = "prepared")[[1L]][[
      "list_prepared_fold"
    ]][["response"]], 2L
  )
})

testthat::test_that("freshness validates ancestors without analytical work", {
  data_manifest <-
    tibble::tibble(
      name = base::c("config_input", "raw", "folds", "model"),
      command = base::c("1L", "stop('do not execute')", "raw", "folds"),
      cue_mode = base::c("always", "thorough", "thorough", "thorough")
    )
  list_network <-
    base::list(edges = tibble::tibble(
      from = base::c("config_input", "raw", "folds"),
      to = base::c("raw", "folds", "model")
    ))
  vec_checked <- NULL
  testthat::expect_invisible(
    validate_sjsdm_cv_preparation_freshness(
      pipeline_script = "pipeline.R",
      store_path = "store",
      target_names = "folds",
      manifest_function = function(...) data_manifest,
      network_function = function(...) list_network,
      outdated_function = function(names, ...) {
        vec_checked <<-
          base::names(tidyselect::eval_select(
            expr = base::substitute(names), data = stats::setNames(
              base::seq_along(data_manifest[["name"]]),
              data_manifest[["name"]]
            ),
            env = base::parent.frame()
          ))
        base::character()
      },
      read_target_function = function(name, ...) 1L,
      load_metadata_function = function(...) data_manifest
    )
  )
  testthat::expect_setequal(vec_checked, base::c("raw", "folds"))
  testthat::expect_error(
    validate_sjsdm_cv_preparation_freshness(
      pipeline_script = "pipeline.R",
      store_path = "store",
      target_names = "folds",
      manifest_function = function(...) data_manifest,
      network_function = function(...) list_network,
      outdated_function = function(...) "raw",
      read_target_function = function(name, ...) 1L,
      load_metadata_function = function(...) data_manifest
    ),
    "stage 01|01_run_preparation[.]R"
  )
  testthat::expect_error(
    validate_sjsdm_cv_preparation_freshness(
      pipeline_script = "pipeline.R",
      store_path = "store",
      target_names = "folds",
      manifest_function = function(...) data_manifest,
      network_function = function(...) list_network,
      outdated_function = function(...) base::character(),
      read_target_function = function(name, ...) 2L,
      load_metadata_function = function(...) data_manifest
    ),
    "config_input"
  )
})

testthat::test_that("freshness detects real upstream function and file edits", {
  path_fixture <-
    withr::local_tempdir()
  file_fixture_input <-
    fs::path(path_fixture, "input.txt")
  file_pipeline <-
    fs::path(path_fixture, "pipeline.R")
  path_store <-
    fs::path(path_fixture, "store")
  base::writeLines("original", file_fixture_input)
  vec_source <-
    base::c(
      "prepare_fixture <- function(x) x",
      "list(",
      "targets::tar_target(config_input, 1L,",
      "  cue = targets::tar_cue(mode = 'always')),",
      stringr::str_glue(
        "targets::tar_target(file_input, '{file_fixture_input}',",
        " format = 'file'),"),
      "targets::tar_target(raw, readLines(file_input)),",
      "targets::tar_target(folds, prepare_fixture(raw)),",
      "targets::tar_target(model, stop('not executed'))",
      ")"
    )
  base::writeLines(vec_source, file_pipeline)
  targets::tar_make(script = file_pipeline, store = path_store,
    names = "folds", callr_function = NULL, reporter = "silent")
  testthat::expect_invisible(validate_sjsdm_cv_preparation_freshness(
    file_pipeline, path_store, "folds"
  ))
  vec_changed <- vec_source
  vec_changed[[1L]] <- "prepare_fixture <- function(x) toupper(x)"
  base::writeLines(vec_changed, file_pipeline)
  testthat::expect_error(validate_sjsdm_cv_preparation_freshness(
    file_pipeline, path_store, "folds"
  ), "folds")
  base::writeLines(vec_source, file_pipeline)
  base::writeLines("changed", file_fixture_input)
  testthat::expect_error(validate_sjsdm_cv_preparation_freshness(
    file_pipeline, path_store, "folds"
  ), "file_input")
  testthat::expect_false("model" %in%
    targets::tar_meta(store = path_store)[["name"]])
})

testthat::test_that("freshness refuses unknown always-cued work", {
  data_manifest <-
    tibble::tibble(name = "folds", command = "stop('not executed')",
      cue_mode = "always")
  testthat::expect_error(
    validate_sjsdm_cv_preparation_freshness(
      pipeline_script = "pipeline.R", store_path = "store",
      target_names = "folds",
      manifest_function = function(...) data_manifest,
      network_function = function(...) base::list(
        edges = tibble::tibble(from = base::character(),
          to = base::character())
      ),
      outdated_function = function(...) base::character(),
      read_target_function = function(...) base::stop("not executed"),
      load_metadata_function = function(...) data_manifest
    ),
    "always|folds"
  )
})

testthat::test_that("missing configuration dependencies name stage recovery", {
  data_manifest <-
    tibble::tibble(name = base::c("config_input", "raw", "folds"),
      command = base::c("raw", "stop('not executed')", "raw"),
      cue_mode = base::c("always", "thorough", "thorough"))
  testthat::expect_error(validate_sjsdm_cv_preparation_freshness(
    pipeline_script = "pipeline.R", store_path = "store",
    target_names = "folds",
    manifest_function = function(...) data_manifest,
    network_function = function(...) base::list(edges = tibble::tibble(
      from = base::c("raw", "config_input"),
      to = base::c("config_input", "folds"))),
    outdated_function = function(...) base::character(),
    read_target_function = function(...) base::stop("missing cached input"),
    load_metadata_function = function(...) data_manifest
  ), "01_run_preparation[.]R")
})

testthat::test_that("missing cached ancestors block before shortcut checks", {
  for (
    target_missing in base::c(
      "vec_cross_validation_grouped_fold_ladder_family",
      "new_preparation_input"
    )
  ) {
    data_manifest <-
      tibble::tibble(
        name = base::c(target_missing, "folds"),
        command = base::c("base::c(5L, 10L)", target_missing),
        cue_mode = base::c(
          if (
            target_missing == "new_preparation_input"
          ) {
            "thorough"
          } else {
            "always"
          },
          "thorough"
        )
      )
    environment_calls <-
      base::new.env(parent = base::emptyenv())
    environment_calls[["shortcut_calls"]] <- 0L
    testthat::expect_error(validate_sjsdm_cv_preparation_freshness(
      pipeline_script = "pipeline.R", store_path = "store",
      target_names = "folds",
      manifest_function = function(...) data_manifest,
      network_function = function(...) base::list(edges = tibble::tibble(
        from = target_missing, to = "folds")),
      load_metadata_function = function(...) tibble::tibble(name = "folds"),
      read_target_function = function(...) base::stop("missing record"),
      outdated_function = function(...) {
        environment_calls[["shortcut_calls"]] <-
          environment_calls[["shortcut_calls"]] + 1L
        base::stop("cannot bootstrap missing target")
      }
    ), "01_run_preparation[.]R")
    testthat::expect_identical(environment_calls[["shortcut_calls"]], 0L)
  }
})

testthat::test_that("a new fold-ladder record has useful real-store recovery", {
  path_fixture <-
    withr::local_tempdir()
  file_pipeline <-
    fs::path(path_fixture, "pipeline.R")
  path_store <-
    fs::path(path_fixture, "store")
  vec_initial <-
    base::c("list(",
      "targets::tar_target(raw, 1L, format = 'rds'),",
      "targets::tar_target(folds, raw, format = 'rds'),",
      "targets::tar_target(model, stop('must not execute')))")
  base::writeLines(vec_initial, file_pipeline)
  targets::tar_make(script = file_pipeline, store = path_store,
    names = "folds", callr_function = NULL, reporter = "silent")
  vec_changed <-
    base::c("list(",
      "targets::tar_target(raw, 1L, format = 'rds'),",
      "targets::tar_target(vec_cross_validation_grouped_fold_ladder_family,",
      " c(5L, 10L), cue = targets::tar_cue(mode = 'always'),",
      " format = 'rds'),",
      "targets::tar_target(folds,",
      " list(raw, vec_cross_validation_grouped_fold_ladder_family),",
      " format = 'rds'),",
      "targets::tar_target(model, stop('must not execute')))")
  base::writeLines(vec_changed, file_pipeline)
  testthat::expect_error(validate_sjsdm_cv_preparation_freshness(
    file_pipeline, path_store, "folds"
  ), "01_run_preparation[.]R")
  testthat::expect_false("model" %in%
    targets::tar_meta(store = path_store)[["name"]])
  targets::tar_make(script = file_pipeline, store = path_store,
    names = "folds", callr_function = NULL, reporter = "silent")
  testthat::expect_invisible(validate_sjsdm_cv_preparation_freshness(
    file_pipeline, path_store, "folds"
  ))
})

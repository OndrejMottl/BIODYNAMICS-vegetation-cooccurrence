testthat::test_that(
  "run_pipeline_interpolation_prebuild() validates worker count",
  {
    testthat::expect_error(
      run_pipeline_interpolation_prebuild(
        pipeline_script = "pipeline.R",
        pipeline_store = "targets",
        workers = 0L
      ),
      "positive integer"
    )
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() checks core feasibility first",
  {
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    path_counter <- base::file.path(path_test, "counter.txt")
    base::writeLines(
      base::c(
        "library(targets)",
        "tar_option_set(error = 'continue')",
        "list(",
        "  tar_target(",
        "    flag_available_core_count_validated,",
        "    stop('Not enough cores in this spatial window.')",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated,",
        base::sprintf(
          "    {writeLines('started', '%s'); 1L}",
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )

    testthat::expect_error(
      run_pipeline_interpolation_prebuild(
        pipeline_script = path_pipeline,
        pipeline_store = path_store,
        workers = 1L
      ),
      "Not enough cores"
    )
    testthat::expect_false(base::file.exists(path_counter))
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() bootstraps an empty store",
  {
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    base::writeLines(
      base::c(
        "library(targets)",
        "list(",
        "  tar_target(data_community_long_ages, 1L),",
        "  tar_target(",
        "    data_community_proportions,",
        "    data_community_long_ages",
        "  ),",
        "  tar_target(data_age_uncertainty, 2L),",
        "  tar_target(list_community_interpolation_index, 3L),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    data_community_proportions + data_age_uncertainty +",
        "      list_community_interpolation_index",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )

    testthat::expect_equal(
      targets::tar_read_raw(
        name = "data_community_interpolated",
        store = path_store
      ),
      6L
    )
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() passes libraries to workers",
  {
    testthat::skip_if_not_installed("crew")
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    base::writeLines(
      base::c(
        "library(targets)",
        "stopifnot(length(tar_option_get('library')) > 0L)",
        "tar_option_set(controller = build_preprocessing_controller())",
        "list(",
        "  tar_target(data_community_proportions, 1L),",
        "  tar_target(data_age_uncertainty, 2L),",
        "  tar_target(",
        "    list_community_interpolation_index,",
        "    list(1L, 2L), iteration = 'list'",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated_dataset,",
        "    length(qs2::qs_serialize(",
        "      list_community_interpolation_index",
        "    )),",
        "    pattern = map(list_community_interpolation_index)",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    sum(unlist(data_community_interpolated_dataset))",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 2L
    )

    testthat::expect_true(
      targets::tar_read_raw(
        name = "data_community_interpolated",
        store = path_store
      ) > 0L
    )
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() reuses successful interpolation",
  {
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    path_counter <- base::file.path(path_test, "counter.txt")
    base::writeLines(
      base::c(
        "library(targets)",
        base::sprintf(
          'counter_file <- "%s"',
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        "list(",
        "  tar_target(data_community_proportions_shared, 1L),",
        "  tar_target(data_age_uncertainty_shared, 1L),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    {",
        "      count <- if (file.exists(counter_file)) {",
        "        as.integer(readLines(counter_file)) + 1L",
        "      } else {",
        "        1L",
        "      }",
        "      writeLines(as.character(count), counter_file)",
        "      data_community_proportions_shared +",
        "        data_age_uncertainty_shared",
        "    },",
        "    cue = tar_cue(mode = 'thorough')",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )
    targets::tar_make(
      script = path_pipeline,
      store = path_store,
      callr_function = NULL,
      reporter = "silent"
    )

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )

    testthat::expect_equal(base::readLines(path_counter), "1")
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() migrates complete branch caches",
  {
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    path_counter <- base::file.path(path_test, "counter.txt")
    path_provenance <-
      base::file.path(
        path_store,
        "recovery",
        "interpolation_cache_migration_v1.csv"
      )
    vec_common_pipeline <-
      base::c(
        "library(targets)",
        "tar_option_set(format = 'qs')",
        "list(",
        "  tar_target(",
        "    data_community_proportions,",
        "    data.frame(dataset_name = 'core_a', value = 1L)",
        "  ),",
        "  tar_target(",
        "    data_age_uncertainty,",
        "    data.frame(dataset_name = 'core_a', age = 1L)",
        "  ),",
        "  tar_target(data_community_proportions_shared, 1L),",
        "  tar_target(data_age_uncertainty_shared, 1L),",
        "  tar_target(",
        "    list_community_interpolation_index,",
        "    list(list(dataset_name = 'core_a')),",
        "    iteration = 'list'",
        "  ),"
      )
    base::writeLines(
      base::c(
        vec_common_pipeline,
        base::sprintf(
          '  tar_target(data_community_interpolated_dataset, {%s',
          ""
        ),
        base::sprintf(
          "    count <- if (file.exists('%s')) {",
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        base::sprintf(
          "      as.integer(readLines('%s')) + 1L",
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        "    } else { 1L }",
        base::sprintf(
          "    writeLines(as.character(count), '%s')",
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        "    data.frame(",
        "      dataset_name = list_community_interpolation_index[[1L]],",
        "      taxon = 'taxon_a', age = 1L, value = 1L",
        "    )",
        "  }, pattern = map(list_community_interpolation_index)),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    dplyr::bind_rows(data_community_interpolated_dataset)",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )
    targets::tar_make(
      script = path_pipeline,
      store = path_store,
      callr_function = NULL,
      reporter = "silent"
    )
    base::writeLines(
      base::c(
        vec_common_pipeline,
        "  tar_target(",
        "    data_community_interpolated_dataset,",
        "    interpolate_community_dataset_from_shared_inputs(",
        "      list_interpolation_index =",
        "        list_community_interpolation_index",
        "    ),",
        "    pattern = map(list_community_interpolation_index)",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    dplyr::bind_rows(data_community_interpolated_dataset)",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )
    data_result <-
      targets::tar_read_raw(
        name = "data_community_interpolated",
        store = path_store
      )

    testthat::expect_equal(base::readLines(path_counter), "1")
    testthat::expect_equal(data_result[["value"]], 1L)
    testthat::expect_true(base::file.exists(path_provenance))

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )
    testthat::expect_equal(base::readLines(path_counter), "1")
  }
)

testthat::test_that(
  "run_pipeline_interpolation_prebuild() refreshes live mori handles",
  {
    testthat::skip_if_not_installed("crew")
    testthat::skip_if_not_installed("mori")
    path_test <- withr::local_tempdir()
    path_pipeline <- base::file.path(path_test, "pipeline.R")
    path_store <- base::file.path(path_test, "targets")
    path_counter <- base::file.path(path_test, "counter.txt")
    base::writeLines(
      base::c(
        "library(targets)",
        "tar_option_set(",
        "  format = 'qs',",
        "  controller = build_preprocessing_controller()",
        ")",
        base::sprintf(
          'counter_file <- "%s"',
          base::normalizePath(
            path_counter,
            winslash = "/",
            mustWork = FALSE
          )
        ),
        "list(",
        "  tar_target(data_source, data.frame(value = 1L)),",
        "  tar_target(",
        "    data_community_proportions_shared,",
        "    build_shared_interpolation_data(",
        "      data_interpolation = data_source,",
        "      registry_key = 'community'",
        "    ),",
        "    deployment = 'main',",
        "    memory = 'persistent',",
        "    cue = tar_cue(mode = 'always')",
        "  ),",
        "  tar_target(",
        "    list_community_interpolation_index,",
        "    list(1L),",
        "    iteration = 'list'",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated_dataset,",
        "    {",
        "      count <- if (file.exists(counter_file)) {",
        "        as.integer(readLines(counter_file)) + 1L",
        "      } else {",
        "        1L",
        "      }",
        "      writeLines(as.character(count), counter_file)",
        "      descriptor <- data_community_proportions_shared",
        "      shared_name <- readLines(",
        "        file.path(",
        "          Sys.getenv(",
        "            'BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY'",
        "          ),",
        "          paste0(descriptor[['registry_key']], '.txt')",
        "        )",
        "      )",
        "      mori::map_shared(shared_name)[['value']] +",
        "        list_community_interpolation_index",
        "    },",
        "    pattern = map(list_community_interpolation_index)",
        "  ),",
        "  tar_target(",
        "    data_community_interpolated,",
        "    unlist(data_community_interpolated_dataset)",
        "  )",
        ")"
      ),
      con = path_pipeline,
      useBytes = TRUE
    )

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )
    data_meta_first <-
      targets::tar_meta(
        names = tidyselect::all_of(
          "data_community_proportions_shared"
        ),
        fields = base::c("name", "data"),
        store = path_store
      )
    withr::local_options(
      biodynamics.interpolation_shared_registry = NULL
    )
    base::gc()

    run_pipeline_interpolation_prebuild(
      pipeline_script = path_pipeline,
      pipeline_store = path_store,
      workers = 1L
    )
    data_meta_second <-
      targets::tar_meta(
        names = tidyselect::all_of(
          "data_community_proportions_shared"
        ),
        fields = base::c("name", "data"),
        store = path_store
      )

    testthat::expect_equal(base::readLines(path_counter), "1")
    testthat::expect_identical(
      data_meta_first[["data"]],
      data_meta_second[["data"]]
    )
  }
)

testthat::test_that("build_shared_interpolation_data() validates input", {
  testthat::expect_error(
    build_shared_interpolation_data(
      data_interpolation = base::c("a", "b")
    ),
    regexp = "data frame"
  )
})

testthat::test_that("build_shared_interpolation_data() returns shared data", {
  testthat::skip_if_not_installed("mori")
  path_registry <- withr::local_tempdir()
  withr::local_envvar(
    BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
  )

  data_input <-
    tibble::tibble(
      dataset_name = "core_a",
      value = 1
    )

  data_shared <-
    build_shared_interpolation_data(
      data_interpolation = data_input
    )

  testthat::expect_named(
    data_shared,
    base::c("registry_key", "source_hash")
  )
})

testthat::test_that("build_shared_interpolation_data() retains named regions", {
  testthat::skip_if_not_installed("mori")
  withr::local_options(
    biodynamics.interpolation_shared_registry = NULL
  )
  path_registry <- withr::local_tempdir()
  withr::local_envvar(
    BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
  )

  data_input <-
    tibble::tibble(
      dataset_name = "core_a",
      value = 1
    )

  data_shared <-
    build_shared_interpolation_data(
      data_interpolation = data_input,
      registry_key = "community"
    )

  shared_name <-
    base::readLines(
      base::file.path(path_registry, "community.txt"),
      warn = FALSE
    )

  base::rm(data_shared)
  base::gc()

  data_mapped <-
    mori::map_shared(shared_name)

  testthat::expect_equal(data_mapped, data_input)
})

testthat::test_that(
  "build_shared_interpolation_data() validates registry key",
  {
    testthat::skip_if_not_installed("mori")
    path_registry <- withr::local_tempdir()
    withr::local_envvar(
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
    )

    testthat::expect_error(
      build_shared_interpolation_data(
        data_interpolation = tibble::tibble(dataset_name = "core_a"),
        registry_key = ""
      ),
      "registry_key"
    )
  }
)

testthat::test_that(
  "build_shared_interpolation_data() handles 1000 records",
  {
    testthat::skip_if_not_installed("mori")
    path_registry <- withr::local_tempdir()
    withr::local_envvar(
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
    )

    data_interpolation <-
      tibble::tibble(
        dataset_name = "core_a",
        value = base::seq_len(1000L)
      )

    data_shared <-
      build_shared_interpolation_data(
        data_interpolation = data_interpolation
      )

    shared_name <-
      base::readLines(
        base::file.path(
          path_registry,
          stringr::str_glue("{data_shared[['registry_key']]}.txt")
        ),
        warn = FALSE
      )
    data_mapped <- mori::map_shared(shared_name)
    testthat::expect_equal(base::nrow(data_mapped), 1000L)
    testthat::expect_equal(data_mapped, data_interpolation)
  }
)

testthat::test_that(
  "build_shared_interpolation_data() has stable descriptors",
  {
    testthat::skip_if_not_installed("mori")
    path_registry <- withr::local_tempdir()
    withr::local_envvar(
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
    )
    data_input <-
      tibble::tibble(dataset_name = "core_a", value = 1)

    data_shared_first <-
      build_shared_interpolation_data(
        data_interpolation = data_input,
        registry_key = "community"
      )
    data_shared_second <-
      build_shared_interpolation_data(
        data_interpolation = data_input,
        registry_key = "community"
      )
    data_shared_changed <-
      build_shared_interpolation_data(
        data_interpolation = dplyr::mutate(data_input, value = 2),
        registry_key = "community"
      )
    testthat::expect_identical(data_shared_first, data_shared_second)
    testthat::expect_false(
      base::identical(
        data_shared_first[["source_hash"]],
        data_shared_changed[["source_hash"]]
      )
    )
  }
)

testthat::test_that(
  "build_shared_interpolation_data() requires a registry path",
  {
    withr::local_envvar(
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = NA_character_
    )
    testthat::expect_error(
      build_shared_interpolation_data(
        data_interpolation = tibble::tibble(dataset_name = "core_a")
      ),
      regexp = "shared-memory registry"
    )
  }
)

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

  data_input <-
    tibble::tibble(
      dataset_name = "core_a",
      value = 1
    )

  data_shared <-
    build_shared_interpolation_data(
      data_interpolation = data_input
    )

  testthat::expect_s3_class(data_shared, "data.frame")
  testthat::expect_equal(data_shared, data_input)
})

testthat::test_that("build_shared_interpolation_data() retains named regions", {
  testthat::skip_if_not_installed("mori")
  withr::local_options(
    biodynamics.interpolation_shared_registry = NULL
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
    mori::shared_name(data_shared)

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

    data_interpolation <-
      tibble::tibble(
        dataset_name = "core_a",
        value = base::seq_len(1000L)
      )

    data_shared <-
      build_shared_interpolation_data(
        data_interpolation = data_interpolation
      )

    testthat::expect_equal(
      base::nrow(data_shared),
      1000L
    )
    testthat::expect_equal(
      data_shared,
      data_interpolation
    )
  }
)

testthat::test_that("share_interpolation_data() validates data frame", {
  testthat::expect_error(
    share_interpolation_data(data = base::c("a", "b")),
    regexp = "data frame"
  )
})

testthat::test_that("share_interpolation_data() returns data frame object", {
  testthat::skip_if_not_installed("mori")

  data_input <-
    tibble::tibble(
      dataset_name = "core_a",
      value = 1
    )

  data_shared <-
    share_interpolation_data(data = data_input)

  testthat::expect_s3_class(data_shared, "data.frame")
  testthat::expect_equal(data_shared, data_input)
})

testthat::test_that("share_interpolation_data() retains named regions", {
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
    share_interpolation_data(
      data = data_input,
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

testthat::test_that("share_interpolation_data() validates registry key", {
  testthat::skip_if_not_installed("mori")

  testthat::expect_error(
    share_interpolation_data(
      data = tibble::tibble(dataset_name = "core_a"),
      registry_key = ""
    ),
    "registry_key"
  )
})

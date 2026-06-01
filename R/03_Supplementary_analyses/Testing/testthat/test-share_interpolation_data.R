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

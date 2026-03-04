testthat::test_that("prepare_data_for_fit() return correct class", {
  data_example_community <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      age = c(500, 1000),
      taxon = c("taxon1", "taxon2"),
      pollen_prop = c(0.5, 0.7)
    )

  data_example_abiotic <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      age = c(500, 1000),
      abiotic_variable_name = c("abiotic1", "abiotic2"),
      abiotic_value = c(0.5, 0.7)
    )


  result_comm <-
    prepare_data_for_fit(data_example_community, type = "community")

  result_abiotic <-
    prepare_data_for_fit(data_example_abiotic, type = "abiotic")

  testthat::expect_s3_class(result_comm, "data.frame")
  testthat::expect_s3_class(result_abiotic, "data.frame")
})

testthat::test_that("prepare_data_for_fit() return correct values", {
  data_example_community <-
    data.frame(
      dataset_name = rep(c("dataset1", "dataset2"), each = 2),
      age = c(500, 1000, 500, 1000),
      taxon = c("taxon1", "taxon2", "taxon1", "taxon2"),
      pollen_prop = c(0.5, 0.6, 0.7, 0.8)
    )

  data_example_abiotic <-
    data.frame(
      dataset_name = rep(c("dataset1", "dataset2"), each = 2),
      age = c(500, 1000, 500, 1000),
      abiotic_variable_name = c("abiotic1", "abiotic2", "abiotic1", "abiotic2"),
      abiotic_value = c(0.5, 0.6, 0.7, 0.8)
    )

  result_comm <-
    prepare_data_for_fit(data_example_community, type = "community")

  result_abiotic <-
    prepare_data_for_fit(data_example_abiotic, type = "abiotic")

  expected_result_comm <-
    data.frame(
      row_name = c("dataset1__500", "dataset1__1000", "dataset2__500", "dataset2__1000"),
      taxon1 = c(0.5, 0, 0.7, 0),
      taxon2 = c(0, 0.6, 0, 0.8)
    ) %>%
    tibble::column_to_rownames("row_name")

  expected_result_abiotic <-
    data.frame(
      row_name = c("dataset1__500", "dataset1__1000", "dataset2__500", "dataset2__1000"),
      abiotic1 = c(0.5, NA, 0.7, NA),
      abiotic2 = c(NA, 0.6, NA, 0.8)
    ) %>%
    tibble::column_to_rownames("row_name")

  testthat::expect_equal(result_comm, expected_result_comm)
  testthat::expect_equal(result_abiotic, expected_result_abiotic)
})

testthat::test_that("prepare_data_for_fit() handles invalid input", {
  data_example_community <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      age = c(500, 1000),
      taxon = c("taxon1", "taxon2"),
      pollen_prop = c(0.5, 0.7)
    )

  data_example_abiotic <-
    data.frame(
      dataset_name = c("dataset1", "dataset2"),
      age = c(500, 1000),
      abiotic_variable_name = c("abiotic1", "abiotic2"),
      abiotic_value = c(0.5, 0.7)
    )


  testthat::expect_error(
    prepare_data_for_fit(NULL)
  )

  testthat::expect_error(
    prepare_data_for_fit(123)
  )

  testthat::expect_error(
    prepare_data_for_fit(data.frame())
  )

  testthat::expect_error(
    prepare_data_for_fit(
      data = data_example_community,
      type = "invalid_type"
    )
  )

  testthat::expect_error(
    prepare_data_for_fit(
      data = data_example_community,
      type = "abiotic"
    )
  )
})

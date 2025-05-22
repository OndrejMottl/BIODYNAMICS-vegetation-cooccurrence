testthat::test_that("extract_data_from_vegvault returns a data frame for valid input", {
  # Use a known test file or mock file
  test_db <-
    here::here("Data/Input/VegVault.sqlite")

  testthat::skip_if_not(
    file.exists(test_db),
    "Test database not available"
  )

  res <-
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = c(0, 5),
      y_lim = c(0, 10),
      age_lim = c(0, 0),
      sel_dataset_type = c("vegetation_plot", "gridpoints"),
      sel_abiotic_var_name = "bio1"
    )

  testthat::expect_s3_class(res, "data.frame")
})


testthat::test_that("extract_data_from_vegvault handles arguments", {
  test_db <-
    here::here("Data/Input/VegVault.sqlite")

  testthat::skip_if_not(
    file.exists(test_db),
    "Test database not available"
  )

  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = "nonexistent.sqlite"
    )
  )

  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = "c(0, 5)",
      y_lim = c(0, 10),
      age_lim = c(0, 0),
      sel_dataset_type = c("vegetation_plot", "gridpoints"),
      sel_abiotic_var_name = "bio1"
    )
  )
  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = c(0, 5),
      y_lim = "c(0, 10)",
      age_lim = c(0, 0),
      sel_dataset_type = c("vegetation_plot", "gridpoints"),
      sel_abiotic_var_name = "bio1"
    )
  )
  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = c(0, 5),
      y_lim = c(0, 10),
      age_lim = "c(0, 0)",
      sel_dataset_type = c("vegetation_plot", "gridpoints"),
      sel_abiotic_var_name = "bio1"
    )
  )
  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = c(0, 5),
      y_lim = c(0, 10),
      age_lim = c(0, 0),
      sel_dataset_type = 1,
      sel_abiotic_var_name = c("bio1", "bio2")
    )
  )
  testthat::expect_error(
    extract_data_from_vegvault(
      path_to_vegvault = test_db,
      x_lim = c(0, 5),
      y_lim = c(0, 10),
      age_lim = c(0, 0),
      sel_dataset_type = c("vegetation_plot", "gridpoints"),
      sel_abiotic_var_name = 1
    )
  )
})

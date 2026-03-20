# Input Validation (no external database required)

testthat::test_that(
  "extract_data_from_vegvault errors for invalid path_to_vegvault",
  {
    testthat::expect_error(
      extract_data_from_vegvault(path_to_vegvault = 123),
      regexp = "character"
    )

    testthat::expect_error(
      extract_data_from_vegvault(path_to_vegvault = "nonexistent.sqlite"),
      regexp = "VegVault"
    )
  }
)

# Output Structure and further Input Validation (require VegVault database)

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

# tryCatch error-path (no external database required)

testthat::test_that(
  "extract_data_from_vegvault errors when plan build fails",
  {
    # Create a minimal SQLite file so path validation passes
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbDisconnect(conn = db_con)

    # Patch vaultkeepr::open_vault to throw a simulated error
    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop("Simulated vaultkeepr plan error")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      extract_data_from_vegvault(
        path_to_vegvault = tmp_db,
        x_lim = c(0, 5),
        y_lim = c(0, 10),
        age_lim = c(0, 0),
        sel_dataset_type = c("vegetation_plot"),
        sel_abiotic_var_name = "bio1"
      ),
      regexp = "vaultkeepr query plan"
    )

    base::file.remove(tmp_db)
  }
)

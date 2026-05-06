# Input Validation (no external database required)

testthat::test_that(
  "extract_data_from_vegvault errors for NULL plan",
  {
    testthat::expect_error(
      extract_data_from_vegvault(
        plan = NULL,
        sel_abiotic_var_name = "bio1"
      ),
      regexp = "plan"
    )
  }
)

testthat::test_that(
  "extract_data_from_vegvault errors for invalid sel_abiotic_var_name",
  {
    fake_plan <-
      base::list()

    testthat::expect_error(
      extract_data_from_vegvault(
        plan = fake_plan,
        sel_abiotic_var_name = 1L
      ),
      regexp = "sel_abiotic_var_name"
    )

    testthat::expect_error(
      extract_data_from_vegvault(
        plan = fake_plan,
        sel_abiotic_var_name = NULL
      ),
      regexp = "sel_abiotic_var_name"
    )
  }
)

# Output Structure (VegVault database required)

testthat::test_that(
  "extract_data_from_vegvault returns a data frame for valid input",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = base::c(0, 5),
        y_lim = base::c(0, 10),
        age_lim = base::c(0, 0),
        sel_dataset_type = base::c("vegetation_plot", "gridpoints")
      )

    res <-
      extract_data_from_vegvault(
        plan = res_plan,
        sel_abiotic_var_name = "bio1"
      )

    testthat::expect_s3_class(res, "data.frame")
  }
)

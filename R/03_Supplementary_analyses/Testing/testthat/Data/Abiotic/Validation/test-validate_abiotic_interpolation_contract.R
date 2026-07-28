testthat::test_that(
  stringr::str_c(
    "validate_abiotic_interpolation_contract() accepts deterministic ",
    "abiotic input"
  ),
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "dataset1",
      abiotic_variable_name = "bio1",
      age = base::c(0, 500, 1000),
      abiotic_value = base::c(1, 2, 3)
    )

    testthat::expect_invisible(
      validate_abiotic_interpolation_contract(
        data_source = data_abiotic,
        grouping_variables = base::c(
          "dataset_name",
          "abiotic_variable_name"
        ),
        age_variable_name = "age"
      )
    )
  }
)

testthat::test_that(
  "validate_abiotic_interpolation_contract() rejects uncertainty columns",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "dataset1",
      abiotic_variable_name = "bio1",
      age = base::c(0, 500, 1000),
      abiotic_value = base::c(1, 2, 3)
    )

    testthat::expect_error(
      validate_abiotic_interpolation_contract(
        data_source = dplyr::mutate(data_abiotic, iteration = 1L)
      ),
      regexp = "uncertainty"
    )

    testthat::expect_error(
      validate_abiotic_interpolation_contract(
        data_source = dplyr::mutate(
          data_abiotic,
          age_uncertainty = age
        )
      ),
      regexp = "uncertainty"
    )
  }
)

testthat::test_that(
  "validate_abiotic_interpolation_contract() rejects uncertainty routing args",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "dataset1",
      abiotic_variable_name = "bio1",
      age = base::c(0, 500, 1000),
      abiotic_value = base::c(1, 2, 3)
    )

    testthat::expect_error(
      validate_abiotic_interpolation_contract(
        data_source = data_abiotic,
        grouping_variables = base::c("dataset_name", "iteration")
      ),
      regexp = "uncertainty"
    )

    testthat::expect_error(
      validate_abiotic_interpolation_contract(
        data_source = data_abiotic,
        age_variable_name = "age_uncertainty"
      ),
      regexp = "uncertainty"
    )
  }
)

testthat::test_that(
  "guarded abiotic interpolation remains deterministic",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = base::rep("dataset1", 3),
      abiotic_variable_name = base::rep("bio1", 3),
      age = base::c(0, 500, 1000),
      abiotic_value = base::c(1, 2, 3)
    )

    result <- data_abiotic |>
      validate_abiotic_interpolation_contract(
        grouping_variables = base::c(
          "dataset_name",
          "abiotic_variable_name"
        ),
        age_variable_name = "age"
      ) |>
      interpolate_data(
        value_var = "abiotic_value",
        by = base::c("dataset_name", "abiotic_variable_name"),
        age_min = 0,
        age_max = 1000,
        timestep = 500
      )

    testthat::expect_false("iteration" %in% base::colnames(result))
    testthat::expect_false("age_uncertainty" %in% base::colnames(result))
    testthat::expect_equal(
      dplyr::pull(result, abiotic_value),
      base::c(1, 2, 3)
    )
  }
)

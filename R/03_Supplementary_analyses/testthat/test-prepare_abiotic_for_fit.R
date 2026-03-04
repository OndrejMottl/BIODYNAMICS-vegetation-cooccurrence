testthat::test_that(
  "prepare_abiotic_for_fit() errors if abiotic arg not a df",
  {
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_abiotic_for_fit(
        data_abiotic_long = "not_a_df",
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() errors if sample_ids not a df",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      abiotic_variable_name = "temp",
      abiotic_value = 10
    )
    testthat::expect_error(
      prepare_abiotic_for_fit(
        data_abiotic_long = data_abiotic,
        data_sample_ids = 42L
      )
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() errors on missing abiotic columns",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      abiotic_variable_name = "temp"
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_abiotic_for_fit(
        data_abiotic_long = data_abiotic,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() errors on missing sample_ids cols",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      abiotic_variable_name = "temp",
      abiotic_value = 10
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A"
    )
    testthat::expect_error(
      prepare_abiotic_for_fit(
        data_abiotic_long = data_abiotic,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() returns a data frame",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "A", "B", "B"),
      age = c(0, 100, 0, 100),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 12, 8, 9)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "A", "B", "B"),
      age = c(0, 100, 0, 100)
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() output has dataset_name and age",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 8)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::all(
        c("dataset_name", "age") %in% base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() pivots variables to columns",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 0),
      abiotic_variable_name = c("temp", "precip"),
      abiotic_value = c(10, 500)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      "temp" %in% base::colnames(res)
    )
    testthat::expect_true(
      "precip" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() filters rows to sample_ids",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      abiotic_variable_name = "temp",
      abiotic_value = c(10, 8)
    )
    # Only A is in sample_ids
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, dataset_name),
      "A"
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() rows ordered by dataset then age",
  {
    data_abiotic <- tibble::tibble(
      dataset_name = c("B", "A", "A", "B"),
      age = c(100, 0, 100, 0),
      abiotic_variable_name = "temp",
      abiotic_value = c(9, 10, 12, 8)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("B", "A", "A", "B"),
      age = c(100, 0, 100, 0)
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(
      dplyr::pull(res, dataset_name),
      c("A", "A", "B", "B")
    )
    testthat::expect_equal(
      dplyr::pull(res, age),
      c(0, 100, 0, 100)
    )
  }
)

testthat::test_that(
  "prepare_abiotic_for_fit() missing combos are NA in output",
  {
    # A age 0 has temp but B age 0 has precip only
    data_abiotic <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      abiotic_variable_name = c("temp", "precip"),
      abiotic_value = c(10, 500)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_abiotic_for_fit(
      data_abiotic_long = data_abiotic,
      data_sample_ids = data_sample_ids
    )
    vec_temp <- dplyr::pull(res, temp)
    vec_precip <- dplyr::pull(res, precip)
    # A should have NA for precip, B should have NA for temp
    testthat::expect_true(
      base::any(base::is.na(vec_precip))
    )
    testthat::expect_true(
      base::any(base::is.na(vec_temp))
    )
  }
)

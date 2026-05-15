testthat::test_that(
  "validate_community_source() validates required columns",
  {
    data_source <- tibble::tibble(dataset_name = "site_a")

    testthat::expect_error(
      validate_community_source(data_source = data_source),
      regexp = "sample_name"
    )
  }
)


testthat::test_that(
  "validate_community_source() validates numeric columns",
  {
    data_source <- tibble::tibble(
      dataset_name = "site_a",
      sample_name = "s1",
      age = "0",
      taxon = "Abies",
      pollen_count = 1
    )

    testthat::expect_error(
      validate_community_source(data_source = data_source),
      regexp = "age"
    )

    testthat::expect_no_error(
      validate_community_source(
        data_source = data_source,
        check_numeric = FALSE
      )
    )
  }
)


testthat::test_that(
  "validate_community_source() returns invisibly for valid data",
  {
    data_source <- tibble::tibble(
      dataset_name = "site_a",
      sample_name = "s1",
      age = 0,
      taxon = "Abies",
      pollen_count = 1
    )

    res <- validate_community_source(data_source = data_source)

    testthat::expect_equal(res, data_source)
  }
)

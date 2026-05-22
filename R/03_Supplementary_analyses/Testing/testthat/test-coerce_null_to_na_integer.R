testthat::test_that(
  "coerce_null_to_na_integer() converts NULL to missing integer",
  {
    res <-
      coerce_null_to_na_integer(NULL)

    testthat::expect_true(base::is.na(res))
    testthat::expect_type(res, "integer")
  }
)

testthat::test_that(
  "coerce_null_to_na_integer() converts scalar values to integer",
  {
    res <-
      coerce_null_to_na_integer(10.8)

    testthat::expect_identical(res, 10L)
  }
)

testthat::test_that(
  "coerce_null_to_na_integer() validates scalar input",
  {
    testthat::expect_error(
      coerce_null_to_na_integer(c(1, 2)),
      regexp = "value"
    )
  }
)

# Input Validation

testthat::test_that("add_age_column_from_rownames() errors on NULL", {
  testthat::expect_error(
    add_age_column_from_rownames(NULL)
  )
})

testthat::test_that(
  "add_age_column_from_rownames() errors on non-data.frame",
  {
    testthat::expect_error(
      add_age_column_from_rownames(123)
    )

    testthat::expect_error(
      add_age_column_from_rownames("not a data frame")
    )
  }
)

testthat::test_that(
  "add_age_column_from_rownames() errors without __ in row names",
  {
    data_invalid <-
      data.frame(
        dataset_name = c("dataset1__500", "dataset2__1000")
      )

    testthat::expect_error(
      add_age_column_from_rownames(data_invalid)
    )
  }
)

# Output Structure

testthat::test_that("add_age_column_from_rownames() returns correct class", {
  data_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000")
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    add_age_column_from_rownames(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that(
  "add_age_column_from_rownames() result contains age column",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    testthat::expect_true(
      "age" %in% base::colnames(result)
    )
  }
)

testthat::test_that(
  "add_age_column_from_rownames() preserves row count",
  {
    data_example <-
      data.frame(
        row_name = c("d1__500", "d2__1000", "d3__2000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    testthat::expect_equal(
      base::nrow(result),
      base::nrow(data_example)
    )
  }
)

testthat::test_that(
  "add_age_column_from_rownames() age column is numeric",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    age_values <-
      dplyr::pull(result, age)

    testthat::expect_type(age_values, "double")
  }
)

# Functional Correctness

testthat::test_that("add_age_column_from_rownames() returns correct data", {
  data_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000")
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    add_age_column_from_rownames(data_example)

  expected_result <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000"),
      age = c(500, 1000)
    ) %>%
    tibble::column_to_rownames("row_name")

  testthat::expect_equal(result, expected_result)
})

testthat::test_that(
  "add_age_column_from_rownames() handles single-row input",
  {
    data_example <-
      data.frame(row_name = "site1__750") %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    age_values <-
      dplyr::pull(result, age)

    testthat::expect_equal(age_values, 750)
    testthat::expect_equal(base::nrow(result), 1L)
  }
)

testthat::test_that(
  "add_age_column_from_rownames() handles decimal ages",
  {
    data_example <-
      data.frame(
        row_name = c("site1__100.5", "site2__200.75")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    age_values <-
      dplyr::pull(result, age)

    testthat::expect_equal(age_values, c(100.5, 200.75))
  }
)

testthat::test_that(
  "add_age_column_from_rownames() preserves original columns",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        abundance = c(45.5, 62.3)
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_age_column_from_rownames(data_example)

    testthat::expect_true(
      "abundance" %in% base::colnames(result)
    )

    abundance_values <-
      dplyr::pull(result, abundance)

    testthat::expect_equal(abundance_values, c(45.5, 62.3))
  }
)

# Side Effects

testthat::test_that(
  "add_age_column_from_rownames() emits no warnings",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_no_warning(
      add_age_column_from_rownames(data_example)
    )
  }
)

testthat::test_that(
  "add_age_column_from_rownames() emits no messages",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_no_message(
      add_age_column_from_rownames(data_example)
    )
  }
)

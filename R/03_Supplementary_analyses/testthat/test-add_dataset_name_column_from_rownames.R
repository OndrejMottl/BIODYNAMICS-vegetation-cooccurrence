# Input Validation

testthat::test_that(
  "add_dataset_name_column_from_rownames() errors on NULL",
  {
    testthat::expect_error(
      add_dataset_name_column_from_rownames(NULL)
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() errors on non-data.frame",
  {
    testthat::expect_error(
      add_dataset_name_column_from_rownames(123)
    )

    testthat::expect_error(
      add_dataset_name_column_from_rownames("not a data frame")
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() errors without __ in row names",
  {
    data_invalid <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      )

    testthat::expect_error(
      add_dataset_name_column_from_rownames(data_invalid)
    )
  }
)

# Output Structure

testthat::test_that(
  "add_dataset_name_column_from_rownames() returns correct class",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    testthat::expect_s3_class(result, "data.frame")
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() result has dataset_name column",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    testthat::expect_true(
      "dataset_name" %in% base::colnames(result)
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() preserves row count",
  {
    data_example <-
      data.frame(
        row_name = c("d1__500", "d2__1000", "d3__2000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    testthat::expect_equal(
      base::nrow(result),
      base::nrow(data_example)
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() dataset_name column is character",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    name_values <-
      dplyr::pull(result, dataset_name)

    testthat::expect_type(name_values, "character")
  }
)

# Functional Correctness

testthat::test_that(
  "add_dataset_name_column_from_rownames() returns correct data",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    expected_result <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        dataset_name = c("dataset1", "dataset2")
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_equal(result, expected_result)
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() handles single-row input",
  {
    data_example <-
      data.frame(row_name = "mysite__100") %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    name_value <-
      dplyr::pull(result, dataset_name)

    testthat::expect_equal(name_value, "mysite")
    testthat::expect_equal(base::nrow(result), 1L)
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() extracts names with underscores",
  {
    data_example <-
      data.frame(
        row_name = c("my_dataset__500", "other_site__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

    name_values <-
      dplyr::pull(result, dataset_name)

    testthat::expect_equal(
      name_values,
      c("my_dataset", "other_site")
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() preserves original columns",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        abundance = c(45.5, 62.3)
      ) %>%
      tibble::column_to_rownames("row_name")

    result <-
      add_dataset_name_column_from_rownames(data_example)

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
  "add_dataset_name_column_from_rownames() emits no warnings",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_no_warning(
      add_dataset_name_column_from_rownames(data_example)
    )
  }
)

testthat::test_that(
  "add_dataset_name_column_from_rownames() emits no messages",
  {
    data_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000")
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_no_message(
      add_dataset_name_column_from_rownames(data_example)
    )
  }
)

testthat::test_that(
  "prepare_ordered_fold_partition() filters and orders exactly",
  {
    data_source <-
      tibble::tibble(
        sample_id = base::c("c", "a", "b"),
        value = base::c(3, NA_real_, 2)
      )

    data_partition <-
      prepare_ordered_fold_partition(
        data_partition_source = data_source,
        partition_ids = base::c("b", "a"),
        id_column = "sample_id"
      )

    testthat::expect_identical(
      data_partition[["sample_id"]],
      base::c("b", "a")
    )
    testthat::expect_named(data_partition, base::names(data_source))
    testthat::expect_true(base::is.na(data_partition[["value"]][[2L]]))
  }
)

testthat::test_that(
  "prepare_ordered_fold_partition() validates identifiers",
  {
    data_source <-
      tibble::tibble(sample_id = base::c("a", "a"))

    testthat::expect_error(
      prepare_ordered_fold_partition(
        data_partition_source = data_source,
        partition_ids = "a",
        id_column = "sample_id"
      ),
      "unique"
    )

    testthat::expect_error(
      prepare_ordered_fold_partition(
        data_partition_source = tibble::tibble(sample_id = "a"),
        partition_ids = base::c("a", "b"),
        id_column = "sample_id"
      ),
      "missing"
    )
  }
)

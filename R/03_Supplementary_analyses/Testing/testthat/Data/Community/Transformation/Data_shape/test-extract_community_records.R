testthat::test_that(
  "extract_community_records() unnests in-memory community records",
  {
    data_vegvault <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset2"),
        ignored_metadata = base::c("a", "b"),
        data_community = base::list(
          tibble::tibble(
            community_id = 1:2,
            community_name = base::c("A", "B")
          ),
          tibble::tibble(
            community_id = 3:4,
            community_name = base::c("C", "D")
          )
        )
      )

    res_community_records <-
      extract_community_records(data_vegvault = data_vegvault)

    testthat::expect_s3_class(
      res_community_records,
      "data.frame"
    )
    testthat::expect_named(
      res_community_records,
      base::c("dataset_name", "community_id", "community_name")
    )
    testthat::expect_equal(
      base::nrow(res_community_records),
      4L
    )
    testthat::expect_equal(
      dplyr::pull(res_community_records, dataset_name),
      base::c("dataset1", "dataset1", "dataset2", "dataset2")
    )
  }
)

testthat::test_that(
  "extract_community_records() validates its input contract",
  {
    testthat::expect_error(
      extract_community_records(data_vegvault = NULL),
      "must be a data frame"
    )
    testthat::expect_error(
      extract_community_records(data_vegvault = 123),
      "must be a data frame"
    )
    testthat::expect_error(
      extract_community_records(
        data_vegvault = tibble::tibble(dataset_name = "dataset1")
      ),
      "must contain columns"
    )
  }
)

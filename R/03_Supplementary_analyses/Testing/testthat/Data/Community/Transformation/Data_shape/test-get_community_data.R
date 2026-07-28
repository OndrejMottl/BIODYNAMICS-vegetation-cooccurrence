testthat::test_that("get_community_data returns a data frame", {
  data_example <-
    tibble::tibble(
      dataset_name = c("dataset1", "dataset2"),
      data_community = list(
        data.frame(community_id = 1:3, community_name = c("A", "B", "C")),
        data.frame(community_id = 4:6, community_name = c("D", "E", "F"))
      )
    )

  result <-
    get_community_data(data_example)

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("get_community_data handles invalid input", {
  testthat::expect_error(get_community_data(NULL))
  testthat::expect_error(get_community_data(123))
})

testthat::test_that("get_community_data produces expected results", {
  data_example <-
    tibble::tibble(
      dataset_name = c("dataset1", "dataset2"),
      data_community = list(
        data.frame(community_id = 1:3, community_name = c("A", "B", "C")),
        data.frame(community_id = 4:6, community_name = c("D", "E", "F"))
      )
    )

  result <-
    get_community_data(data_example)

  testthat::expect_equal(
    colnames(result),
    c("dataset_name", "community_id", "community_name")
  )

  testthat::expect_equal(
    nrow(result),
    6
  )
})

testthat::test_that("transform_to_proportions returns a data frame", {
  data_example <-
    tibble::tibble(
      sample_name = rep(
        c(
          "sample1", "sample2", "sample3", "sample4", "sample5"
        ),
        each = 2
      ),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        5
      ),
      pollen_count = rep(
        seq(1, 10, by = 2),
        2
      )
    )

  result <-
    transform_to_proportions(
      data_example,
      get_pollen_sum(data_example)
    )

  testthat::expect_s3_class(result, "data.frame")
})

testthat::test_that("transform_to_proportions handles invalid input", {
  testthat::expect_error(transform_to_proportions(NULL, NULL))
  testthat::expect_error(transform_to_proportions(123, 456))
})

testthat::test_that("transform_to_proportions produces expected results", {
  data_example <-
    tibble::tibble(
      sample_name = rep(
        c(
          "sample1", "sample2", "sample3", "sample4", "sample5"
        ),
        each = 2
      ),
      taxon = rep(
        c(
          "taxon1", "taxon2"
        ),
        5
      ),
      pollen_count = rep(
        seq(1, 10, by = 2),
        2
      )
    )

  pollen_sum <-
    get_pollen_sum(data_example)

  result <-
    transform_to_proportions(
      data_example,
      pollen_sum
    )

  testthat::expect_equal(
    colnames(result),
    c("sample_name", "taxon", "pollen_prop")
  )

  testthat::expect_equal(
    result$pollen_prop,
    c(
      data_example$pollen_count /
        rep(
          pollen_sum$pollen_sum,
          each = 2
        )
    )
  )
})

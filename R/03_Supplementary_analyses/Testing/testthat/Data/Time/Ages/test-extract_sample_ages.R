testthat::test_that(
  "extract_sample_ages() unnests ages and drops unrelated columns",
  {
    data_vegvault <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset2"),
        ignored_metadata = base::c("a", "b"),
        data_samples = base::list(
          tibble::tibble(
            sample_name = base::c("sample1", "sample2"),
            age = base::c(100, 200)
          ),
          tibble::tibble(
            sample_name = base::c("sample3", "sample4"),
            age = base::c(300, 400)
          )
        )
      )

    res_sample_ages <-
      extract_sample_ages(data_vegvault = data_vegvault)

    testthat::expect_s3_class(
      res_sample_ages,
      "data.frame"
    )
    testthat::expect_named(
      res_sample_ages,
      base::c("dataset_name", "sample_name", "age")
    )
    testthat::expect_equal(
      dplyr::pull(res_sample_ages, age),
      base::c(100, 200, 300, 400)
    )
    testthat::expect_equal(
      base::nrow(res_sample_ages),
      4L
    )
  }
)

testthat::test_that(
  "extract_sample_ages() validates its input contract",
  {
    testthat::expect_error(
      extract_sample_ages(data_vegvault = NULL),
      "must be a data frame"
    )
    testthat::expect_error(
      extract_sample_ages(
        data_vegvault = tibble::tibble(dataset_name = "dataset1")
      ),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "extract_sample_ages() handles moderately large nested input",
  {
    vec_sample_ids <-
      base::seq_len(1000L)
    data_vegvault <-
      tibble::tibble(
        dataset_name = "dataset1",
        data_samples = base::list(
          tibble::tibble(
            sample_name = stringr::str_c(
              "sample_",
              vec_sample_ids
            ),
            age = vec_sample_ids
          )
        )
      )

    res_sample_ages <-
      extract_sample_ages(data_vegvault = data_vegvault)

    testthat::expect_equal(
      base::nrow(res_sample_ages),
      1000L
    )
    testthat::expect_equal(
      dplyr::pull(res_sample_ages, age),
      vec_sample_ids
    )
  }
)

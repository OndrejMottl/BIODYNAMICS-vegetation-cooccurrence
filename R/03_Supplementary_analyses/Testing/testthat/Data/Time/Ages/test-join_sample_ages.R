testthat::test_that(
  "join_sample_ages() joins ages without changing record order",
  {
    data_records <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset1", "dataset2"),
        sample_name = base::c("sample2", "sample1", "sample3"),
        taxon_count = base::c(20, 10, 30)
      )
    data_sample_ages <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset1"),
        sample_name = base::c("sample1", "sample2"),
        age = base::c(100, 200)
      )

    res_records_with_ages <-
      join_sample_ages(
        data_records = data_records,
        data_sample_ages = data_sample_ages
      )

    testthat::expect_s3_class(
      res_records_with_ages,
      "data.frame"
    )
    testthat::expect_named(
      res_records_with_ages,
      base::c("dataset_name", "sample_name", "taxon_count", "age")
    )
    testthat::expect_equal(
      dplyr::pull(res_records_with_ages, sample_name),
      base::c("sample2", "sample1", "sample3")
    )
    testthat::expect_equal(
      dplyr::pull(res_records_with_ages, age),
      base::c(200, 100, NA_real_)
    )
  }
)

testthat::test_that(
  "join_sample_ages() validates its input contract",
  {
    testthat::expect_error(
      join_sample_ages(
        data_records = NULL,
        data_sample_ages = NULL
      ),
      "data_records must be a data frame"
    )
    testthat::expect_error(
      join_sample_ages(
        data_records = tibble::tibble(
          dataset_name = "dataset1",
          sample_name = "sample1"
        ),
        data_sample_ages = tibble::tibble(
          dataset_name = "dataset1",
          sample_name = "sample1"
        )
      ),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "join_sample_ages() rejects duplicate age keys",
  {
    data_records <-
      tibble::tibble(
        dataset_name = "dataset1",
        sample_name = "sample1"
      )
    data_sample_ages <-
      tibble::tibble(
        dataset_name = base::c("dataset1", "dataset1"),
        sample_name = base::c("sample1", "sample1"),
        age = base::c(100, 200)
      )

    testthat::expect_error(
      join_sample_ages(
        data_records = data_records,
        data_sample_ages = data_sample_ages
      ),
      "must match at most 1 row"
    )
  }
)

testthat::test_that(
  "join_sample_ages() preserves moderately large record sets",
  {
    vec_sample_ids <-
      base::seq_len(1000L)
    vec_sample_names <-
      stringr::str_c(
        "sample_",
        vec_sample_ids
      )
    data_records <-
      tibble::tibble(
        dataset_name = "dataset1",
        sample_name = base::rev(vec_sample_names),
        value = base::rev(vec_sample_ids)
      )
    data_sample_ages <-
      tibble::tibble(
        dataset_name = "dataset1",
        sample_name = vec_sample_names,
        age = vec_sample_ids
      )

    res_records_with_ages <-
      join_sample_ages(
        data_records = data_records,
        data_sample_ages = data_sample_ages
      )

    testthat::expect_equal(
      base::nrow(res_records_with_ages),
      1000L
    )
    testthat::expect_equal(
      dplyr::pull(res_records_with_ages, age),
      base::rev(vec_sample_ids)
    )
  }
)

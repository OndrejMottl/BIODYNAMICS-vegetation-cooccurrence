testthat::test_that(
  "make_community_interpolation_index() validates dataset column",
  {
    testthat::expect_error(
      make_community_interpolation_index(
        data = tibble::tibble(value = 1)
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "make_community_interpolation_index() returns dataset metadata",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core_b", "core_a", "core_b"),
        value = 1:3
      )

    list_index <-
      make_community_interpolation_index(data = data_community)

    testthat::expect_length(list_index, 2L)
    testthat::expect_equal(
      purrr::map_chr(list_index, ~ purrr::chuck(.x, "dataset_name")),
      base::c("core_a", "core_b")
    )
    testthat::expect_false(
      base::any(
        purrr::map_lgl(list_index, ~ purrr::chuck(.x, "flag_empty"))
      )
    )
  }
)

testthat::test_that(
  "make_community_interpolation_index() handles empty community input",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::character(),
        value = base::numeric()
      )

    list_index <-
      make_community_interpolation_index(data = data_community)

    testthat::expect_length(list_index, 1L)
    testthat::expect_true(purrr::chuck(list_index, 1L, "flag_empty"))
    testthat::expect_true(
      base::is.na(purrr::chuck(list_index, 1L, "dataset_name"))
    )
  }
)

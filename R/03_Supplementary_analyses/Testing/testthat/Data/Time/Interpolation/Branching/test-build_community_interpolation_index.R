testthat::test_that(
  "build_community_interpolation_index() validates its input",
  {
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = NULL
      ),
      regexp = "must be a data frame"
    )
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = tibble::tibble(value = 1)
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() returns sorted metadata",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core_b", "core_a", "core_b"),
        value = 1:3
      )

    list_interpolation_index <-
      build_community_interpolation_index(
        data_community = data_community
      )

    testthat::expect_length(list_interpolation_index, 2L)
    testthat::expect_equal(
      purrr::map_chr(
        list_interpolation_index,
        ~ purrr::chuck(.x, "dataset_name")
      ),
      base::c("core_a", "core_b")
    )
    testthat::expect_false(
      base::any(
        purrr::map_lgl(
          list_interpolation_index,
          ~ purrr::chuck(.x, "flag_empty")
        )
      )
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() returns an empty sentinel",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::character(),
        value = base::numeric()
      )

    list_interpolation_index <-
      build_community_interpolation_index(
        data_community = data_community
      )

    testthat::expect_length(list_interpolation_index, 1L)
    testthat::expect_true(
      purrr::chuck(
        list_interpolation_index,
        1L,
        "flag_empty"
      )
    )
    testthat::expect_true(
      base::is.na(
        purrr::chuck(
          list_interpolation_index,
          1L,
          "dataset_name"
        )
      )
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() handles 1000 records",
  {
    data_community <-
      tibble::tibble(
        dataset_name = stringr::str_c(
          "core_",
          base::rep(
            base::seq_len(100L),
            each = 10L
          )
        )
      )

    list_interpolation_index <-
      build_community_interpolation_index(
        data_community = data_community
      )

    testthat::expect_length(
      list_interpolation_index,
      100L
    )
    testthat::expect_false(
      base::any(
        purrr::map_lgl(
          list_interpolation_index,
          ~ purrr::chuck(.x, "flag_empty")
        )
      )
    )
  }
)

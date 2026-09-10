testthat::test_that(
  "build_community_interpolation_index() validates inputs",
  {
    data_valid <- tibble::tibble(dataset_name = "core_a")

    testthat::expect_error(
      build_community_interpolation_index(
        data_community = NULL,
        data_age_uncertainty = data_valid
      ),
      regexp = "must be a data frame"
    )
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = tibble::tibble(value = 1),
        data_age_uncertainty = data_valid
      ),
      regexp = "dataset_name"
    )
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = data_valid,
        data_age_uncertainty = NULL
      ),
      regexp = "data_age_uncertainty must be a data frame"
    )
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = data_valid,
        data_age_uncertainty = tibble::tibble(value = 1)
      ),
      regexp = "data_age_uncertainty.*dataset_name"
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() returns exact sorted ranges",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core_b", "core_b", "core_a")
      )
    data_uncertainty <-
      tibble::tibble(
        dataset_name = base::c("core_a", "core_a")
      )

    list_index <-
      build_community_interpolation_index(
        data_community = data_community,
        data_age_uncertainty = data_uncertainty
      )

    testthat::expect_equal(
      purrr::map_chr(list_index, ~ .x[["dataset_name"]]),
      base::c("core_a", "core_b")
    )
    testthat::expect_equal(
      purrr::map_int(list_index, ~ .x[["index_community_row_start"]]),
      base::c(3L, 1L)
    )
    testthat::expect_equal(
      purrr::map_int(list_index, ~ .x[["index_community_row_end"]]),
      base::c(3L, 2L)
    )
    testthat::expect_equal(
      list_index[[1L]][["index_age_uncertainty_row_start"]],
      1L
    )
    testthat::expect_true(
      base::is.na(
        list_index[[2L]][["index_age_uncertainty_row_start"]]
      )
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() rejects split datasets",
  {
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = tibble::tibble(
          dataset_name = base::c("core_a", "core_b", "core_a")
        ),
        data_age_uncertainty = tibble::tibble(
          dataset_name = base::character()
        )
      ),
      regexp = "data_community.*contiguous"
    )
    testthat::expect_error(
      build_community_interpolation_index(
        data_community = tibble::tibble(dataset_name = "core_a"),
        data_age_uncertainty = tibble::tibble(
          dataset_name = base::c("core_a", "core_b", "core_a")
        )
      ),
      regexp = "data_age_uncertainty.*contiguous"
    )
  }
)

testthat::test_that(
  "build_community_interpolation_index() returns an empty sentinel",
  {
    list_index <-
      build_community_interpolation_index(
        data_community = tibble::tibble(
          dataset_name = base::character()
        ),
        data_age_uncertainty = tibble::tibble(
          dataset_name = base::character()
        )
      )

    testthat::expect_length(list_index, 1L)
    testthat::expect_true(list_index[[1L]][["flag_empty"]])
    testthat::expect_true(
      base::all(
        base::is.na(
          base::unlist(list_index[[1L]][3:6])
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
          base::rep(base::seq_len(100L), each = 10L)
        )
      )
    list_index <-
      build_community_interpolation_index(
        data_community = data_community,
        data_age_uncertainty = tibble::tibble(
          dataset_name = base::character()
        )
      )

    testthat::expect_length(list_index, 100L)
    testthat::expect_false(
      base::any(purrr::map_lgl(list_index, ~ .x[["flag_empty"]]))
    )
  }
)

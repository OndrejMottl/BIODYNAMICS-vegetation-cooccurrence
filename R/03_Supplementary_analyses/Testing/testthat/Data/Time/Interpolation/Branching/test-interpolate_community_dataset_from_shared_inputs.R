testthat::test_that(
  "interpolate_community_dataset_from_shared_inputs() validates index",
  {
    data_community <-
      tibble::tibble(dataset_name = "core_a")

    data_uncertainty <-
      tibble::tibble(dataset_name = "core_a")

    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index =
          base::list(dataset_name = "core_a"),
        data_community = data_community,
        data_age_uncertainty = data_uncertainty
      ),
      regexp = "flag_empty"
    )
  }
)

testthat::test_that(
  "interpolate_community_dataset_from_shared_inputs() matches direct call",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core_a", "core_a", "core_b"),
        sample_name = base::c("sample_a", "sample_b", "sample_c"),
        taxon = "Taxon",
        age = base::c(0, 500, 0),
        value = base::c(0, 1, 0.5)
      )

    data_uncertainty <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        iteration = base::integer(),
        age_uncertainty = base::numeric()
      )

    data_community_shared <-
      build_shared_interpolation_data(
        data_interpolation = data_community
      )

    data_age_uncertainty_shared <-
      build_shared_interpolation_data(
        data_interpolation = data_uncertainty
      )

    data_community_selected <-
      data_community |>
      dplyr::filter(.data[["dataset_name"]] == "core_a")

    data_community_expected <-
      interpolate_paleo_community_with_age_uncertainty(
        data_community = data_community_selected,
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    data_community_interpolated <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = "core_a",
          flag_empty = FALSE
        ),
        data_community = data_community_shared,
        data_age_uncertainty = data_age_uncertainty_shared,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    testthat::expect_equal(
      data_community_interpolated,
      data_community_expected
    )
  }
)

testthat::test_that(
  "interpolate_community_dataset_from_shared_inputs() handles empty index",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        taxon = base::character(),
        age = base::numeric(),
        value = base::numeric()
      )

    data_uncertainty <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        iteration = base::integer(),
        age_uncertainty = base::numeric()
      )

    data_community_interpolated <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = NA_character_,
          flag_empty = TRUE
        ),
        data_community = data_community,
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    testthat::expect_s3_class(
      data_community_interpolated,
      "data.frame"
    )
    testthat::expect_equal(
      base::nrow(data_community_interpolated),
      0L
    )
    testthat::expect_equal(
      base::colnames(data_community_interpolated),
      base::c("dataset_name", "taxon", "age", "value")
    )
  }
)

testthat::test_that(
  "interpolate_community_dataset_from_shared_inputs() filters 1000 records",
  {
    vec_dataset_names <-
      stringr::str_c(
        "core_",
        base::rep(
          base::seq_len(500L),
          each = 2L
        )
      )
    data_community <-
      tibble::tibble(
        dataset_name = vec_dataset_names,
        sample_name = stringr::str_c(
          "sample_",
          base::seq_len(1000L)
        ),
        taxon = "Taxon",
        age = base::rep(
          base::c(0, 500),
          times = 500L
        ),
        value = base::rep(
          base::c(0, 1),
          times = 500L
        )
      )
    data_age_uncertainty <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        iteration = base::integer(),
        age_uncertainty = base::numeric()
      )

    data_community_interpolated <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = "core_500",
          flag_empty = FALSE
        ),
        data_community = data_community,
        data_age_uncertainty = data_age_uncertainty,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    testthat::expect_equal(
      dplyr::pull(
        data_community_interpolated,
        "dataset_name"
      ),
      base::rep("core_500", 2L)
    )
    testthat::expect_equal(
      dplyr::pull(
        data_community_interpolated,
        "value"
      ),
      base::c(0, 1)
    )
  }
)

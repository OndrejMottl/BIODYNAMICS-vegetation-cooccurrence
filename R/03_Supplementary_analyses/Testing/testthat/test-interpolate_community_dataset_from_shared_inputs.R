testthat::test_that(
  "interpolate_community_dataset_from_shared_inputs() validates index",
  {
    data_community <-
      tibble::tibble(dataset_name = "core_a")

    data_uncertainty <-
      tibble::tibble(dataset_name = "core_a")

    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        data_interpolation_index = base::list(dataset_name = "core_a"),
        data = data_community,
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

    data_shared <-
      share_interpolation_data(data = data_community)

    data_uncertainty_shared <-
      share_interpolation_data(data = data_uncertainty)

    data_selected <-
      data_community |>
      dplyr::filter(dataset_name == "core_a")

    data_expected <-
      interpolate_community_data_with_uncertainty(
        data = data_selected,
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        timestep = 500,
        n_cores = 1L
      )

    data_result <-
      interpolate_community_dataset_from_shared_inputs(
        data_interpolation_index = base::list(
          dataset_name = "core_a",
          flag_empty = FALSE
        ),
        data = data_shared,
        data_age_uncertainty = data_uncertainty_shared,
        age_min = 0,
        age_max = 500,
        timestep = 500,
        n_cores = 1L
      )

    testthat::expect_equal(data_result, data_expected)
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

    data_result <-
      interpolate_community_dataset_from_shared_inputs(
        data_interpolation_index = base::list(
          dataset_name = NA_character_,
          flag_empty = TRUE
        ),
        data = data_community,
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        timestep = 500,
        n_cores = 1L
      )

    testthat::expect_s3_class(data_result, "data.frame")
    testthat::expect_equal(base::nrow(data_result), 0L)
    testthat::expect_equal(
      base::colnames(data_result),
      base::c("dataset_name", "taxon", "age", "value")
    )
  }
)

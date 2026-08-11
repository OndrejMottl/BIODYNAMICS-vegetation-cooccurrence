testthat::test_that(
  ".interpolate_fossil_age_iteration_batch() selects iterations",
  {
    data_community <-
      tibble::tibble(
        sample_name = base::c("a", "b"),
        taxon = "oak",
        value = base::c(0.2, 0.8)
      )
    data_age_uncertainty <-
      tidyr::expand_grid(
        sample_name = base::c("a", "b"),
        iteration = 1:2
      ) |>
      dplyr::mutate(
        age_uncertainty = dplyr::if_else(
          .data[["sample_name"]] == "a",
          100,
          200
        )
      )

    data_result <-
      .interpolate_fossil_age_iteration_batch(
        vec_iterations = 2L,
        dataset_name = "core_a",
        data_community = data_community,
        data_age_uncertainty = data_age_uncertainty,
        list_interpolation_arguments = base::list(),
        interpolate_grouped_time_series_function = function(
            data_time_series,
            grouping_variables,
            n_cores) {
          return(data_time_series)
        }
      )

    testthat::expect_equal(base::unique(data_result[["iteration"]]), 2L)
    testthat::expect_equal(
      base::unique(data_result[["dataset_name"]]),
      "core_a"
    )
    testthat::expect_equal(
      base::sort(data_result[["age"]]),
      base::c(100, 200)
    )
  }
)

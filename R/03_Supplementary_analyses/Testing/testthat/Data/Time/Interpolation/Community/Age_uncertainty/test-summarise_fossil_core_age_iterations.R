testthat::test_that(
  ".summarise_fossil_core_age_iterations() returns iteration medians",
  {
    data_community <-
      tibble::tibble(
        sample_name = "a",
        taxon = "oak",
        value = 0.5
      )
    data_age_uncertainty <-
      tibble::tibble(
        sample_name = "a",
        iteration = 1:2,
        age_uncertainty = 100
      )

    data_result <-
      .summarise_fossil_core_age_iterations(
        dataset_name = "core_a",
        data_community = data_community,
        data_age_uncertainty = data_age_uncertainty,
        max_expanded_rows = 1L,
        list_interpolation_arguments = base::list(),
        interpolate_grouped_time_series_function = function(
            data_time_series,
            grouping_variables,
            n_cores) {
          res_data <-
            data_time_series |>
            dplyr::mutate(value = base::as.numeric(.data[["iteration"]]))

          return(res_data)
        }
      )

    testthat::expect_equal(data_result[["value"]], 1.5)
    testthat::expect_equal(data_result[["dataset_name"]], "core_a")
    testthat::expect_equal(data_result[["taxon"]], "oak")
    testthat::expect_equal(data_result[["age"]], 100)
  }
)

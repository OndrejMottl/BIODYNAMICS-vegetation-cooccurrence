testthat::test_that(
  ".compute_interpolation_on_age_grid() interpolates named columns",
  {
    data_time_series_group <-
      tibble::tibble(
        sample_age = base::c(0, 100),
        abundance = base::c(0, 1)
      )

    data_interpolated <-
      .compute_interpolation_on_age_grid(
        data_time_series_group = data_time_series_group,
        age_variable_name = "sample_age",
        value_variable_name = "abundance",
        interpolation_method = "linear",
        extrapolation_rule = 1,
        ties_function = base::mean,
        age_min = 0,
        age_max = 100,
        time_step = 50
      )

    testthat::expect_s3_class(data_interpolated, "tbl_df")
    testthat::expect_named(
      data_interpolated,
      base::c("sample_age", "abundance")
    )
    testthat::expect_equal(
      data_interpolated[["sample_age"]],
      base::c(0, 50, 100)
    )
    testthat::expect_equal(
      data_interpolated[["abundance"]],
      base::c(0, 0.5, 1)
    )
  }
)

testthat::test_that(
  ".compute_interpolation_on_age_grid() handles ties and extrapolation",
  {
    data_time_series_group <-
      tibble::tibble(
        age = base::c(0, 0, 100),
        value = base::c(1, 3, 5)
      )

    data_interpolated <-
      .compute_interpolation_on_age_grid(
        data_time_series_group = data_time_series_group,
        age_variable_name = "age",
        value_variable_name = "value",
        interpolation_method = "linear",
        extrapolation_rule = 2,
        ties_function = base::mean,
        age_min = -100,
        age_max = 200,
        time_step = 100
      )

    testthat::expect_equal(
      data_interpolated[["age"]],
      base::c(-100, 0, 100, 200)
    )
    testthat::expect_equal(
      data_interpolated[["value"]],
      base::c(2, 2, 5, 5)
    )
  }
)

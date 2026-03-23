testthat::test_that(
  "get_spatial_model_params returns correct list structure",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = c("europe", "eu_r001"),
        scale = c("continental", "regional"),
        parent_id = c(NA_character_, "europe"),
        x_min = c(-10, -10),
        x_max = c(40, 0),
        y_min = c(35, 35),
        y_max = c(70, 40),
        n_iter = c(400L, 1600L),
        n_step_size = c(32L, 16L),
        n_sampling = c(100L, 250L),
        n_samples_anova = c(500L, 500L)
      ),
      file = temp_csv
    )

    res <-
      get_spatial_model_params(
        scale_id = "europe",
        file = temp_csv
      )

    testthat::expect_type(res, "list")
    testthat::expect_named(
      res,
      c("n_iter", "n_step_size", "n_sampling", "n_samples_anova")
    )

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params returns correct integer values",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = "europe",
        scale = "continental",
        parent_id = NA_character_,
        x_min = -10,
        x_max = 40,
        y_min = 35,
        y_max = 70,
        n_iter = 400L,
        n_step_size = 32L,
        n_sampling = 100L,
        n_samples_anova = 500L
      ),
      file = temp_csv
    )

    res <-
      get_spatial_model_params(
        scale_id = "europe",
        file = temp_csv
      )

    testthat::expect_equal(res$n_iter, 400L)
    testthat::expect_equal(res$n_step_size, 32L)
    testthat::expect_equal(res$n_sampling, 100L)
    testthat::expect_equal(res$n_samples_anova, 500L)

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params converts NA n_step_size to NULL",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = "eu_r001_l001",
        scale = "local",
        parent_id = "eu_r001",
        x_min = -10,
        x_max = -5,
        y_min = 35,
        y_max = 40,
        n_iter = 3200L,
        n_step_size = NA_integer_,
        n_sampling = 200L,
        n_samples_anova = 500L
      ),
      file = temp_csv
    )

    res <-
      get_spatial_model_params(
        scale_id = "eu_r001_l001",
        file = temp_csv
      )

    testthat::expect_null(res$n_step_size)

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params returns correct values for each row",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = c("europe", "eu_r001"),
        scale = c("continental", "regional"),
        parent_id = c(NA_character_, "europe"),
        x_min = c(-10, -10),
        x_max = c(40, 0),
        y_min = c(35, 35),
        y_max = c(70, 40),
        n_iter = c(400L, 1600L),
        n_step_size = c(32L, 16L),
        n_sampling = c(100L, 250L),
        n_samples_anova = c(500L, 500L)
      ),
      file = temp_csv
    )

    res_regional <-
      get_spatial_model_params(
        scale_id = "eu_r001",
        file = temp_csv
      )

    testthat::expect_equal(res_regional$n_iter, 1600L)
    testthat::expect_equal(res_regional$n_step_size, 16L)
    testthat::expect_equal(res_regional$n_sampling, 250L)

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params errors on unknown scale_id",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = "europe",
        scale = "continental",
        parent_id = NA_character_,
        x_min = -10,
        x_max = 40,
        y_min = 35,
        y_max = 70,
        n_iter = 400L,
        n_step_size = 32L,
        n_sampling = 100L,
        n_samples_anova = 500L
      ),
      file = temp_csv
    )

    testthat::expect_error(
      get_spatial_model_params(
        scale_id = "nonexistent",
        file = temp_csv
      )
    )

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params errors on non-character scale_id",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    readr::write_csv(
      x = tibble::tibble(
        scale_id = "europe",
        scale = "continental",
        parent_id = NA_character_,
        x_min = -10,
        x_max = 40,
        y_min = 35,
        y_max = 70,
        n_iter = 400L,
        n_step_size = 32L,
        n_sampling = 100L,
        n_samples_anova = 500L
      ),
      file = temp_csv
    )

    testthat::expect_error(
      get_spatial_model_params(
        scale_id = 123,
        file = temp_csv
      )
    )

    testthat::expect_error(
      get_spatial_model_params(
        scale_id = c("europe", "america"),
        file = temp_csv
      )
    )

    base::unlink(temp_csv)
  }
)

testthat::test_that(
  "get_spatial_model_params errors on unreadable file",
  {
    testthat::expect_error(
      get_spatial_model_params(
        scale_id = "europe",
        file = "nonexistent_file.csv"
      )
    )
  }
)

testthat::test_that(
  "get_spatial_model_params errors when required columns missing",
  {
    temp_csv <-
      tempfile(fileext = ".csv")

    # CSV missing n_iter, n_step_size, n_sampling, n_samples_anova
    readr::write_csv(
      x = tibble::tibble(
        scale_id = "europe",
        scale = "continental",
        parent_id = NA_character_,
        x_min = -10,
        x_max = 40,
        y_min = 35,
        y_max = 70
      ),
      file = temp_csv
    )

    testthat::expect_error(
      get_spatial_model_params(
        scale_id = "europe",
        file = temp_csv
      )
    )

    base::unlink(temp_csv)
  }
)

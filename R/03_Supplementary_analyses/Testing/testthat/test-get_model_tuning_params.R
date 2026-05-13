write_tuning_file <- function(dir,
                              analysis_id = "paleo_spatial",
                              resolution = "genus",
                              data = NULL) {
  if (
    base::is.null(data)
  ) {
    data <-
      tibble::tibble(
        scale_id = c("europe", "eu_r001"),
        n_iter = c(400L, 1600L),
        n_step_size = c(NA_integer_, 32L),
        n_sampling = c(100L, 250L),
        n_samples_anova = c(500L, 500L),
        n_early_stopping = c(NA_integer_, 0L)
      )
  }

  readr::write_csv(
    x = data,
    file = base::file.path(
      dir,
      stringr::str_glue(
        "model_tuning_{analysis_id}_{resolution}.csv"
      )
    )
  )
}

testthat::test_that(
  "get_model_tuning_params returns expected list structure",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(temp_dir)

    res <-
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "eu_r001",
        resolution_id = "genus",
        dir = temp_dir
      )

    testthat::expect_type(res, "list")
    testthat::expect_named(
      res,
      c(
        "n_iter",
        "n_step_size",
        "n_sampling",
        "n_samples_anova",
        "n_early_stopping"
      )
    )
    testthat::expect_equal(purrr::chuck(res, "n_iter"), 1600L)
    testthat::expect_equal(purrr::chuck(res, "n_step_size"), 32L)
    testthat::expect_equal(purrr::chuck(res, "n_sampling"), 250L)
    testthat::expect_equal(purrr::chuck(res, "n_samples_anova"), 500L)
    testthat::expect_equal(purrr::chuck(res, "n_early_stopping"), 0L)
  }
)

testthat::test_that(
  "get_model_tuning_params maps FT resolution aliases to ft file",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(
      dir = temp_dir,
      resolution = "ft",
      data = tibble::tibble(
        scale_id = "europe",
        n_iter = 800L,
        n_step_size = NA_integer_,
        n_sampling = 200L,
        n_samples_anova = 500L,
        n_early_stopping = 0L
      )
    )

    res_functional_type <-
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "functional_type",
        dir = temp_dir
      )

    res_ft_modern <-
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "ft_modern",
        dir = temp_dir
      )

    testthat::expect_equal(
      purrr::chuck(res_functional_type, "n_iter"),
      800L
    )
    testthat::expect_equal(res_ft_modern, res_functional_type)
  }
)

testthat::test_that(
  "get_model_tuning_params converts missing optional values to NULL",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(temp_dir)

    res <-
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "genus",
        dir = temp_dir
      )

    testthat::expect_null(purrr::pluck(res, "n_step_size"))
    testthat::expect_null(purrr::pluck(res, "n_early_stopping"))
  }
)

testthat::test_that(
  "get_model_tuning_params errors on missing tuning file",
  {
    temp_dir <- base::tempdir()

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "modern_spatial",
        scale_id = "europe",
        resolution_id = "genus",
        dir = temp_dir
      ),
      regexp = "Model tuning file"
    )
  }
)

testthat::test_that(
  "get_model_tuning_params errors on unknown resolution_id",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(temp_dir)

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "species",
        dir = temp_dir
      ),
      regexp = "resolution_id"
    )
  }
)

testthat::test_that(
  "get_model_tuning_params errors when required columns are missing",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(
      dir = temp_dir,
      data = tibble::tibble(
        scale_id = "europe",
        n_iter = 400L
      )
    )

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "genus",
        dir = temp_dir
      ),
      regexp = "must contain columns"
    )
  }
)

testthat::test_that(
  "get_model_tuning_params errors on unknown or duplicate scale_id",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(temp_dir)

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "missing",
        resolution_id = "genus",
        dir = temp_dir
      ),
      regexp = "Expected exactly 1 row"
    )

    write_tuning_file(
      dir = temp_dir,
      data = tibble::tibble(
        scale_id = c("europe", "europe"),
        n_iter = c(400L, 500L),
        n_step_size = c(NA_integer_, NA_integer_),
        n_sampling = c(100L, 100L),
        n_samples_anova = c(500L, 500L),
        n_early_stopping = c(NA_integer_, NA_integer_)
      )
    )

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "genus",
        dir = temp_dir
      ),
      regexp = "Expected exactly 1 row"
    )
  }
)

testthat::test_that(
  "get_model_tuning_params errors when required values are missing",
  {
    temp_dir <- base::tempdir()
    write_tuning_file(
      dir = temp_dir,
      data = tibble::tibble(
        scale_id = "europe",
        n_iter = NA_integer_,
        n_step_size = NA_integer_,
        n_sampling = 100L,
        n_samples_anova = 500L,
        n_early_stopping = NA_integer_
      )
    )

    testthat::expect_error(
      get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = "europe",
        resolution_id = "genus",
        dir = temp_dir
      ),
      regexp = "must not be missing"
    )
  }
)

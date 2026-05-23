testthat::test_that(
  "get_functional_type_classification_path() returns latest path",
  {
    withr::with_tempdir(
      {
        file_old <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-01-01.qs"
          )

        file_new <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-05-23__hash__.qs"
          )

        base::file.create(file_old)
        base::file.create(file_new)

        res <-
          get_functional_type_classification_path(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_equal(res, file_new)
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path() supports prefix",
  {
    withr::with_tempdir(
      {
        file_modern <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_modern_europe_2026-05-23.qs"
          )

        base::file.create(file_modern)

        res <-
          get_functional_type_classification_path(
            continent_id = "europe",
            data_source_prefix = "modern",
            path_processed = base::getwd()
          )

        testthat::expect_equal(res, file_modern)
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path() validates arguments",
  {
    testthat::expect_error(
      get_functional_type_classification_path(
        continent_id = character()
      ),
      regexp = "continent_id"
    )

    testthat::expect_error(
      get_functional_type_classification_path(
        continent_id = "europe",
        data_source_prefix = ""
      ),
      regexp = "data_source_prefix"
    )

    testthat::expect_error(
      get_functional_type_classification_path(
        continent_id = "europe",
        path_processed = base::file.path(base::tempdir(), "missing")
      ),
      regexp = "path_processed"
    )
  }
)

testthat::test_that(
  "get_latest_dated_file_path() returns latest dated file",
  {
    withr::with_tempdir(
      {
        file_old <-
          base::file.path(
            base::getwd(),
            "modern_patterns_unit_2026-01-01.csv"
          )

        file_new <-
          base::file.path(
            base::getwd(),
            "modern_patterns_unit_2026-05-23.csv"
          )

        base::file.create(file_old)
        base::file.create(file_new)

        res <-
          get_latest_dated_file_path(
            file_name_base = "modern_patterns_unit",
            path_directory = base::getwd(),
            file_extension = "csv"
          )

        testthat::expect_equal(res, file_new)
      }
    )
  }
)

testthat::test_that(
  "get_latest_dated_file_path() treats file_name_base literally",
  {
    withr::with_tempdir(
      {
        file_literal <-
          base::file.path(
            base::getwd(),
            "model.v1_2026-05-23.csv"
          )

        file_regex_like <-
          base::file.path(
            base::getwd(),
            "modelXv1_2026-05-24.csv"
          )

        base::file.create(file_literal)
        base::file.create(file_regex_like)

        res <-
          get_latest_dated_file_path(
            file_name_base = "model.v1",
            path_directory = base::getwd(),
            file_extension = "csv"
          )

        testthat::expect_equal(res, file_literal)
      }
    )
  }
)

testthat::test_that(
  "get_latest_dated_file_path() validates arguments",
  {
    testthat::expect_error(
      get_latest_dated_file_path(
        file_name_base = character(),
        path_directory = base::tempdir(),
        file_extension = "csv"
      ),
      regexp = "file_name_base"
    )

    testthat::expect_error(
      get_latest_dated_file_path(
        file_name_base = "x",
        path_directory = base::file.path(base::tempdir(), "missing"),
        file_extension = "csv"
      ),
      regexp = "path_directory"
    )
  }
)

testthat::test_that(
  "get_latest_dated_file_path() errors when no file matches",
  {
    withr::with_tempdir(
      {
        testthat::expect_error(
          get_latest_dated_file_path(
            file_name_base = "definitely_missing_prefix",
            path_directory = base::getwd(),
            file_extension = "csv"
          ),
          regexp = "No `csv` file found"
        )
      }
    )
  }
)

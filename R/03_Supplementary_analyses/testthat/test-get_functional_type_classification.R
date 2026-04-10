testthat::test_that(
  "get_functional_type_classification() errors on non-character id",
  {
    testthat::expect_error(
      get_functional_type_classification(
        continent_id = 123
      )
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors on length > 1 id",
  {
    testthat::expect_error(
      get_functional_type_classification(
        continent_id = base::c("europe", "asia")
      )
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors on empty string id",
  {
    testthat::expect_error(
      get_functional_type_classification(
        continent_id = ""
      )
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors on non-char path",
  {
    dir_temp <-
      base::tempdir()

    testthat::expect_error(
      get_functional_type_classification(
        continent_id = "europe",
        path_processed = 999L
      )
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors on missing dir",
  {
    dir_fake <-
      base::file.path(
        base::tempdir(),
        "nonexistent_traits_dir_xyz"
      )

    testthat::expect_error(
      get_functional_type_classification(
        continent_id = "europe",
        path_processed = dir_fake
      )
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors when no file found",
  {
    withr::with_tempdir(
      {
        testthat::expect_error(
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() errors on partial id match",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_europe <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_europe
        )

        testthat::expect_error(
          get_functional_type_classification(
            continent_id = "eur",
            path_processed = base::getwd()
          )
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() returns a tbl_df",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_s3_class(res, "tbl_df")
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() returns exactly 2 columns",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_asia_2026-01-15.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "asia",
            path_processed = base::getwd()
          )

        testthat::expect_equal(
          base::ncol(res),
          2L
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() has correct column names",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_america_2026-02-10.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "america",
            path_processed = base::getwd()
          )

        testthat::expect_equal(
          base::colnames(res),
          base::c("taxon_name", "functional_type")
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() taxon_name is character",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_type(
          dplyr::pull(res, taxon_name),
          "character"
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() functional_type is numeric",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_true(
          base::is.numeric(
            dplyr::pull(res, functional_type)
          )
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() functional_type has no NAs",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L)
          )

        file_path <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_path
        )

        res <-
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_false(
          base::anyNA(
            dplyr::pull(res, functional_type)
          )
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification() picks most recent file",
  {
    withr::with_tempdir(
      {
        data_old <-
          tibble::tibble(
            taxon_name = base::c("Old_A"),
            functional_type = base::c(9L)
          )

        data_new <-
          tibble::tibble(
            taxon_name = base::c("New_A", "New_B"),
            functional_type = base::c(1L, 2L)
          )

        file_old <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-01-01.qs"
          )

        file_new <-
          base::file.path(
            base::getwd(),
            "data_ft_classification_europe_2026-03-01.qs"
          )

        qs2::qs_save(
          object = data_old,
          file = file_old
        )

        qs2::qs_save(
          object = data_new,
          file = file_new
        )

        res <-
          get_functional_type_classification(
            continent_id = "europe",
            path_processed = base::getwd()
          )

        testthat::expect_equal(
          base::nrow(res),
          2L
        )

        testthat::expect_equal(
          dplyr::pull(res, taxon_name),
          base::c("New_A", "New_B")
        )
      }
    )
  }
)


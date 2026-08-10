testthat::test_that(
  "load_functional_type_classification() returns selected columns",
  {
    withr::with_tempdir(
      {
        data_ft <-
          tibble::tibble(
            taxon_name = base::c("Taxon_A", "Taxon_B"),
            functional_type = base::c(1L, 2L),
            extra_column = base::c("a", "b")
          )

        file_ft <-
          base::file.path(
            base::getwd(),
            "data_functional_type_classification_europe_2026-05-23.qs"
          )

        qs2::qs_save(
          object = data_ft,
          file = file_ft
        )

        res <-
          load_functional_type_classification(path_classification_file = file_ft)

        testthat::expect_s3_class(res, "tbl_df")
        testthat::expect_equal(
          base::colnames(res),
          base::c("taxon_name", "functional_type")
        )
      }
    )
  }
)

testthat::test_that(
  "load_functional_type_classification() validates file",
  {
    testthat::expect_error(
      load_functional_type_classification(path_classification_file = character()),
      regexp = "file"
    )

    testthat::expect_error(
      load_functional_type_classification(
        path_classification_file = base::file.path(base::tempdir(), "missing.qs")
      ),
      regexp = "file"
    )
  }
)

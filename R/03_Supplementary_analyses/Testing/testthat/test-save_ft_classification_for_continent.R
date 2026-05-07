testthat::test_that(
  "save_ft_classification_for_continent() errors on non-character continent_id",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = 123L,
        data_classification = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on length > 1 continent_id",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = base::c("europe", "asia"),
        data_classification = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on empty string continent_id",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "",
        data_classification = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when data_classification is not a data frame",
  {
    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_classification = "not a data frame"
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when path_processed is not character",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_classification = data_cls,
        path_processed = 99L
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on invalid data_source_prefix",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_classification = data_cls,
        data_source_prefix = base::c("modern", "paleo")
      )
    )
    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_classification = data_cls,
        data_source_prefix = ""
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when verbose is not logical",
  {
    data_cls <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        functional_type = base::c(1L, 2L),
        silhouette_width = base::c(0.5, 0.6)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_classification = data_cls,
        verbose = "yes"
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() supports modern file prefix",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            data_source_prefix = "modern",
            verbose = FALSE
          )

        testthat::expect_true(
          base::grepl(
            pattern = stringr::str_c(
              "^data_ft_classification_modern_europe_",
              "\\d{4}-\\d{2}-\\d{2}__[0-9a-f]+__\\.qs$"
            ),
            x = base::basename(res)
          )
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() returns a single character string",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        testthat::expect_type(res, "character")
        testthat::expect_length(res, 1L)
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() returned path exists as a file",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        testthat::expect_true(base::file.exists(res))
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() file name matches expected dated pattern",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        file_name <-
          base::basename(res)

        testthat::expect_true(
          base::grepl(
            pattern = stringr::str_c(
              "^data_ft_classification_europe_",
              "\\d{4}-\\d{2}-\\d{2}__[0-9a-f]+__\\.qs$"
            ),
            x = file_name
          )
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() saved file reads back as a tibble",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        data_loaded <-
          qs2::qs_read(res)

        testthat::expect_true(
          base::inherits(data_loaded, "data.frame")
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() saved content matches input classification",
  {
    withr::with_tempdir(
      {
        data_cls <-
          tibble::tibble(
            taxon_name = base::c("A", "B"),
            functional_type = base::c(1L, 2L),
            silhouette_width = base::c(0.5, 0.6)
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_classification = data_cls,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        data_loaded <-
          qs2::qs_read(res)

        testthat::expect_equal(data_loaded, data_cls)
      }
    )
  }
)

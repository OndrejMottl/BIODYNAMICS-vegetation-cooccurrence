testthat::test_that(
  "save_ft_classification_for_continent() errors on non-char continent_id",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = 123L,
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on length > 1 continent_id",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = base::c("europe", "asia"),
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on empty string continent_id",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on non-data.frame trait_table",
  {
    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = "not a data frame",
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when trait_table missing taxon_name",
  {
    data_tt <-
      tibble::tibble(
        taxon = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on non-data.frame classified",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = "not a data frame"
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when classified missing scale_id",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        continent = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors when classified missing taxon_resolved",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on k_max < 2",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls,
        k_max = 1L
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on non-integer k_max",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls,
        k_max = "ten"
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on non-char path_processed",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls,
        path_processed = 99L
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() errors on non-logical verbose",
  {
    data_tt <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1, 2)
      )

    data_cls <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    testthat::expect_error(
      save_ft_classification_for_continent(
        continent_id = "europe",
        data_trait_table = data_tt,
        data_traits_classified_corrected = data_cls,
        verbose = "yes"
      )
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() returns a single character string",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            ),
            sla = base::c(5, 5.1, 4.9, 5.2, 4.8, 50, 49.8, 50.2, 50.1, 49.9),
            height = base::c(0.5, 0.4, 0.6, 0.5, 0.4, 5, 4.8, 5.2, 5.0, 4.9)
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 10L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
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
  "save_ft_classification_for_continent() returned path is an existing file",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            ),
            sla = base::c(5, 5.1, 4.9, 5.2, 4.8, 50, 49.8, 50.2, 50.1, 49.9),
            height = base::c(0.5, 0.4, 0.6, 0.5, 0.4, 5, 4.8, 5.2, 5.0, 4.9)
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 10L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        testthat::expect_true(base::file.exists(res))
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() file name matches expected pattern",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            ),
            sla = base::c(5, 5.1, 4.9, 5.2, 4.8, 50, 49.8, 50.2, 50.1, 49.9),
            height = base::c(0.5, 0.4, 0.6, 0.5, 0.4, 5, 4.8, 5.2, 5.0, 4.9)
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 10L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        file_name <-
          base::basename(res)

        testthat::expect_true(
          base::grepl(
            "^data_ft_classification_europe_\\d{4}-\\d{2}-\\d{2}\\.qs$",
            file_name
          )
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() saved file is readable tibble",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            ),
            sla = base::c(5, 5.1, 4.9, 5.2, 4.8, 50, 49.8, 50.2, 50.1, 49.9),
            height = base::c(0.5, 0.4, 0.6, 0.5, 0.4, 5, 4.8, 5.2, 5.0, 4.9)
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 10L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        data_loaded <-
          qs2::qs_read(file = res)

        testthat::expect_s3_class(data_loaded, "tbl_df")
        testthat::expect_true(
          "taxon_name" %in% base::colnames(data_loaded)
        )
        testthat::expect_true(
          "functional_type" %in% base::colnames(data_loaded)
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() result contains only continent taxa",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J",
              "K", "L"
            ),
            sla = base::c(
              5, 5.1, 4.9, 5.2, 4.8,
              50, 49.8, 50.2, 50.1, 49.9,
              25, 26
            ),
            height = base::c(
              0.5, 0.4, 0.6, 0.5, 0.4,
              5, 4.8, 5.2, 5.0, 4.9,
              2.5, 2.6
            )
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::c(
              base::rep("europe", 10L),
              base::rep("asia", 2L)
            ),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J",
              "K", "L"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        data_loaded <-
          qs2::qs_read(file = res)

        testthat::expect_false(
          base::any(
            dplyr::pull(data_loaded, "taxon_name") %in%
              base::c("K", "L")
          )
        )
        testthat::expect_true(
          base::all(
            base::c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J") %in%
              dplyr::pull(data_loaded, "taxon_name")
          )
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() drops all-NA trait rows",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J",
              "NA_taxon"
            ),
            sla = base::c(
              5, 5.1, 4.9, 5.2, 4.8,
              50, 49.8, 50.2, 50.1, 49.9,
              NA_real_
            ),
            height = base::c(
              0.5, 0.4, 0.6, 0.5, 0.4,
              5, 4.8, 5.2, 5.0, 4.9,
              NA_real_
            )
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 11L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J",
              "NA_taxon"
            )
          )

        res <-
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 9L,
            path_processed = base::getwd(),
            verbose = FALSE
          )

        data_loaded <-
          qs2::qs_read(file = res)

        testthat::expect_false(
          "NA_taxon" %in% dplyr::pull(data_loaded, "taxon_name")
        )
      }
    )
  }
)

testthat::test_that(
  "save_ft_classification_for_continent() silently caps k_max",
  {
    withr::with_tempdir(
      {
        data_tt <-
          tibble::tibble(
            taxon_name = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            ),
            sla = base::c(5, 5.1, 4.9, 5.2, 4.8, 50, 49.8, 50.2, 50.1, 49.9),
            height = base::c(0.5, 0.4, 0.6, 0.5, 0.4, 5, 4.8, 5.2, 5.0, 4.9)
          )

        data_cls <-
          tibble::tibble(
            scale_id = base::rep("europe", 10L),
            taxon_resolved = base::c(
              "A", "B", "C", "D", "E",
              "F", "G", "H", "I", "J"
            )
          )

        # k_max = 100 is far above nrow = 10; should succeed after silent cap
        testthat::expect_no_error(
          save_ft_classification_for_continent(
            continent_id = "europe",
            data_trait_table = data_tt,
            data_traits_classified_corrected = data_cls,
            k_max = 100L,
            path_processed = base::getwd(),
            verbose = FALSE
          )
        )
      }
    )
  }
)

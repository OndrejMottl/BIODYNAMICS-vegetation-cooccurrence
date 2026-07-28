testthat::test_that(
  "save_missing_taxa_template() validates data_missing_taxa",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = "not a data frame",
          file_missing_taxa_template = file_missing_taxa_template
        )
      )

      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = 123L,
          file_missing_taxa_template = file_missing_taxa_template
        )
      )

      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = base::list(sel_name = "x"),
          file_missing_taxa_template = file_missing_taxa_template
        )
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() validates file_missing_taxa_template",
  {
    withr::with_tempdir({
      data_taxa_classification <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = data_taxa_classification,
          file_missing_taxa_template = 123
        )
      )

      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = data_taxa_classification,
          file_missing_taxa_template = c("a.csv", "b.csv")
        )
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() creates file with rows",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa_classification <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      save_missing_taxa_template(
        data_missing_taxa = data_taxa_classification,
        file_missing_taxa_template = file_missing_taxa_template
      )

      testthat::expect_true(
        base::file.exists(file_missing_taxa_template)
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_missing_taxa_result, sel_name),
        "Taxon A"
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() creates file when empty",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa_classification <-
        tibble::tibble(
          sel_name = base::character(0),
          kingdom = base::character(0),
          phylum = base::character(0),
          class = base::character(0),
          order = base::character(0),
          family = base::character(0),
          genus = base::character(0),
          species = base::character(0)
        )

      save_missing_taxa_template(
        data_missing_taxa = data_taxa_classification,
        file_missing_taxa_template = file_missing_taxa_template
      )

      testthat::expect_true(
        base::file.exists(file_missing_taxa_template)
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        0L
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() appends new taxa",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_missing_taxa_existing <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      readr::write_csv(data_missing_taxa_existing, file_missing_taxa_template)

      data_missing_taxa_new <-
        tibble::tibble(
          sel_name = "Taxon B",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_new,
        file_missing_taxa_template = file_missing_taxa_template
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        2L
      )

      vec_column_names <-
        dplyr::pull(data_missing_taxa_result, sel_name)

      testthat::expect_true(
        "Taxon A" %in% vec_column_names
      )

      testthat::expect_true(
        "Taxon B" %in% vec_column_names
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() deduplicates sel_name",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_missing_taxa_existing <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      readr::write_csv(data_missing_taxa_existing, file_missing_taxa_template)

      data_missing_taxa_duplicates <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = "Plantae",
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_duplicates,
        file_missing_taxa_template = file_missing_taxa_template
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_missing_taxa_result, sel_name),
        "Taxon A"
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() skips write when no change",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_missing_taxa_existing <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      readr::write_csv(data_missing_taxa_existing, file_missing_taxa_template)

      vec_modification_time_before <-
        base::file.info(file_missing_taxa_template)[["mtime"]]

      # Ensure measurable time difference if file is written
      base::Sys.sleep(0.05)

      data_missing_taxa_empty <-
        tibble::tibble(
          sel_name = base::character(0),
          kingdom = base::character(0),
          phylum = base::character(0),
          class = base::character(0),
          order = base::character(0),
          family = base::character(0),
          genus = base::character(0),
          species = base::character(0)
        )

      save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_empty,
        file_missing_taxa_template = file_missing_taxa_template
      )

      vec_modification_time_after <-
        base::file.info(file_missing_taxa_template)[["mtime"]]

      testthat::expect_equal(
        vec_modification_time_before,
        vec_modification_time_after
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() returns file_missing_taxa_template invisibly",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa_classification <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      res_missing_taxa_template <-
        save_missing_taxa_template(
          data_missing_taxa = data_taxa_classification,
          file_missing_taxa_template = file_missing_taxa_template
        )

      testthat::expect_true(
        base::identical(res_missing_taxa_template, file_missing_taxa_template)
      )

      testthat::expect_type(res_missing_taxa_template, "character")
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() writes expected columns",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa_classification <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      save_missing_taxa_template(
        data_missing_taxa = data_taxa_classification,
        file_missing_taxa_template = file_missing_taxa_template
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      vec_expected_columns <-
        base::c(
          "sel_name", "kingdom", "phylum", "class",
          "order", "family", "genus", "species"
        )

      testthat::expect_named(
        data_missing_taxa_result,
        vec_expected_columns,
        ignore.order = FALSE
      )
    })
  }
)

# ── new tests for data_classification_table parameter ───────────────────────

testthat::test_that(
  "save_missing_taxa_template() validates data_classification_table",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa_classification <-
        tibble::tibble(
          sel_name = base::character(0),
          kingdom = base::character(0),
          phylum = base::character(0),
          class = base::character(0),
          order = base::character(0),
          family = base::character(0),
          genus = base::character(0),
          species = base::character(0)
        )

      # Not NULL and not a data frame should error
      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = data_taxa_classification,
          file_missing_taxa_template = file_missing_taxa_template,
          data_classification_table = "not a data frame"
        )
      )

      # Data frame without sel_name should error
      testthat::expect_error(
        save_missing_taxa_template(
          data_missing_taxa = data_taxa_classification,
          file_missing_taxa_template = file_missing_taxa_template,
          data_classification_table = base::data.frame(x = 1)
        )
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() removes stale entries matching classification table",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      # Write an existing template that contains two taxa
      data_missing_taxa_existing <-
        tibble::tibble(
          sel_name = base::c("Taxon A", "Taxon B"),
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      readr::write_csv(data_missing_taxa_existing, file_missing_taxa_template)

      # "Taxon A" is now in the classification table (resolved)
      data_classification_table <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = "Plantae",
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      # No new missing taxa
      data_missing_taxa_new <-
        tibble::tibble(
          sel_name = base::character(0),
          kingdom = base::character(0),
          phylum = base::character(0),
          class = base::character(0),
          order = base::character(0),
          family = base::character(0),
          genus = base::character(0),
          species = base::character(0)
        )

      save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_new,
        file_missing_taxa_template = file_missing_taxa_template,
        data_classification_table = data_classification_table
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      # Taxon A should be removed; Taxon B should remain
      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_missing_taxa_result, sel_name),
        "Taxon B"
      )
    })
  }
)

testthat::test_that(
  "save_missing_taxa_template() NULL data_classification_table preserves behaviour",
  {
    withr::with_tempdir({
      file_missing_taxa_template <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_missing_taxa_existing <-
        tibble::tibble(
          sel_name = "Taxon A",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      readr::write_csv(data_missing_taxa_existing, file_missing_taxa_template)

      data_missing_taxa_new <-
        tibble::tibble(
          sel_name = "Taxon B",
          kingdom = NA_character_,
          phylum = NA_character_,
          class = NA_character_,
          order = NA_character_,
          family = NA_character_,
          genus = NA_character_,
          species = NA_character_
        )

      save_missing_taxa_template(
        data_missing_taxa = data_missing_taxa_new,
        file_missing_taxa_template = file_missing_taxa_template,
        data_classification_table = NULL
      )

      data_missing_taxa_result <-
        readr::read_csv(file_missing_taxa_template, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_missing_taxa_result),
        2L
      )

      vec_column_names <-
        dplyr::pull(data_missing_taxa_result, sel_name)

      testthat::expect_true("Taxon A" %in% vec_column_names)
      testthat::expect_true("Taxon B" %in% vec_column_names)
    })
  }
)

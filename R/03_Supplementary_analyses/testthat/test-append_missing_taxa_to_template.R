testthat::test_that(
  "append_missing_taxa_to_template() validates data_missing_taxa",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      testthat::expect_error(
        append_missing_taxa_to_template(
          data_missing_taxa = "not a data frame",
          file_path = path_tmp
        )
      )

      testthat::expect_error(
        append_missing_taxa_to_template(
          data_missing_taxa = 123L,
          file_path = path_tmp
        )
      )

      testthat::expect_error(
        append_missing_taxa_to_template(
          data_missing_taxa = base::list(sel_name = "x"),
          file_path = path_tmp
        )
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() validates file_path",
  {
    withr::with_tempdir({
      data_taxa <-
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
        append_missing_taxa_to_template(
          data_missing_taxa = data_taxa,
          file_path = 123
        )
      )

      testthat::expect_error(
        append_missing_taxa_to_template(
          data_missing_taxa = data_taxa,
          file_path = c("a.csv", "b.csv")
        )
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() creates file with rows",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_taxa,
        file_path = path_tmp
      )

      testthat::expect_true(
        base::file.exists(path_tmp)
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_result, sel_name),
        "Taxon A"
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() creates file when empty",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_taxa,
        file_path = path_tmp
      )

      testthat::expect_true(
        base::file.exists(path_tmp)
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_result),
        0L
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() appends new taxa",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_existing <-
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

      readr::write_csv(data_existing, path_tmp)

      data_new <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_new,
        file_path = path_tmp
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_result),
        2L
      )

      vec_names <-
        dplyr::pull(data_result, sel_name)

      testthat::expect_true(
        "Taxon A" %in% vec_names
      )

      testthat::expect_true(
        "Taxon B" %in% vec_names
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() deduplicates sel_name",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_existing <-
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

      readr::write_csv(data_existing, path_tmp)

      data_duplicate <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_duplicate,
        file_path = path_tmp
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_result, sel_name),
        "Taxon A"
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() skips write when no change",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_existing <-
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

      readr::write_csv(data_existing, path_tmp)

      mtime_before <-
        base::file.info(path_tmp)[["mtime"]]

      # Ensure measurable time difference if file is written
      base::Sys.sleep(0.05)

      data_empty <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_empty,
        file_path = path_tmp
      )

      mtime_after <-
        base::file.info(path_tmp)[["mtime"]]

      testthat::expect_equal(
        mtime_before,
        mtime_after
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() returns file_path invisibly",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa <-
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

      res <-
        append_missing_taxa_to_template(
          data_missing_taxa = data_taxa,
          file_path = path_tmp
        )

      testthat::expect_true(
        base::identical(res, path_tmp)
      )

      testthat::expect_type(res, "character")
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() writes expected columns",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_taxa,
        file_path = path_tmp
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      vec_expected_cols <-
        base::c(
          "sel_name", "kingdom", "phylum", "class",
          "order", "family", "genus", "species"
        )

      testthat::expect_named(
        data_result,
        vec_expected_cols,
        ignore.order = FALSE
      )
    })
  }
)

# ── new tests for data_classification_table parameter ───────────────────────

testthat::test_that(
  "append_missing_taxa_to_template() validates data_classification_table",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_taxa <-
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
        append_missing_taxa_to_template(
          data_missing_taxa = data_taxa,
          file_path = path_tmp,
          data_classification_table = "not a data frame"
        )
      )

      # Data frame without sel_name should error
      testthat::expect_error(
        append_missing_taxa_to_template(
          data_missing_taxa = data_taxa,
          file_path = path_tmp,
          data_classification_table = base::data.frame(x = 1)
        )
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() removes stale entries matching classification table",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      # Write an existing template that contains two taxa
      data_existing <-
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

      readr::write_csv(data_existing, path_tmp)

      # "Taxon A" is now in the classification table (resolved)
      data_class_table <-
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
      data_new <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_new,
        file_path = path_tmp,
        data_classification_table = data_class_table
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      # Taxon A should be removed; Taxon B should remain
      testthat::expect_equal(
        base::nrow(data_result),
        1L
      )

      testthat::expect_equal(
        dplyr::pull(data_result, sel_name),
        "Taxon B"
      )
    })
  }
)

testthat::test_that(
  "append_missing_taxa_to_template() NULL data_classification_table preserves behaviour",
  {
    withr::with_tempdir({
      path_tmp <-
        base::file.path(base::getwd(), "missing_taxa.csv")

      data_existing <-
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

      readr::write_csv(data_existing, path_tmp)

      data_new <-
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

      append_missing_taxa_to_template(
        data_missing_taxa = data_new,
        file_path = path_tmp,
        data_classification_table = NULL
      )

      data_result <-
        readr::read_csv(path_tmp, show_col_types = FALSE)

      testthat::expect_equal(
        base::nrow(data_result),
        2L
      )

      vec_names <-
        dplyr::pull(data_result, sel_name)

      testthat::expect_true("Taxon A" %in% vec_names)
      testthat::expect_true("Taxon B" %in% vec_names)
    })
  }
)

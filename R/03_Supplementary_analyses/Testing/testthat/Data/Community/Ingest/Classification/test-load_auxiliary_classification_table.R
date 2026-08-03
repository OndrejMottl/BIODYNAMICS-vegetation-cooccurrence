testthat::test_that(
  "load_auxiliary_classification_table() validates file_auxiliary_classification_table type",
  {
    testthat::expect_error(
      load_auxiliary_classification_table(file_auxiliary_classification_table = 123)
    )

    testthat::expect_error(
      load_auxiliary_classification_table(file_auxiliary_classification_table = TRUE)
    )

    testthat::expect_error(
      load_auxiliary_classification_table(file_auxiliary_classification_table = NULL)
    )

    testthat::expect_error(
      load_auxiliary_classification_table(
        file_auxiliary_classification_table = c("path/a.csv", "path/b.csv")
      )
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() returns empty tibble if missing",
  {
    file_auxiliary_classification_table_nonexistent <- base::tempfile(fileext = ".csv")

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(
        file_auxiliary_classification_table = file_auxiliary_classification_table_nonexistent
      )

    testthat::expect_s3_class(res_auxiliary_classification_table, "data.frame")
    testthat::expect_equal(base::nrow(res_auxiliary_classification_table), 0L)
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() reads all 8 columns",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A", "Taxon_B"),
        kingdom  = c("King_A", "King_B"),
        phylum   = c("Phy_A",  "Phy_B"),
        class    = c("Cls_A",  "Cls_B"),
        order    = c("Ord_A",  "Ord_B"),
        family   = c("Fam_A",  "Fam_B"),
        genus    = c("Gen_A",  "Gen_B"),
        species  = c("Sp_A",   "Sp_B")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_s3_class(res_auxiliary_classification_table, "data.frame")
    testthat::expect_equal(base::nrow(res_auxiliary_classification_table), 2L)
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, sel_name),
      c("Taxon_A", "Taxon_B")
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, kingdom),
      c("King_A", "King_B")
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, family),
      c("Fam_A", "Fam_B")
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, genus),
      c("Gen_A", "Gen_B")
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, species),
      c("Sp_A", "Sp_B")
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() errors when sel_name absent",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    testthat::expect_error(
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() fills all aux cols with NA",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A", "Taxon_B")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_s3_class(res_auxiliary_classification_table, "data.frame")
    testthat::expect_equal(base::nrow(res_auxiliary_classification_table), 2L)
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, kingdom)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, phylum)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, class)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, order)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, family)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, genus)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res_auxiliary_classification_table, species)))
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() fills partial missing cols",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_s3_class(res_auxiliary_classification_table, "data.frame")
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
    testthat::expect_equal(
      dplyr::pull(res_auxiliary_classification_table, family),
      "Fam_A"
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, kingdom))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, phylum))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, class))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, order))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, genus))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res_auxiliary_classification_table, species))
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() returns character columns",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, sel_name),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, kingdom),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, phylum),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, class),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, order),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, family),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, genus),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res_auxiliary_classification_table, species),
      "character"
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() drops extra columns",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A"),
        extra_col = c("extra_value")
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_equal(base::ncol(res_auxiliary_classification_table), 8L)
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
  }
)

testthat::test_that(
  "load_auxiliary_classification_table() empty file gives 0-row tibble",
  {
    file_auxiliary_classification_table <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = character(0),
        kingdom  = character(0),
        phylum   = character(0),
        class    = character(0),
        order    = character(0),
        family   = character(0),
        genus    = character(0),
        species  = character(0)
      )

    readr::write_csv(data_input, file_auxiliary_classification_table)

    res_auxiliary_classification_table <-
      load_auxiliary_classification_table(file_auxiliary_classification_table = file_auxiliary_classification_table)

    testthat::expect_s3_class(res_auxiliary_classification_table, "data.frame")
    testthat::expect_equal(base::nrow(res_auxiliary_classification_table), 0L)
    testthat::expect_named(
      res_auxiliary_classification_table,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
  }
)

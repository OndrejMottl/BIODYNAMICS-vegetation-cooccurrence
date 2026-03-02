testthat::test_that(
  "get_aux_classification_table() validates file_path type",
  {
    testthat::expect_error(
      get_aux_classification_table(file_path = 123)
    )

    testthat::expect_error(
      get_aux_classification_table(file_path = TRUE)
    )

    testthat::expect_error(
      get_aux_classification_table(file_path = NULL)
    )

    testthat::expect_error(
      get_aux_classification_table(
        file_path = c("path/a.csv", "path/b.csv")
      )
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() returns empty tibble if missing",
  {
    path_nonexistent <- base::tempfile(fileext = ".csv")

    res <-
      get_aux_classification_table(
        file_path = path_nonexistent
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() reads all 4 columns",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A", "Taxon_B"),
        family = c("Fam_A", "Fam_B"),
        genus = c("Gen_A", "Gen_B"),
        species = c("Sp_A", "Sp_B")
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
    testthat::expect_equal(
      dplyr::pull(res, sel_name),
      c("Taxon_A", "Taxon_B")
    )
    testthat::expect_equal(
      dplyr::pull(res, family),
      c("Fam_A", "Fam_B")
    )
    testthat::expect_equal(
      dplyr::pull(res, genus),
      c("Gen_A", "Gen_B")
    )
    testthat::expect_equal(
      dplyr::pull(res, species),
      c("Sp_A", "Sp_B")
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() errors when sel_name absent",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A")
      )

    readr::write_csv(data_input, path_tmp)

    testthat::expect_error(
      get_aux_classification_table(file_path = path_tmp),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() fills all aux cols with NA",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A", "Taxon_B")
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res, family)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res, genus)))
    )
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res, species)))
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() fills partial missing cols",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A")
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
    testthat::expect_equal(
      dplyr::pull(res, family),
      "Fam_A"
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res, genus))
    )
    testthat::expect_true(
      base::is.na(dplyr::pull(res, species))
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() returns character columns",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A")
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_type(
      dplyr::pull(res, sel_name),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res, family),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res, genus),
      "character"
    )
    testthat::expect_type(
      dplyr::pull(res, species),
      "character"
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() drops extra columns",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = c("Taxon_A"),
        family = c("Fam_A"),
        genus = c("Gen_A"),
        species = c("Sp_A"),
        extra_col = c("extra_value")
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_equal(base::ncol(res), 4L)
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
  }
)

testthat::test_that(
  "get_aux_classification_table() empty file gives 0-row tibble",
  {
    path_tmp <- withr::local_tempfile(fileext = ".csv")

    data_input <-
      tibble::tibble(
        sel_name = character(0),
        family = character(0),
        genus = character(0),
        species = character(0)
      )

    readr::write_csv(data_input, path_tmp)

    res <-
      get_aux_classification_table(file_path = path_tmp)

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
      c("sel_name", "family", "genus", "species")
    )
  }
)

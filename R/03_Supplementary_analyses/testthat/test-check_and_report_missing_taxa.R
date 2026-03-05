testthat::test_that(
  "error when vec_taxa_without_classification is not character",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = 123L,
        template_file_path = base::tempfile(fileext = ".csv")
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "error when vec_taxa_without_classification is numeric",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c(1.1, 2.2),
        template_file_path = base::tempfile(fileext = ".csv")
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "error when template_file_path is not a character",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = character(0),
        template_file_path = 42L
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "error when template_file_path has length greater than 1",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = character(0),
        template_file_path = c(
          base::tempfile(fileext = ".csv"),
          base::tempfile(fileext = ".csv")
        )
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "returns TRUE invisibly when no taxa are missing",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    result <- check_and_report_missing_taxa(
      vec_taxa_without_classification = character(0),
      template_file_path = vec_template_path
    )

    testthat::expect_true(
      isTRUE(result)
    )
  }
)

testthat::test_that(
  "does not create a file when no taxa are missing",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    check_and_report_missing_taxa(
      vec_taxa_without_classification = character(0),
      template_file_path = vec_template_path
    )

    testthat::expect_false(
      base::file.exists(vec_template_path)
    )
  }
)

testthat::test_that(
  "stops with an error when missing taxa are present",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a", "Taxon_b"),
        template_file_path = vec_template_path
      )
    )
  }
)

testthat::test_that(
  "error message contains count of missing taxa",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c(
          "Taxon_a",
          "Taxon_b",
          "Taxon_c"
        ),
        template_file_path = vec_template_path
      ),
      regexp = "3"
    )
  }
)

testthat::test_that(
  "writes a CSV file to template_file_path when taxa are missing",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    try(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a"),
        template_file_path = vec_template_path
      ),
      silent = TRUE
    )

    testthat::expect_true(
      base::file.exists(vec_template_path)
    )
  }
)

testthat::test_that(
  "written CSV has correct column names",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    try(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a"),
        template_file_path = vec_template_path
      ),
      silent = TRUE
    )

    data_result <- readr::read_csv(
      file = vec_template_path,
      show_col_types = FALSE
    )

    testthat::expect_named(
      data_result,
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    )
  }
)

testthat::test_that(
  "written CSV has one row per missing taxon",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")
    vec_missing <- c("Taxon_a", "Taxon_b", "Taxon_c")

    try(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = vec_missing,
        template_file_path = vec_template_path
      ),
      silent = TRUE
    )

    data_result <- readr::read_csv(
      file = vec_template_path,
      show_col_types = FALSE
    )

    testthat::expect_equal(
      base::nrow(data_result),
      base::length(vec_missing)
    )
  }
)

testthat::test_that(
  "CSV sel_name column is pre-filled with missing taxon names",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")
    vec_missing <- c("Taxon_a", "Taxon_b")

    try(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = vec_missing,
        template_file_path = vec_template_path
      ),
      silent = TRUE
    )

    data_result <- readr::read_csv(
      file = vec_template_path,
      show_col_types = FALSE
    )

    testthat::expect_equal(
      dplyr::pull(data_result, sel_name),
      vec_missing
    )
  }
)

testthat::test_that(
  "CSV all rank columns are all NA",
  {
    vec_template_path <- base::tempfile(fileext = ".csv")

    try(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a", "Taxon_b"),
        template_file_path = vec_template_path
      ),
      silent = TRUE
    )

    data_result <- readr::read_csv(
      file = vec_template_path,
      show_col_types = FALSE
    )

    for (
      col_name in c(
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    ) {
      testthat::expect_true(
        base::all(base::is.na(dplyr::pull(data_result, col_name))),
        label = paste(col_name, "should be all NA")
      )
    }
  }
)

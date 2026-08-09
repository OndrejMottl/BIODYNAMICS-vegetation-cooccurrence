# --- Argument validation ---

testthat::test_that(
  "render_trait_quality_control_report() errors on invalid trait_domain_filter",
  {
    testthat::expect_error(
      render_trait_quality_control_report(trait_domain_filter = 123L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(trait_domain_filter = TRUE)
    )

    testthat::expect_error(
      render_trait_quality_control_report(
        trait_domain_filter = c("Leaf Area", "SLA")
      )
    )
  }
)

testthat::test_that(
  "render_trait_quality_control_report() errors on invalid path_report_directory",
  {
    testthat::expect_error(
      render_trait_quality_control_report(path_report_directory = 123L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(path_report_directory = NULL)
    )

    testthat::expect_error(
      render_trait_quality_control_report(
        path_report_directory = c("dir_a", "dir_b")
      )
    )
  }
)

testthat::test_that(
  "render_trait_quality_control_report() errors on invalid maximum_pages",
  {
    testthat::expect_error(
      render_trait_quality_control_report(maximum_pages = "ten")
    )

    testthat::expect_error(
      render_trait_quality_control_report(maximum_pages = -1L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(maximum_pages = 0L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(maximum_pages = c(5L, 10L))
    )
  }
)

testthat::test_that(
  "render_trait_quality_control_report() errors on invalid minimum_taxonomic_records",
  {
    testthat::expect_error(
      render_trait_quality_control_report(minimum_taxonomic_records = "five")
    )

    testthat::expect_error(
      render_trait_quality_control_report(minimum_taxonomic_records = 0L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(minimum_taxonomic_records = -1L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(minimum_taxonomic_records = NULL)
    )

    testthat::expect_error(
      render_trait_quality_control_report(minimum_taxonomic_records = c(3L, 5L))
    )
  }
)

testthat::test_that(
  "render_trait_quality_control_report() errors on invalid verbose",
  {
    testthat::expect_error(
      render_trait_quality_control_report(verbose = "yes")
    )

    testthat::expect_error(
      render_trait_quality_control_report(verbose = 1L)
    )

    testthat::expect_error(
      render_trait_quality_control_report(verbose = NULL)
    )
  }
)

# --- Output filename: NULL domain ---

testthat::test_that(
  "render_trait_quality_control_report() names file correctly when domain is NULL",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    render_trait_quality_control_report(
      trait_domain_filter = NULL,
      path_report_directory = dir_output,
      path_render_directory = dir_docs,
      verbose = FALSE
    )

    dest_path <-
      base::file.path(dir_output, expected_name)

    testthat::expect_true(
      base::file.exists(dest_path)
    )
  }
)

# --- Output filename: character domain ---

testthat::test_that(
  "render_trait_quality_control_report() slugifies domain in output filename",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_Leaf_Area_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    render_trait_quality_control_report(
      trait_domain_filter = "Leaf Area",
      path_report_directory = dir_output,
      path_render_directory = dir_docs,
      verbose = FALSE
    )

    dest_path <-
      base::file.path(dir_output, expected_name)

    testthat::expect_true(
      base::file.exists(dest_path)
    )
  }
)

testthat::test_that(
  "render_trait_quality_control_report() names file correctly for simple domain",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_SLA_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    render_trait_quality_control_report(
      trait_domain_filter = "SLA",
      path_report_directory = dir_output,
      path_render_directory = dir_docs,
      verbose = FALSE
    )

    dest_path <-
      base::file.path(dir_output, expected_name)

    testthat::expect_true(
      base::file.exists(dest_path)
    )
  }
)

# --- File move (not copy) ---

testthat::test_that(
  "render_trait_quality_control_report() moves file: absent source, present dest",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    source_path <-
      base::file.path(dir_docs, expected_name)

    write_mock_rendered_report <- function(...) {
      base::writeLines("pdf", source_path)
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    render_trait_quality_control_report(
      trait_domain_filter = NULL,
      path_report_directory = dir_output,
      path_render_directory = dir_docs,
      verbose = FALSE
    )

    dest_path <-
      base::file.path(dir_output, expected_name)

    testthat::expect_true(
      base::file.exists(dest_path)
    )

    testthat::expect_false(
      base::file.exists(source_path)
    )
  }
)

# --- PDF compression called in-place ---

testthat::test_that(
  "render_trait_quality_control_report() calls pdf_compress() in-place",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    compress_calls <-
      base::list()

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    compress_mock_report <- function(input, ...) {
      compress_calls[[base::length(compress_calls) + 1L]] <<-
        base::list(input = input)
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = compress_mock_report,
      .package = "qpdf"
    )

    render_trait_quality_control_report(
      trait_domain_filter = NULL,
      path_report_directory = dir_output,
      path_render_directory = dir_docs,
      verbose = FALSE
    )

    expected_rendered <-
      base::file.path(dir_docs, expected_name)

    testthat::expect_length(compress_calls, 1L)

    testthat::expect_true(
      compress_calls[[1L]][["input"]] == expected_rendered
    )
  }
)

# --- Missing rendered file: warning emitted ---

testthat::test_that(
  "render_trait_quality_control_report() warns when rendered file not found",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    skip_mock_report_render <- function(...) {
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = skip_mock_report_render,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    testthat::expect_warning(
      render_trait_quality_control_report(
        trait_domain_filter = NULL,
        path_report_directory = dir_output,
        path_render_directory = dir_docs,
        verbose = TRUE
      )
    )
  }
)

# --- verbose = FALSE suppresses message ---

testthat::test_that(
  "render_trait_quality_control_report() emits no message when verbose FALSE",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    testthat::expect_no_message(
      render_trait_quality_control_report(
        trait_domain_filter = NULL,
        path_report_directory = dir_output,
        path_render_directory = dir_docs,
        verbose = FALSE
      )
    )
  }
)

# --- verbose = TRUE emits a message on success ---

testthat::test_that(
  "render_trait_quality_control_report() emits a message when verbose TRUE",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    testthat::expect_message(
      render_trait_quality_control_report(
        trait_domain_filter = NULL,
        path_report_directory = dir_output,
        path_render_directory = dir_docs,
        verbose = TRUE
      )
    )
  }
)

# --- Return value ---

testthat::test_that(
  "render_trait_quality_control_report() returns invisible NULL",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_quality_control_report_{Sys.Date()}.pdf"
      )

    write_mock_rendered_report <- function(...) {
      base::writeLines(
        "pdf",
        base::file.path(dir_docs, expected_name)
      )
      return(base::invisible(NULL))
    }

    write_mock_compressed_report <- function(input, ...) {
      path_compressed_report <- base::tempfile(fileext = ".pdf")
      base::writeLines("compressed", path_compressed_report)
      return(path_compressed_report)
    }

    testthat::local_mocked_bindings(
      quarto_render = write_mock_rendered_report,
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = write_mock_compressed_report,
      .package = "qpdf"
    )

    result <-
      render_trait_quality_control_report(
        trait_domain_filter = NULL,
        path_report_directory = dir_output,
        path_render_directory = dir_docs,
        verbose = FALSE
      )

    testthat::expect_null(result)
  }
)

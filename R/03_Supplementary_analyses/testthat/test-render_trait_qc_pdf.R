# --- Argument validation ---

testthat::test_that(
  "render_trait_qc_pdf() errors on invalid sel_domain_filter",
  {
    testthat::expect_error(
      render_trait_qc_pdf(sel_domain_filter = 123L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_domain_filter = TRUE)
    )

    testthat::expect_error(
      render_trait_qc_pdf(
        sel_domain_filter = c("Leaf Area", "SLA")
      )
    )
  }
)

testthat::test_that(
  "render_trait_qc_pdf() errors on invalid path_output_dir",
  {
    testthat::expect_error(
      render_trait_qc_pdf(path_output_dir = 123L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(path_output_dir = NULL)
    )

    testthat::expect_error(
      render_trait_qc_pdf(
        path_output_dir = c("dir_a", "dir_b")
      )
    )
  }
)

testthat::test_that(
  "render_trait_qc_pdf() errors on invalid sel_max_pages",
  {
    testthat::expect_error(
      render_trait_qc_pdf(sel_max_pages = "ten")
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_max_pages = -1L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_max_pages = 0L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_max_pages = c(5L, 10L))
    )
  }
)

testthat::test_that(
  "render_trait_qc_pdf() errors on invalid sel_min_n_family",
  {
    testthat::expect_error(
      render_trait_qc_pdf(sel_min_n_family = "five")
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_min_n_family = 0L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_min_n_family = -1L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_min_n_family = NULL)
    )

    testthat::expect_error(
      render_trait_qc_pdf(sel_min_n_family = c(3L, 5L))
    )
  }
)

testthat::test_that(
  "render_trait_qc_pdf() errors on invalid verbose",
  {
    testthat::expect_error(
      render_trait_qc_pdf(verbose = "yes")
    )

    testthat::expect_error(
      render_trait_qc_pdf(verbose = 1L)
    )

    testthat::expect_error(
      render_trait_qc_pdf(verbose = NULL)
    )
  }
)

# --- Output filename: NULL domain ---

testthat::test_that(
  "render_trait_qc_pdf() names file correctly when domain is NULL",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    render_trait_qc_pdf(
      sel_domain_filter = NULL,
      path_output_dir = dir_output,
      path_docs_dir = dir_docs,
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
  "render_trait_qc_pdf() slugifies domain in output filename",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_Leaf_Area_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    render_trait_qc_pdf(
      sel_domain_filter = "Leaf Area",
      path_output_dir = dir_output,
      path_docs_dir = dir_docs,
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
  "render_trait_qc_pdf() names file correctly for simple domain",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_SLA_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    render_trait_qc_pdf(
      sel_domain_filter = "SLA",
      path_output_dir = dir_output,
      path_docs_dir = dir_docs,
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
  "render_trait_qc_pdf() moves file: absent source, present dest",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    source_path <-
      base::file.path(dir_docs, expected_name)

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines("pdf", source_path)
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    render_trait_qc_pdf(
      sel_domain_filter = NULL,
      path_output_dir = dir_output,
      path_docs_dir = dir_docs,
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
  "render_trait_qc_pdf() calls pdf_compress() in-place",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    compress_calls <-
      base::list()

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        compress_calls[[base::length(compress_calls) + 1L]] <<-
          base::list(input = input, output = output)
        invisible(NULL)
      },
      .package = "qpdf"
    )

    render_trait_qc_pdf(
      sel_domain_filter = NULL,
      path_output_dir = dir_output,
      path_docs_dir = dir_docs,
      verbose = FALSE
    )

    expected_dest <-
      base::file.path(dir_output, expected_name)

    testthat::expect_length(compress_calls, 1L)

    testthat::expect_true(
      compress_calls[[1L]][["input"]] == expected_dest
    )

    testthat::expect_true(
      compress_calls[[1L]][["output"]] == expected_dest
    )
  }
)

# --- Missing rendered file: warning emitted ---

testthat::test_that(
  "render_trait_qc_pdf() warns when rendered file not found",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    testthat::expect_warning(
      render_trait_qc_pdf(
        sel_domain_filter = NULL,
        path_output_dir = dir_output,
        path_docs_dir = dir_docs,
        verbose = TRUE
      )
    )
  }
)

# --- verbose = FALSE suppresses message ---

testthat::test_that(
  "render_trait_qc_pdf() emits no message when verbose FALSE",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    testthat::expect_no_message(
      render_trait_qc_pdf(
        sel_domain_filter = NULL,
        path_output_dir = dir_output,
        path_docs_dir = dir_docs,
        verbose = FALSE
      )
    )
  }
)

# --- verbose = TRUE emits a message on success ---

testthat::test_that(
  "render_trait_qc_pdf() emits a message when verbose TRUE",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    testthat::expect_message(
      render_trait_qc_pdf(
        sel_domain_filter = NULL,
        path_output_dir = dir_output,
        path_docs_dir = dir_docs,
        verbose = TRUE
      )
    )
  }
)

# --- Return value ---

testthat::test_that(
  "render_trait_qc_pdf() returns invisible NULL",
  {
    dir_docs <-
      withr::local_tempdir()

    dir_output <-
      withr::local_tempdir()

    expected_name <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )

    testthat::local_mocked_bindings(
      quarto_render = function(...) {
        base::writeLines(
          "pdf",
          base::file.path(dir_docs, expected_name)
        )
        invisible(NULL)
      },
      .package = "quarto"
    )

    testthat::local_mocked_bindings(
      pdf_compress = function(input, output, ...) {
        invisible(NULL)
      },
      .package = "qpdf"
    )

    result <-
      render_trait_qc_pdf(
        sel_domain_filter = NULL,
        path_output_dir = dir_output,
        path_docs_dir = dir_docs,
        verbose = FALSE
      )

    testthat::expect_null(result)
  }
)

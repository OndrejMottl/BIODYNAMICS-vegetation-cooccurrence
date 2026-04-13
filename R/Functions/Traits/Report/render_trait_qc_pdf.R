#' @title Render Trait QC Report to a Compressed PDF
#' @description
#' Renders `Trait_qc_report.qmd` to a dated PDF for a single trait
#' domain (or for all domains when `sel_domain_filter` is `NULL`),
#' moves the rendered file from the Quarto docs output directory to
#' `path_output_dir`, and compresses it in-place with
#' `qpdf::pdf_compress()`.
#'
#' The output filename follows one of two patterns depending on
#' `sel_domain_filter`:
#' - `NULL`: `trait_qc_report_{Sys.Date()}.pdf`
#' - character: `trait_qc_{<slug>}_{Sys.Date()}.pdf`
#'   where `<slug>` is `sel_domain_filter` with all non-alphanumeric
#'   characters replaced by underscores.
#' @param sel_domain_filter
#' Character scalar or `NULL`. When `NULL`, all domains are rendered
#' into a single PDF. When a character scalar, only taxa from that
#' trait domain are included. Default: `NULL`.
#' @param path_output_dir
#' Character scalar. Directory where the compressed PDF is saved.
#' Default: `here::here("Outputs/Reports")`.
#' @param path_qmd
#' Character scalar. Path to the Quarto source document.
#' Default: `here::here(
#'   "R/03_Supplementary_analyses/Trait_qc/Trait_qc_report.qmd"
#' )`.
#' @param path_docs_dir
#' Character scalar. Directory that Quarto writes its output to
#' before the file is moved. Default: `here::here(
#'   "docs/R/03_Supplementary_analyses/Trait_qc"
#' )`.
#' @param sel_max_pages
#' Positive integer scalar or `NULL`. Maximum number of pages to
#' render. When `NULL` (default) there is no cap.
#' @param sel_min_n_family
#' Positive integer scalar. Minimum number of taxa from the same
#' family that must be present for the family comparison panel to
#' be rendered. Default: `5L`.
#' @param verbose
#' Logical. If `TRUE` (default), a progress message with the output
#' path is printed to the console via `cli::cli_inform()`. A warning
#' is emitted via `cli::cli_warn()` if the rendered file cannot be
#' found.
#' @return
#' Invisible `NULL`. Called for its side effects: rendering and
#' moving a PDF to `path_output_dir`.
#' @details
#' The function calls `quarto::quarto_render()` with `execute_params`
#' set to `sel_max_pages`, `sel_min_n_family`, and
#' `sel_domain_filter`. The rendered file is expected at
#' `file.path(path_docs_dir, <output_filename>)`. If found it is
#' moved to `path_output_dir` and compressed; if not found a warning
#' is emitted and nothing is moved.
#' @seealso
#' [generate_trait_qc_report()]
#' @export
render_trait_qc_pdf <- function(
    sel_domain_filter = NULL,
    path_output_dir = here::here("Outputs/Reports"),
    path_qmd = here::here(
      "R/03_Supplementary_analyses/Trait_qc/Trait_qc_report.qmd"
    ),
    path_docs_dir = here::here(
      "docs/R/03_Supplementary_analyses/Trait_qc"
    ),
    sel_max_pages = NULL,
    sel_min_n_family = 5L,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.null(sel_domain_filter) ||
      (
        base::is.character(sel_domain_filter) &&
          base::length(sel_domain_filter) == 1L
      ),
    msg = stringr::str_glue(
      "'sel_domain_filter' must be NULL or a single character string."
    )
  )

  assertthat::assert_that(
    base::is.character(path_output_dir) &&
      base::length(path_output_dir) == 1L,
    msg = "'path_output_dir' must be a single character string."
  )

  assertthat::assert_that(
    base::is.null(sel_max_pages) ||
      (
        base::is.numeric(sel_max_pages) &&
          base::length(sel_max_pages) == 1L &&
          sel_max_pages > 0L
      ),
    msg = stringr::str_glue(
      "'sel_max_pages' must be NULL or a single positive number."
    )
  )

  assertthat::assert_that(
    base::is.numeric(sel_min_n_family) &&
      base::length(sel_min_n_family) == 1L &&
      sel_min_n_family > 0L,
    msg = stringr::str_glue(
      "'sel_min_n_family' must be a single positive number."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  if (
    base::is.null(sel_domain_filter)
  ) {
    sel_output_filename <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )
  } else {
    sel_domain_slug <-
      stringr::str_replace_all(
        sel_domain_filter,
        "[^a-zA-Z0-9]",
        "_"
      )
    sel_output_filename <-
      stringr::str_glue(
        "trait_qc_{sel_domain_slug}_{Sys.Date()}.pdf"
      )
  }

  path_output <-
    base::file.path(
      path_output_dir,
      sel_output_filename
    )

  quarto::quarto_render(
    input = path_qmd,
    execute_params = base::list(
      sel_max_pages = sel_max_pages,
      sel_min_n_family = sel_min_n_family,
      sel_domain_filter = sel_domain_filter
    ),
    output_file = base::as.character(sel_output_filename)
  )

  path_rendered <-
    base::file.path(
      path_docs_dir,
      sel_output_filename
    )

  if (
    base::file.exists(path_rendered)
  ) {
    path_compressed <-
      qpdf::pdf_compress(
        input = path_rendered
      )
    fs::file_move(
      path_compressed,
      path_output
    )
    if (base::file.exists(path_rendered)) {
      fs::file_delete(path_rendered)
    }
    if (
      isTRUE(verbose)
    ) {
      cli::cli_inform(
        "Written: {path_output}"
      )
    }
  } else {
    cli::cli_warn(
      "Output not found after render: {path_rendered}"
    )
  }

  return(invisible(NULL))
}

#' @title Render a Trait Quality-Control Report
#' @description
#' Renders `trait_quality_control_report.qmd` to a dated PDF for one trait
#' domain (or for all domains when `trait_domain_filter` is `NULL`),
#' moves the rendered file from the Quarto docs output directory to
#' `path_report_directory`, and compresses it in-place with
#' `qpdf::pdf_compress()`.
#'
#' The output filename follows one of two patterns depending on
#' `trait_domain_filter`:
#' - `NULL`: `trait_qc_report_{Sys.Date()}.pdf`
#' - character: `trait_qc_{<slug>}_{Sys.Date()}.pdf`
#'   where `<slug>` is `trait_domain_filter` with all non-alphanumeric
#'   characters replaced by underscores.
#' @param trait_domain_filter
#' Character scalar or `NULL`. When `NULL`, all domains are rendered
#' into a single PDF. When a character scalar, only taxa from that
#' trait domain are included. Default: `NULL`.
#' @param path_report_directory
#' Character scalar. Directory where the compressed PDF is saved.
#' Default: `here::here("Outputs/Reports")`.
#' @param path_report_source
#' Character scalar. Path to the Quarto source document.
#' Default: `here::here(
#'   "R", "03_Supplementary_analyses", "Diagnostics", "Data_processing",
#'   "Traits", "Quality_control", "trait_quality_control_report.qmd"
#' )`.
#' @param path_render_directory
#' Character scalar. Directory that Quarto writes its output to
#' before the file is moved. Default: `here::here(
#'   "docs", "R", "03_Supplementary_analyses", "Diagnostics",
#'   "Data_processing", "Traits", "Quality_control"
#' )`.
#' @param maximum_pages
#' Positive integer scalar or `NULL`. Maximum number of pages to
#' render. When `NULL` (default) there is no cap.
#' @param minimum_taxonomic_records
#' Positive integer scalar. Minimum records per taxon required for
#' inclusion in the taxonomic comparison panel. Default: `5L`.
#' @param verbose
#' Logical. If `TRUE` (default), a progress message with the output
#' path is printed to the console via `cli::cli_inform()`. A warning
#' is emitted via `cli::cli_warn()` if the rendered file cannot be
#' found.
#' @return
#' Invisible `NULL`. Called for its side effects: rendering and
#' moving a PDF to `path_report_directory`.
#' @details
#' The function calls `quarto::quarto_render()` with `execute_params`
#' set to `maximum_pages`, `minimum_taxonomic_records`, and
#' `trait_domain_filter`. The rendered file is expected at
#' `file.path(path_render_directory, <output_filename>)`. If found it is
#' moved to `path_report_directory` and compressed; if not found a warning
#' is emitted and nothing is moved.
#' @seealso
#' [write_trait_quality_control_report()]
#' @export
render_trait_quality_control_report <- function(
    trait_domain_filter = NULL,
    path_report_directory = here::here("Outputs/Reports"),
    path_report_source = here::here(
      "R",
      "03_Supplementary_analyses",
      "Diagnostics",
      "Data_processing",
      "Traits",
      "Quality_control",
      "trait_quality_control_report.qmd"
    ),
    path_render_directory = here::here(
      "docs",
      "R",
      "03_Supplementary_analyses",
      "Diagnostics",
      "Data_processing",
      "Traits",
      "Quality_control"
    ),
    maximum_pages = NULL,
    minimum_taxonomic_records = 5L,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.null(trait_domain_filter) ||
      (
        base::is.character(trait_domain_filter) &&
          base::length(trait_domain_filter) == 1L
      ),
    msg = stringr::str_glue(
      "'trait_domain_filter' must be NULL or a single character string."
    )
  )

  assertthat::assert_that(
    base::is.character(path_report_directory) &&
      base::length(path_report_directory) == 1L,
    msg = "'path_report_directory' must be a single character string."
  )

  assertthat::assert_that(
    base::is.null(maximum_pages) ||
      (
        base::is.numeric(maximum_pages) &&
          base::length(maximum_pages) == 1L &&
          maximum_pages > 0L
      ),
    msg = stringr::str_glue(
      "'maximum_pages' must be NULL or a single positive number."
    )
  )

  assertthat::assert_that(
    base::is.numeric(minimum_taxonomic_records) &&
      base::length(minimum_taxonomic_records) == 1L &&
      minimum_taxonomic_records > 0L,
    msg = stringr::str_glue(
      "'minimum_taxonomic_records' must be a single positive number."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  if (
    base::is.null(trait_domain_filter)
  ) {
    output_filename <-
      stringr::str_glue(
        "trait_qc_report_{Sys.Date()}.pdf"
      )
  } else {
    trait_domain_slug <-
      stringr::str_replace_all(
        trait_domain_filter,
        "[^a-zA-Z0-9]",
        "_"
      )
    output_filename <-
      stringr::str_glue(
        "trait_qc_{trait_domain_slug}_{Sys.Date()}.pdf"
      )
  }

  path_report <-
    base::file.path(
      path_report_directory,
      output_filename
    )

  quarto::quarto_render(
    input = path_report_source,
    execute_params = base::list(
      maximum_pages = maximum_pages,
      minimum_taxonomic_records = minimum_taxonomic_records,
      trait_domain_filter = trait_domain_filter
    ),
    output_file = base::as.character(output_filename)
  )

  path_rendered_report <-
    base::file.path(
      path_render_directory,
      output_filename
    )

  if (
    base::file.exists(path_rendered_report)
  ) {
    path_compressed_report <-
      qpdf::pdf_compress(
        input = path_rendered_report
      )
    fs::file_move(
      path_compressed_report,
      path_report
    )
    if (
      base::file.exists(path_rendered_report)
    ) {
      fs::file_delete(path_rendered_report)
    }
    if (
      base::isTRUE(verbose)
    ) {
      cli::cli_inform(
        "Written: {path_report}"
      )
    }
  } else {
    cli::cli_warn(
      "Output not found after render: {path_rendered_report}"
    )
  }

  return(base::invisible(NULL))
}

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Render Trait Quality-Control Reports
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Renders the trait quality-control review document to dated PDFs in
#   Outputs/Reports/.
#
# Mode "by_domain" (default): one PDF per trait domain.
# Mode "all_in_one":          one PDF containing all domains.
#
# Usage:
#   source(
#     paste0(
#       "R/03_Supplementary_analyses/Diagnostics/Data_processing/",
#       "Traits/Quality_control/render_trait_quality_control_reports.R"
#     )
#   )
#   The same file can be passed to `Rscript` from a shell.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Settings -----
#----------------------------------------------------------#

# "by_domain" : one PDF per trait domain (recommended)
# "all_in_one": single PDF containing all domains
report_mode <- "by_domain"

report_mode <-
  base::match.arg(
    report_mode,
    choices = base::c("by_domain", "all_in_one")
  )

# Cap pages per render (NULL = no cap)
maximum_pages <- NULL

# Minimum record count for the taxonomic comparison panel
minimum_taxonomic_records <- 5L


#----------------------------------------------------------#
# 2. Output directory -----
#----------------------------------------------------------#

path_report_directory <-
  here::here("Outputs/Reports")

fs::dir_create(
  path_report_directory,
  recurse = TRUE
)


#----------------------------------------------------------#
# 3. Locate QC report -----
#----------------------------------------------------------#

trait_quality_control_report_paths <-
  fs::dir_ls(
    here::here("Data/Temp"),
    regexp = "trait_qc_report_\\d{4}-\\d{2}-\\d{2}\\.csv$"
  )

if (
  base::length(trait_quality_control_report_paths) == 0L
) {
  cli::cli_abort(
    c(
      "No trait_qc_report_*.csv found in Data/Temp/.",
      "i" = "Run the traits pipeline to generate it."
    )
  )
}

path_trait_quality_control_report <-
  trait_quality_control_report_paths |>
  base::sort() |>
  utils::tail(1L)

trait_domains <-
  readr::read_csv(
    path_trait_quality_control_report,
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["n_suspected_outliers_taxon"]] > 0L) |>
  dplyr::pull(.data[["trait_domain_name"]]) |>
  base::unique() |>
  base::sort()


#----------------------------------------------------------#
# 4. Render -----
#----------------------------------------------------------#

if (
  report_mode == "by_domain"
) {
  render_trait_domain_report <- function(trait_domain) {
    render_trait_quality_control_report(
      trait_domain_filter = trait_domain,
      path_report_directory = path_report_directory,
      maximum_pages = maximum_pages,
      minimum_taxonomic_records = minimum_taxonomic_records
    )

    return(base::invisible(NULL))
  }

  purrr::walk(
    .progress = TRUE,
    .x = trait_domains,
    .f = render_trait_domain_report
  )

  cli::cli_inform(
    c(
      "v" = "Rendered {base::length(trait_domains)} domain PDF(s)",
      "i" = "Output directory: {path_report_directory}"
    )
  )
} else {
  render_trait_quality_control_report(
    trait_domain_filter = NULL,
    path_report_directory = path_report_directory,
    maximum_pages = maximum_pages,
    minimum_taxonomic_records = minimum_taxonomic_records
  )
}

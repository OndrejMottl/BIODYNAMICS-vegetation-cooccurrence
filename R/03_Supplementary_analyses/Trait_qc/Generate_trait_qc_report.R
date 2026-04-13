#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#             Generate Trait QC Review Report
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Renders R/03_Supplementary_analyses/Trait_qc/Trait_qc_report.qmd
#   to dated PDFs in Outputs/Reports/.
#
# Mode "by_domain" (default): one PDF per trait domain.
# Mode "all_in_one":          one PDF containing all domains.
#
# Usage:
#   source("R/03_Supplementary_analyses/Trait_qc/Generate_trait_qc_report.R")
#   or
#   Rscript R/03_Supplementary_analyses/Trait_qc/Generate_trait_qc_report.R


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
sel_mode <- "by_domain"

# Cap pages per render (NULL = no cap)
sel_max_pages <- NULL

# Minimum family count for the family comparison panel
sel_min_n_family <- 5L


#----------------------------------------------------------#
# 2. Output directory -----
#----------------------------------------------------------#

path_output_dir <-
  here::here("Outputs/Reports")

fs::dir_create(
  path_output_dir,
  recurse = TRUE
)


#----------------------------------------------------------#
# 3. Locate QC report -----
#----------------------------------------------------------#

vec_qc_report_paths <-
  fs::dir_ls(
    here::here("Data/Temp"),
    regexp = "trait_qc_report_\\d{4}-\\d{2}-\\d{2}\\.csv$"
  )

if (
  base::length(vec_qc_report_paths) == 0L
) {
  cli::cli_abort(
    c(
      "No trait_qc_report_*.csv found in Data/Temp/.",
      "i" = "Run the traits pipeline to generate it."
    )
  )
}

path_qc_report <-
  vec_qc_report_paths |>
  base::sort() |>
  utils::tail(1L)

data_qc_domains <-
  readr::read_csv(
    path_qc_report,
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
  sel_mode == "by_domain"
) {
  purrr::walk(
    .progress = TRUE,
    .x = data_qc_domains,
    .f = ~ render_trait_qc_pdf(
      sel_domain_filter = .x,
      path_output_dir = path_output_dir,
      sel_max_pages = sel_max_pages,
      sel_min_n_family = sel_min_n_family
    )
  )

  cli::cli_inform(
    c(
      "v" = "Rendered {base::length(data_qc_domains)} domain PDF(s)",
      "i" = "Output directory: {path_output_dir}"
    )
  )
} else {
  render_trait_qc_pdf(
    sel_domain_filter = NULL,
    path_output_dir = path_output_dir,
    sel_max_pages = sel_max_pages,
    sel_min_n_family = sel_min_n_family
  )
}

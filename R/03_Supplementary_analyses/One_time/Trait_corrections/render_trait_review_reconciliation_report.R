#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#       Render trait-review reconciliation report
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#

library(here)

path_report_source <-
  here::here(
    "R/03_Supplementary_analyses/One_time/Trait_corrections/",
    "trait_review_reconciliation_report.qmd"
  )
path_report_output_directory <-
  here::here("Outputs/Reports/Trait_corrections/raw")
path_report_render_source <-
  base::file.path(
    path_report_output_directory,
    "trait_review_reconciliation_report.qmd"
  )
path_report_cache_directory <-
  base::file.path(path_report_output_directory, ".quarto")
vec_report_formats <- base::c("html", "typst")
vec_report_files <-
  base::c(
    "trait_review_reconciliation_report.html",
    "trait_review_reconciliation_report.pdf"
  )

assertthat::assert_that(
  base::file.exists(path_report_source),
  msg = "The trait-review reconciliation report source is missing."
)
base::dir.create(
  path_report_output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)
flag_source_copied <-
  base::file.copy(
    from = path_report_source,
    to = path_report_render_source,
    overwrite = TRUE
  )
assertthat::assert_that(
  flag_source_copied,
  msg = "The report source could not be copied for rendering."
)

for (
  index_format in base::seq_along(vec_report_formats)
) {
  quarto::quarto_render(
    input = path_report_render_source,
    output_format = vec_report_formats[[index_format]],
    output_file = vec_report_files[[index_format]],
    execute_dir = here::here(),
    quiet = FALSE
  )
}

base::unlink(path_report_render_source, force = TRUE)
base::unlink(
  path_report_cache_directory,
  recursive = TRUE,
  force = TRUE
)

vec_report_paths <-
  base::file.path(
    path_report_output_directory,
    vec_report_files
  )
assertthat::assert_that(
  base::all(base::file.exists(vec_report_paths)),
  msg = "One or more trait-review report formats were not rendered."
)

base::message(
  "Rendered trait-review reconciliation reports to ",
  path_report_output_directory,
  "."
)

#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#       Render trait-review automation pilot report
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#

library(here)

path_report_source <-
  here::here(
    "R/03_Supplementary_analyses/One_time/Trait_corrections/",
    "trait_review_automation_pilot_report.qmd"
  )
path_output_directory <-
  here::here("Outputs/Reports/Trait_corrections/raw")
path_render_source <-
  base::file.path(
    path_output_directory,
    "trait_review_automation_pilot_report.qmd"
  )

assertthat::assert_that(
  base::file.exists(path_report_source),
  msg = "The trait-review automation pilot report source is missing."
)
base::dir.create(
  path_output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)
flag_source_copied <-
  base::file.copy(
    from = path_report_source,
    to = path_render_source,
    overwrite = TRUE
  )
assertthat::assert_that(
  flag_source_copied,
  msg = "The pilot report source could not be copied for rendering."
)

quarto::quarto_render(
  input = path_render_source,
  output_format = "html",
  output_file = "trait_review_automation_pilot_report.html",
  execute_dir = here::here(),
  quiet = FALSE
)

base::unlink(path_render_source, force = TRUE)

path_report <-
  base::file.path(
    path_output_directory,
    "trait_review_automation_pilot_report.html"
  )
assertthat::assert_that(
  base::file.exists(path_report),
  msg = "The trait-review automation pilot report was not rendered."
)

base::message("Rendered trait-review automation pilot report: ", path_report)

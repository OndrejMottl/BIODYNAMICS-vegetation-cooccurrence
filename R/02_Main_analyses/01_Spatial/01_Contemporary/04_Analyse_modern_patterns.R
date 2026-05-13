#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Analyse modern spatial patterns
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads modern spatial model ANOVA and evaluation targets from all
#   existing modern spatial stores and writes a dated summary table.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_output_tables <-
  here::here("Outputs/Tables")

base::dir.create(
  path = path_output_tables,
  showWarnings = FALSE,
  recursive = TRUE
)

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Read modern model results -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "modern"
  )

data_modern_results <-
  read_spatial_model_results(
    store_index = data_store_index,
    resolution_ids = c("genus", "family", "ft_modern", "ft_paleo"),
    require_non_empty = TRUE
  )


#----------------------------------------------------------#
# 2. Summarize and save -----
#----------------------------------------------------------#

data_modern_summary <-
  data_modern_results |>
  dplyr::group_by(
    .data$data_source,
    .data$scale,
    .data$resolution_id,
    .data$component
  ) |>
  dplyr::summarise(
    n_units = dplyr::n_distinct(.data$scale_id),
    R2_Nagelkerke_percentage_mean = base::mean(
      .data$R2_Nagelkerke_percentage,
      na.rm = TRUE
    ),
    R2_Nagelkerke_percentage_median = stats::median(
      .data$R2_Nagelkerke_percentage,
      na.rm = TRUE
    ),
    auc_mean = if (
      base::all(base::is.na(.data$auc_mean))
    ) {
      NA_real_
    } else {
      base::mean(.data$auc_mean, na.rm = TRUE)
    },
    auc_median = if (
      base::all(base::is.na(.data$auc_median))
    ) {
      NA_real_
    } else {
      stats::median(.data$auc_median, na.rm = TRUE)
    },
    auc_n = base::sum(.data$auc_n, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$resolution_id,
    .data$component
  )

if (
  base::nrow(data_modern_summary) == 0L
) {
  cli::cli_abort("Modern pattern summary is empty.")
}

file_output <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("modern_patterns_summary_{tag_date}.csv")
  )

readr::write_csv(
  x = data_modern_summary,
  file = file_output
)

base::message("Saved modern pattern summary: ", file_output)

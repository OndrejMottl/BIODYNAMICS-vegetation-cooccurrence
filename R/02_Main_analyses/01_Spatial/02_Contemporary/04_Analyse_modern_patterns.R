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
#   existing modern spatial stores and writes dated unit and summary
#   tables for downstream visualisation.


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
    resolution_ids = c("genus", "family", "ft_modern"),
    require_non_empty = TRUE
  ) |>
  dplyr::mutate(
    continent_id = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data/Input/spatial_grid.csv")
    )
  )


#----------------------------------------------------------#
# 2. Save unit table -----
#----------------------------------------------------------#

data_modern_unit <-
  data_modern_results |>
  dplyr::arrange(
    .data$data_source,
    .data$scale,
    .data$scale_id,
    .data$resolution_id,
    .data$component
  )

if (
  base::nrow(data_modern_unit) == 0L
) {
  cli::cli_abort("Modern pattern unit table is empty.")
}

file_modern_unit <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("modern_patterns_unit_{tag_date}.csv")
  )

readr::write_csv(
  x = data_modern_unit,
  file = file_modern_unit
)


#----------------------------------------------------------#
# 3. Summarize and save -----
#----------------------------------------------------------#

data_modern_summary <-
  data_modern_unit |>
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
    R2_Nagelkerke_percentage_lwr_95 = stats::quantile(
      .data$R2_Nagelkerke_percentage,
      probs = 0.025,
      na.rm = TRUE,
      names = FALSE
    ),
    R2_Nagelkerke_percentage_upr_95 = stats::quantile(
      .data$R2_Nagelkerke_percentage,
      probs = 0.975,
      na.rm = TRUE,
      names = FALSE
    ),
    auc_mean_mean = if (
      base::all(base::is.na(.data$auc_mean))
    ) {
      NA_real_
    } else {
      base::mean(.data$auc_mean, na.rm = TRUE)
    },
    auc_mean_median = if (
      base::all(base::is.na(.data$auc_mean))
    ) {
      NA_real_
    } else {
      stats::median(.data$auc_mean, na.rm = TRUE)
    },
    auc_mean_lwr_95 = if (
      base::all(base::is.na(.data$auc_mean))
    ) {
      NA_real_
    } else {
      stats::quantile(
        .data$auc_mean,
        probs = 0.025,
        na.rm = TRUE,
        names = FALSE
      )
    },
    auc_mean_upr_95 = if (
      base::all(base::is.na(.data$auc_mean))
    ) {
      NA_real_
    } else {
      stats::quantile(
        .data$auc_mean,
        probs = 0.975,
        na.rm = TRUE,
        names = FALSE
      )
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

file_modern_summary <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("modern_patterns_summary_{tag_date}.csv")
  )

readr::write_csv(
  x = data_modern_summary,
  file = file_modern_summary
)

base::message("Saved modern pattern unit table: ", file_modern_unit)
base::message("Saved modern pattern summary: ", file_modern_summary)

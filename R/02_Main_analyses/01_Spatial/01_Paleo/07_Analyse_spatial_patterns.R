#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               Analyse spatial patterns
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Loads ANOVA results from all paleo spatial units and combines
#   them into a single long tibble with a `taxonomic_scale`
#   column. The combined tibble is saved to Outputs/Data/ for
#   downstream use by 08_Plot_resolution_comparison.R, and dated
#   unit and summary tables are saved for modern-parity figures.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output_data <-
  here::here("Outputs/Data")

path_output_tables <-
  here::here("Outputs/Tables")

base::dir.create(
  path = path_output_data,
  showWarnings = FALSE,
  recursive = TRUE
)

base::dir.create(
  path = path_output_tables,
  showWarnings = FALSE,
  recursive = TRUE
)

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Load all results -----
#----------------------------------------------------------#

vec_taxonomic_resolutions <-
  c(
    "genus",
    "family",
    "functional_type"
  )

data_anova_results <-
  build_spatial_model_store_index(
    data_source = "paleo"
  ) |>
  read_spatial_model_results(
    resolution_ids = vec_taxonomic_resolutions,
    require_non_empty = TRUE
  ) |>
  dplyr::mutate(
    continent_id = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data/Input/spatial_grid.csv")
    ),
    scale = base::factor(
      scale,
      levels = c("local", "regional", "continental")
    ),
    taxonomic_scale = base::factor(
      resolution_id,
      levels = vec_taxonomic_resolutions,
      labels = c("Genus", "Family", "Functional type")
    )
  )

if (
  base::nrow(data_anova_results) == 0L
) {
  cli::cli_abort("Paleo spatial pattern unit table is empty.")
}


#----------------------------------------------------------#
# 2. Save combined ANOVA results -----
#----------------------------------------------------------#

RUtilpol::save_latest_file(
  object_to_save = data_anova_results,
  dir = path_output_data,
  prefered_format = "qs"
)


#----------------------------------------------------------#
# 3. Save unit table -----
#----------------------------------------------------------#

data_paleo_unit <-
  data_anova_results |>
  dplyr::arrange(
    .data$data_source,
    .data$scale,
    .data$scale_id,
    .data$resolution_id,
    .data$component
  )

file_paleo_unit <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_patterns_unit_{tag_date}.csv")
  )

readr::write_csv(
  x = data_paleo_unit,
  file = file_paleo_unit
)


#----------------------------------------------------------#
# 4. Summarize and save -----
#----------------------------------------------------------#

data_paleo_summary <-
  data_paleo_unit |>
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

file_paleo_summary <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_patterns_summary_{tag_date}.csv")
  )

readr::write_csv(
  x = data_paleo_summary,
  file = file_paleo_summary
)

base::message("Saved paleo pattern unit table: ", file_paleo_unit)
base::message("Saved paleo pattern summary: ", file_paleo_summary)

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Compare paleo and modern patterns
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares matched paleo and modern spatial stores for genus and
#   family resolutions, and compares modern FT groupings based on
#   modern vs paleo classifications.


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
# 1. Read model results -----
#----------------------------------------------------------#

data_modern_results <-
  build_spatial_model_store_index(
    data_source = "modern"
  ) |>
  read_spatial_model_results(
    resolution_ids = c("genus", "family", "ft_modern", "ft_paleo")
  )

data_paleo_results <-
  build_spatial_model_store_index(
    data_source = "paleo"
  ) |>
  read_spatial_model_results(
    resolution_ids = c("genus", "family")
  )

if (
  base::nrow(data_modern_results) == 0L ||
    base::nrow(data_paleo_results) == 0L
) {
  cli::cli_abort(
    "Cannot compare paleo and modern results because at least one result set is empty."
  )
}


#----------------------------------------------------------#
# 2. Paleo vs modern comparison -----
#----------------------------------------------------------#

data_paleo_modern_unit <-
  data_paleo_results |>
  dplyr::filter(
    .data$resolution_id %in% c("genus", "family")
  ) |>
  dplyr::select(
    .data$scale,
    .data$scale_id,
    .data$resolution_id,
    .data$component,
    R2_Nagelkerke_percentage_paleo = .data$R2_Nagelkerke_percentage,
    auc_mean_paleo = .data$auc_mean
  ) |>
  dplyr::inner_join(
    y = data_modern_results |>
      dplyr::filter(
        .data$resolution_id %in% c("genus", "family")
      ) |>
      dplyr::select(
        .data$scale,
        .data$scale_id,
        .data$resolution_id,
        .data$component,
        R2_Nagelkerke_percentage_modern = .data$R2_Nagelkerke_percentage,
        auc_mean_modern = .data$auc_mean
      ),
    by = c("scale", "scale_id", "resolution_id", "component")
  ) |>
  dplyr::mutate(
    R2_Nagelkerke_percentage_delta_modern_minus_paleo =
      .data$R2_Nagelkerke_percentage_modern -
        .data$R2_Nagelkerke_percentage_paleo,
    auc_mean_delta_modern_minus_paleo =
      .data$auc_mean_modern - .data$auc_mean_paleo
  )

if (
  base::nrow(data_paleo_modern_unit) == 0L
) {
  cli::cli_abort("No matched paleo-modern genus/family results were found.")
}

data_paleo_modern_summary <-
  data_paleo_modern_unit |>
  dplyr::group_by(
    .data$scale,
    .data$resolution_id,
    .data$component
  ) |>
  dplyr::summarise(
    n_units = dplyr::n_distinct(.data$scale_id),
    R2_paleo_mean = base::mean(
      .data$R2_Nagelkerke_percentage_paleo,
      na.rm = TRUE
    ),
    R2_modern_mean = base::mean(
      .data$R2_Nagelkerke_percentage_modern,
      na.rm = TRUE
    ),
    R2_delta_modern_minus_paleo_mean = base::mean(
      .data$R2_Nagelkerke_percentage_delta_modern_minus_paleo,
      na.rm = TRUE
    ),
    R2_delta_modern_minus_paleo_median = stats::median(
      .data$R2_Nagelkerke_percentage_delta_modern_minus_paleo,
      na.rm = TRUE
    ),
    auc_delta_modern_minus_paleo_mean = if (
      base::all(base::is.na(.data$auc_mean_delta_modern_minus_paleo))
    ) {
      NA_real_
    } else {
      base::mean(
        .data$auc_mean_delta_modern_minus_paleo,
        na.rm = TRUE
      )
    },
    .groups = "drop"
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$resolution_id,
    .data$component
  )

file_paleo_modern <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_modern_patterns_comparison_{tag_date}.csv")
  )

readr::write_csv(
  x = data_paleo_modern_summary,
  file = file_paleo_modern
)


#----------------------------------------------------------#
# 3. Modern FT grouping comparison -----
#----------------------------------------------------------#

data_ft_unit <-
  data_modern_results |>
  dplyr::filter(
    .data$resolution_id %in% c("ft_modern", "ft_paleo")
  ) |>
  dplyr::select(
    .data$scale,
    .data$scale_id,
    .data$resolution_id,
    .data$component,
    .data$R2_Nagelkerke_percentage,
    .data$auc_mean
  ) |>
  tidyr::pivot_wider(
    names_from = "resolution_id",
    values_from = c(
      "R2_Nagelkerke_percentage",
      "auc_mean"
    )
  ) |>
  tidyr::drop_na(
    "R2_Nagelkerke_percentage_ft_modern",
    "R2_Nagelkerke_percentage_ft_paleo"
  ) |>
  dplyr::mutate(
    R2_delta_ft_modern_minus_ft_paleo =
      .data$R2_Nagelkerke_percentage_ft_modern -
        .data$R2_Nagelkerke_percentage_ft_paleo,
    auc_delta_ft_modern_minus_ft_paleo =
      .data$auc_mean_ft_modern - .data$auc_mean_ft_paleo
  )

if (
  base::nrow(data_ft_unit) == 0L
) {
  cli::cli_abort("No matched modern FT modern-vs-paleo results were found.")
}

data_ft_summary <-
  data_ft_unit |>
  dplyr::group_by(
    .data$scale,
    .data$component
  ) |>
  dplyr::summarise(
    n_units = dplyr::n_distinct(.data$scale_id),
    R2_ft_modern_mean = base::mean(
      .data$R2_Nagelkerke_percentage_ft_modern,
      na.rm = TRUE
    ),
    R2_ft_paleo_mean = base::mean(
      .data$R2_Nagelkerke_percentage_ft_paleo,
      na.rm = TRUE
    ),
    R2_delta_ft_modern_minus_ft_paleo_mean = base::mean(
      .data$R2_delta_ft_modern_minus_ft_paleo,
      na.rm = TRUE
    ),
    R2_delta_ft_modern_minus_ft_paleo_median = stats::median(
      .data$R2_delta_ft_modern_minus_ft_paleo,
      na.rm = TRUE
    ),
    auc_delta_ft_modern_minus_ft_paleo_mean = if (
      base::all(base::is.na(.data$auc_delta_ft_modern_minus_ft_paleo))
    ) {
      NA_real_
    } else {
      base::mean(
        .data$auc_delta_ft_modern_minus_ft_paleo,
        na.rm = TRUE
      )
    },
    .groups = "drop"
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$component
  )

file_ft <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("modern_ft_grouping_comparison_{tag_date}.csv")
  )

readr::write_csv(
  x = data_ft_summary,
  file = file_ft
)

base::message("Saved paleo-modern comparison: ", file_paleo_modern)
base::message("Saved modern FT grouping comparison: ", file_ft)

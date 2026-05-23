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
# Compares matched paleo and modern spatial stores for genus,
#   family, and functional-type outputs. The functional-type
#   comparison uses modern `ft_modern` against paleo
#   `functional_type`; modern `ft_paleo` is not part of the
#   current modern spatial pipeline.


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
    resolution_ids = c("genus", "family", "ft_modern"),
    require_non_empty = TRUE
  )

data_paleo_results <-
  build_spatial_model_store_index(
    data_source = "paleo"
  ) |>
  read_spatial_model_results(
    resolution_ids = c("genus", "family", "functional_type"),
    require_non_empty = TRUE
  )


#----------------------------------------------------------#
# 2. Standardise resolution labels -----
#----------------------------------------------------------#

data_modern_compare <-
  data_modern_results |>
  dplyr::mutate(
    comparison_id = dplyr::case_when(
      .data$resolution_id == "genus" ~ "genus",
      .data$resolution_id == "family" ~ "family",
      .data$resolution_id == "ft_modern" ~ "functional_type",
      .default = NA_character_
    ),
    comparison_resolution = dplyr::case_when(
      .data$comparison_id == "genus" ~ "Genus",
      .data$comparison_id == "family" ~ "Family",
      .data$comparison_id == "functional_type" ~ "Functional type",
      .default = NA_character_
    )
  ) |>
  dplyr::filter(
    !base::is.na(.data$comparison_id)
  ) |>
  dplyr::select(
    scale,
    scale_id,
    comparison_id,
    comparison_resolution,
    resolution_id_modern = resolution_id,
    component,
    R2_Nagelkerke_percentage_modern = R2_Nagelkerke_percentage,
    auc_mean_modern = auc_mean
  )

data_paleo_compare <-
  data_paleo_results |>
  dplyr::mutate(
    comparison_id = dplyr::case_when(
      .data$resolution_id == "genus" ~ "genus",
      .data$resolution_id == "family" ~ "family",
      .data$resolution_id == "functional_type" ~ "functional_type",
      .default = NA_character_
    ),
    comparison_resolution = dplyr::case_when(
      .data$comparison_id == "genus" ~ "Genus",
      .data$comparison_id == "family" ~ "Family",
      .data$comparison_id == "functional_type" ~ "Functional type",
      .default = NA_character_
    )
  ) |>
  dplyr::filter(
    !base::is.na(.data$comparison_id)
  ) |>
  dplyr::select(
    scale,
    scale_id,
    comparison_id,
    comparison_resolution,
    resolution_id_paleo = resolution_id,
    component,
    R2_Nagelkerke_percentage_paleo = R2_Nagelkerke_percentage,
    auc_mean_paleo = auc_mean
  )


#----------------------------------------------------------#
# 3. Paleo vs modern comparison -----
#----------------------------------------------------------#

data_paleo_modern_unit <-
  data_paleo_compare |>
  dplyr::inner_join(
    y = data_modern_compare,
    by = dplyr::join_by(
      scale,
      scale_id,
      comparison_id,
      comparison_resolution,
      component
    ),
    multiple = "error"
  ) |>
  dplyr::mutate(
    R2_delta_modern_minus_paleo =
      .data$R2_Nagelkerke_percentage_modern -
        .data$R2_Nagelkerke_percentage_paleo,
    auc_delta_modern_minus_paleo =
      .data$auc_mean_modern - .data$auc_mean_paleo
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$scale_id,
    .data$comparison_id,
    .data$component
  )

if (
  base::nrow(data_paleo_modern_unit) == 0L
) {
  cli::cli_abort("No matched paleo-modern spatial results were found.")
}

data_paleo_modern_summary <-
  data_paleo_modern_unit |>
  dplyr::group_by(
    .data$scale,
    .data$comparison_id,
    .data$comparison_resolution,
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
      .data$R2_delta_modern_minus_paleo,
      na.rm = TRUE
    ),
    R2_delta_modern_minus_paleo_median = stats::median(
      .data$R2_delta_modern_minus_paleo,
      na.rm = TRUE
    ),
    R2_delta_modern_minus_paleo_lwr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.025,
      na.rm = TRUE,
      names = FALSE
    ),
    R2_delta_modern_minus_paleo_upr_95 = stats::quantile(
      .data$R2_delta_modern_minus_paleo,
      probs = 0.975,
      na.rm = TRUE,
      names = FALSE
    ),
    auc_delta_modern_minus_paleo_mean = if (
      base::all(base::is.na(.data$auc_delta_modern_minus_paleo))
    ) {
      NA_real_
    } else {
      base::mean(
        .data$auc_delta_modern_minus_paleo,
        na.rm = TRUE
      )
    },
    auc_delta_modern_minus_paleo_median = if (
      base::all(base::is.na(.data$auc_delta_modern_minus_paleo))
    ) {
      NA_real_
    } else {
      stats::median(
        .data$auc_delta_modern_minus_paleo,
        na.rm = TRUE
      )
    },
    .groups = "drop"
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$comparison_id,
    .data$component
  )

file_paleo_modern_unit <-
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_modern_patterns_comparison_unit_{tag_date}.csv"
    )
  )

file_paleo_modern_summary <-
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "paleo_modern_patterns_comparison_summary_{tag_date}.csv"
    )
  )

file_paleo_modern_legacy <-
  base::file.path(
    path_output_tables,
    stringr::str_glue("paleo_modern_patterns_comparison_{tag_date}.csv")
  )

readr::write_csv(
  x = data_paleo_modern_unit,
  file = file_paleo_modern_unit
)

readr::write_csv(
  x = data_paleo_modern_summary,
  file = file_paleo_modern_summary
)

readr::write_csv(
  x = data_paleo_modern_summary,
  file = file_paleo_modern_legacy
)

base::message(
  "Saved paleo-modern comparison unit table: ",
  file_paleo_modern_unit
)
base::message(
  "Saved paleo-modern comparison summary: ",
  file_paleo_modern_summary
)

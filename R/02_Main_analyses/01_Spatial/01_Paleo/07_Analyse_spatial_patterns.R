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
# Loads ANOVA results from all spatial units and combines
#   them into a single long tibble with a
#   `taxonomic_resolution` column (genus / family /
#   functional type). The combined tibble is saved to
#   Outputs/Data/ for downstream use by
#   08_Plot_resolution_comparison.R.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output_data <-
  here::here("Outputs/Data")

base::dir.create(
  path = path_output_data,
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
    resolution_ids = vec_taxonomic_resolutions
  ) |>
  dplyr::left_join(
    readr::read_csv(
      here::here("Data/Input/spatial_grid.csv"),
      show_col_types = FALSE
    ) |>
      dplyr::select(
        scale_id,
        continent_id
      ),
    by = dplyr::join_by(scale_id),
    multiple = "error"
  ) |>
  dplyr::mutate(
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


#----------------------------------------------------------#
# 2. Save combined ANOVA results -----
#----------------------------------------------------------#

RUtilpol::save_latest_file(
  object_to_save = data_anova_results,
  dir = path_output_data,
  prefered_format = "qs"
)

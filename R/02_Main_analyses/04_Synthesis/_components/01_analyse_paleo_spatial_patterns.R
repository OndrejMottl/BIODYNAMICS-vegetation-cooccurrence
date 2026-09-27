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
#   downstream use by the stage 05 manuscript figures. Dated unit and summary
#   tables support modern-parity figures and the functional-type ordination.
# Workflow contract:
#   Run after the paleo continental, regional, and local runners complete in
#   normal mode. This script reads stores but never updates target metadata.
#   Available results are combined and an entirely empty result is fatal;
#   completeness across expected units must be checked before publication.
#   Writes a latest QS object plus dated unit and summary CSV tables.

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
  load_spatial_model_results(
    resolution_ids = vec_taxonomic_resolutions,
    require_non_empty = TRUE
  ) |>
  dplyr::mutate(
    continent_id = resolve_continent_ids_from_scale_ids(
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
    dplyr::across(
      dplyr::all_of(
        c(
          "R2_Nagelkerke_percentage",
          "fitted_auc_mean",
          "predictive_tjur_r2_mean",
          "predictive_auc_mean",
          "predictive_log_loss_mean"
        )
      ),
      .fns = list(
        mean = ~ if (base::all(base::is.na(.x))) {
          NA_real_
        } else {
          base::mean(.x, na.rm = TRUE)
        },
        median = ~ if (base::all(base::is.na(.x))) {
          NA_real_
        } else {
          stats::median(.x, na.rm = TRUE)
        },
        lwr_95 = ~ if (base::all(base::is.na(.x))) {
          NA_real_
        } else {
          stats::quantile(
            .x,
            probs = 0.025,
            na.rm = TRUE,
            names = FALSE
          )
        },
        upr_95 = ~ if (base::all(base::is.na(.x))) {
          NA_real_
        } else {
          stats::quantile(
            .x,
            probs = 0.975,
            na.rm = TRUE,
            names = FALSE
          )
        }
      ),
      .names = "{.col}_{.fn}"
    ),
    fitted_auc_n = base::sum(.data$fitted_auc_n, na.rm = TRUE),
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


#----------------------------------------------------------#
# 5. Synthesize functional-type ordination -----
#----------------------------------------------------------#

store_functional_type <-
  build_spatial_model_store_index(
    data_source = "paleo"
  ) |>
  dplyr::filter(
    .data$scale == "continental",
    .data$scale_id == "europe",
    .data$store_exists
  ) |>
  dplyr::pull(.data$store_path)

if (
  base::length(store_functional_type) != 1L
) {
  cli::cli_abort(
    "Functional-type ordination requires one Europe continental store."
  )
}

data_functional_type_dissimilarity <-
  targets::tar_read_raw(
    name = "data_functional_type_dissimilarity_continental",
    store = store_functional_type
  )
data_functional_type_classification <-
  targets::tar_read_raw(
    name = "data_functional_type_classification_continental",
    store = store_functional_type
  ) |>
  dplyr::mutate(
    functional_type = base::as.integer(.data$functional_type)
  )

data_functional_type_counts <-
  data_functional_type_classification |>
  dplyr::count(
    .data$functional_type,
    name = "n_taxa"
  ) |>
  dplyr::filter(.data$n_taxa > 1L)

vec_functional_type_taxa <-
  data_functional_type_classification |>
  dplyr::semi_join(
    data_functional_type_counts,
    by = dplyr::join_by(functional_type)
  ) |>
  dplyr::pull(.data$taxon_name)

data_functional_type_dissimilarity_filtered <-
  data_functional_type_dissimilarity |>
  base::as.matrix() |>
  magrittr::extract(
    vec_functional_type_taxa,
    vec_functional_type_taxa
  ) |>
  stats::as.dist()

base::set.seed(900723)
mod_functional_type_nmds <-
  vegan::metaMDS(
    comm = data_functional_type_dissimilarity_filtered,
    k = 2L,
    try = 30L,
    trymax = 120L,
    autotransform = FALSE,
    trace = FALSE,
    pc = TRUE
  )

mat_functional_type_scores <-
  vegan::scores(
    x = mod_functional_type_nmds,
    display = "sites"
  )

data_functional_type_ordination <-
  mat_functional_type_scores |>
  tibble::as_tibble(
    .name_repair = ~ base::c("nmds_1", "nmds_2")
  ) |>
  dplyr::mutate(
    taxon_name = base::rownames(mat_functional_type_scores),
    nmds_stress = mod_functional_type_nmds[["stress"]],
    continent_id = "europe",
    scale = "continental",
    scale_id = "europe",
    resolution_id = "functional_type",
    availability_status = "available",
    n_models = 1L,
    .before = 1L
  ) |>
  dplyr::inner_join(
    data_functional_type_classification,
    by = dplyr::join_by(taxon_name),
    multiple = "error"
  ) |>
  dplyr::semi_join(
    data_functional_type_counts,
    by = dplyr::join_by(functional_type)
  )

data_functional_type_ordination_summary <-
  data_functional_type_ordination |>
  dplyr::group_by(
    .data$continent_id,
    .data$scale,
    .data$scale_id,
    .data$resolution_id,
    .data$availability_status,
    .data$functional_type
  ) |>
  dplyr::summarise(
    nmds_1 = stats::median(.data$nmds_1),
    nmds_2 = stats::median(.data$nmds_2),
    n_taxa = dplyr::n(),
    n_models = dplyr::first(.data$n_models),
    nmds_stress = dplyr::first(.data$nmds_stress),
    .groups = "drop"
  )

file_functional_type_ordination <-
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "functional_type_ordination_unit_{tag_date}.csv"
    )
  )
file_functional_type_ordination_summary <-
  base::file.path(
    path_output_tables,
    stringr::str_glue(
      "functional_type_ordination_summary_{tag_date}.csv"
    )
  )

readr::write_csv(
  data_functional_type_ordination,
  file_functional_type_ordination
)
readr::write_csv(
  data_functional_type_ordination_summary,
  file_functional_type_ordination_summary
)

base::message("Saved paleo pattern unit table: ", file_paleo_unit)
base::message("Saved paleo pattern summary: ", file_paleo_summary)
base::message(
  "Saved functional-type ordination: ",
  file_functional_type_ordination
)

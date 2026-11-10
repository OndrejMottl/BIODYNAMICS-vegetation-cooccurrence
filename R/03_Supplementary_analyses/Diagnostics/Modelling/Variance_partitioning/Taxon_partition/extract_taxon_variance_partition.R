#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Extract per-taxon variance partition
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads every stored variance-partition object and writes the
#   model-level and per-taxon fractions to two tables.
# Read-only on the target stores; no model is refitted.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

path_output <-
  here::here("Outputs/Tables/Diagnostics/Taxon_variance_partition")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

path_unit_tables <-
  here::here("Outputs/Tables/Visualisation")

# Unique, shared, and full fractions kept for every taxon
vec_fractions <-
  c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS", "Full")

vec_temporal_continents <-
  c("europe", "america", "asia")


#----------------------------------------------------------#
# 1. Helpers -----
#----------------------------------------------------------#

# The newest published unit table of one data source
resolve_unit_table_path <- function(data_source_name) {
  res <-
    base::list.files(
      path = path_unit_tables,
      pattern = stringr::str_glue(
        "^{data_source_name}_variance_partitioning_unit_.*[.]csv$"
      ),
      full.names = TRUE
    ) |>
    base::sort() |>
    utils::tail(n = 1)

  return(res)
}

load_spatial_work_list <- function(data_source_name) {
  res <-
    resolve_unit_table_path(data_source_name = data_source_name) |>
    readr::read_csv(show_col_types = FALSE) |>
    dplyr::filter(
      .data[["component"]] == "Associations",
      .data[["data_source"]] == data_source_name
    ) |>
    dplyr::mutate(
      # The published path is machine specific; keep the part
      #    below the repository root
      store_path = stringr::str_extract(
        string = .data[["store_path"]],
        pattern = "Data/targets/.*$"
      ),
      target_name = stringr::str_glue(
        "list_jsdm_variance_partition_{resolution_id}"
      ) |>
        base::as.character(),
      age = NA_real_
    ) |>
    dplyr::select(
      "data_source", "scale", "scale_id", "continent_id",
      "resolution_id", "age", "store_path", "target_name"
    )

  return(res)
}

load_temporal_work_list <- function(continent_name) {
  store_path_relative <-
    stringr::str_glue(
      "Data/targets/paleo_temporal_{continent_name}/",
      "pipeline_paleo_temporal"
    ) |>
    base::as.character()

  res <-
    targets::tar_meta(
      store = here::here(store_path_relative),
      fields = c("name", "error")
    ) |>
    dplyr::filter(
      stringr::str_detect(
        string = .data[["name"]],
        pattern = "^model_anova_timeslice_[0-9]+$"
      ),
      base::is.na(.data[["error"]])
    ) |>
    dplyr::mutate(
      data_source = "paleo",
      scale = "temporal",
      scale_id = stringr::str_glue(
        "{continent_name}_{.data[['name']]}"
      ) |>
        base::as.character(),
      continent_id = continent_name,
      resolution_id = "genus",
      age = stringr::str_extract(
        string = .data[["name"]],
        pattern = "[0-9]+$"
      ) |>
        base::as.numeric(),
      store_path = store_path_relative,
      target_name = .data[["name"]]
    ) |>
    dplyr::select(
      "data_source", "scale", "scale_id", "continent_id",
      "resolution_id", "age", "store_path", "target_name"
    )

  return(res)
}

# Model-level and per-taxon fractions of one stored object
extract_partition_tables <- function(store_path, target_name) {
  list_anova <-
    targets::tar_read_raw(
      name = target_name,
      store = here::here(store_path)
    )

  n_samples <-
    purrr::chuck(list_anova, "N")

  data_model <-
    list_anova |>
    purrr::chuck("results") |>
    tibble::as_tibble() |>
    dplyr::filter(.data[["models"]] %in% vec_fractions) |>
    dplyr::select(
      fraction = "models",
      deviance = "Deviance",
      r2_nagelkerke = "R2 Nagelkerke",
      r2_mcfadden = "R2 McFadden"
    ) |>
    dplyr::mutate(n_samples = n_samples)

  # Site-by-taxon log-likelihoods of every fraction
  list_log_likelihood <-
    purrr::chuck(list_anova, "lls", 1)

  vec_null_log_likelihood <-
    list_log_likelihood |>
    purrr::chuck("Null") |>
    base::colSums()

  data_taxa <-
    vec_fractions |>
    purrr::map(
      .f = function(fraction_name) {
        vec_nagelkerke <-
          purrr::chuck(
            list_anova, "species", "R2_Nagelkerke", fraction_name
          )

        vec_mcfadden <-
          purrr::chuck(
            list_anova, "species", "R2_McFadden", fraction_name
          )

        # Taken from the log-likelihoods because the per-taxon
        #    Nagelkerke R2 can round to exactly one
        vec_deviance <-
          2 * (
            list_log_likelihood |>
              purrr::chuck(fraction_name) |>
              base::colSums() -
              vec_null_log_likelihood
          )

        tibble::tibble(
          taxon = base::names(vec_nagelkerke),
          fraction = fraction_name,
          deviance = base::unname(vec_deviance),
          r2_nagelkerke = base::unname(vec_nagelkerke),
          r2_mcfadden = base::unname(vec_mcfadden)
        )
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      n_samples = n_samples,
      n_taxa = dplyr::n_distinct(.data[["taxon"]])
    )

  res <-
    base::list(
      model = data_model |>
        dplyr::mutate(
          n_taxa = dplyr::n_distinct(data_taxa[["taxon"]])
        ),
      taxa = data_taxa
    )

  return(res)
}


#----------------------------------------------------------#
# 2. Work list -----
#----------------------------------------------------------#

data_work <-
  dplyr::bind_rows(
    load_spatial_work_list(data_source_name = "paleo"),
    load_spatial_work_list(data_source_name = "modern"),
    vec_temporal_continents |>
      purrr::map(.f = load_temporal_work_list) |>
      purrr::list_rbind()
  )

base::message(
  stringr::str_glue("Stored models to read: {base::nrow(data_work)}")
)


#----------------------------------------------------------#
# 3. Extraction -----
#----------------------------------------------------------#

list_extracted <-
  base::seq_len(base::nrow(data_work)) |>
  purrr::map(
    .progress = TRUE,
    .f = function(index_row) {
      data_row <-
        dplyr::slice(data_work, index_row)

      list_tables <-
        base::tryCatch(
          expr = extract_partition_tables(
            store_path = data_row[["store_path"]],
            target_name = data_row[["target_name"]]
          ),
          error = function(e) {
            base::message(
              stringr::str_glue(
                "FAILED {data_row[['scale_id']]} ",
                "{data_row[['target_name']]}: ",
                "{base::conditionMessage(e)}"
              )
            )
            NULL
          }
        )

      # The stored objects hold the fitted model; release it
      #    before the next one is read
      base::gc(verbose = FALSE)

      if (
        base::is.null(list_tables)
      ) {
        return(NULL)
      }

      data_id <-
        dplyr::select(data_row, -"store_path", -"target_name")

      base::list(
        model = dplyr::bind_cols(
          data_id,
          purrr::chuck(list_tables, "model")
        ),
        taxa = dplyr::bind_cols(
          data_id,
          purrr::chuck(list_tables, "taxa")
        )
      )
    }
  ) |>
  purrr::compact()

data_model_partition <-
  list_extracted |>
  purrr::map(.f = ~ purrr::chuck(.x, "model")) |>
  purrr::list_rbind()

data_taxon_partition <-
  list_extracted |>
  purrr::map(.f = ~ purrr::chuck(.x, "taxa")) |>
  purrr::list_rbind()


#----------------------------------------------------------#
# 4. Outputs -----
#----------------------------------------------------------#

date_label <-
  base::format(base::Sys.Date(), "%Y-%m-%d")

readr::write_csv(
  x = data_model_partition,
  file = base::file.path(
    path_output,
    stringr::str_glue("model_variance_partition_{date_label}.csv")
  )
)

readr::write_csv(
  x = data_taxon_partition,
  file = base::file.path(
    path_output,
    stringr::str_glue("taxon_variance_partition_{date_label}.csv")
  )
)


#----------------------------------------------------------#
# 5. Checks -----
#----------------------------------------------------------#

base::message(
  stringr::str_glue(
    "Models extracted: {base::length(list_extracted)} of ",
    "{base::nrow(data_work)}; taxon rows: ",
    "{base::nrow(data_taxon_partition)}"
  )
)

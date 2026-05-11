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

data_targets_meta <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    store_path = here::here(
      stringr::str_glue("Data/targets/paleo_spatial_{scale}"),
      scale_id,
      "pipeline_paleo_spatial_resolution"
    )
  ) |>
  dplyr::mutate(
    store_exists = fs::dir_exists(store_path),
    # Read pipeline metadata once per unit; NULL for non-existent stores.
    # complete_only = FALSE returns all known targets so that
    # successful targets (error = NA) can be distinguished from
    # errored ones (error = non-NA) and never-ran ones (absent).
    pipeline_meta = purrr::map2(
      .x = store_path,
      .y = store_exists,
      .f = ~ {
        if (
          base::isFALSE(.y)
        ) {
          return(NULL)
        }
        purrr::possibly(
          ~ targets::tar_meta(
            fields = c("name", "error"),
            complete_only = FALSE,
            store = .x
          ),
          otherwise = NULL
        )(.x)
      }
    )
  ) |>
  dplyr::mutate(
    # Per-resolution success: the key model target (model_jsdm_selected_<res>)
    # must appear in metadata with no recorded error.
    successful_genus = purrr::map_lgl(
      .x = pipeline_meta,
      .f = ~ {
        if (
          base::is.null(.x)
        ) {
          return(FALSE)
        }
        target_row <-
          dplyr::filter(.x, name == "model_jsdm_selected_genus")
        base::nrow(target_row) > 0L &&
          base::is.na(dplyr::pull(target_row, error))
      }
    ),
    successful_family = purrr::map_lgl(
      .x = pipeline_meta,
      .f = ~ {
        if (
          base::is.null(.x)
        ) {
          return(FALSE)
        }
        target_row <-
          dplyr::filter(.x, name == "model_jsdm_selected_family")
        base::nrow(target_row) > 0L &&
          base::is.na(dplyr::pull(target_row, error))
      }
    ),
    successful_functional_type = purrr::map_lgl(
      .x = pipeline_meta,
      .f = ~ {
        if (
          base::is.null(.x)
        ) {
          return(FALSE)
        }
        target_row <-
          dplyr::filter(.x, name == "model_jsdm_selected_functional_type")
        base::nrow(target_row) > 0L &&
          base::is.na(dplyr::pull(target_row, error))
      }
    )
  ) |>
  dplyr::select(-pipeline_meta)

data_targets_successful <-
  data_targets_meta |>
  dplyr::filter(store_exists)

vec_taxonomic_resolutions <-
  c(
    "genus",
    "family",
    "functional_type"
  )

data_anova_results <-
  data_targets_successful |>
  dplyr::mutate(
    vec_model_anova_targets = purrr::map(
      .x = store_path,
      .f = ~ targets::tar_meta(
        fields = c("name", "error"),
        complete_only = FALSE,
        store = .x
      ) |>
        dplyr::filter(base::is.na(error)) |>
        dplyr::pull(name) |>
        stringr::str_subset(
          pattern = "^model_anova_"
        ) |>
        base::intersect(
          y = stringr::str_glue(
            "model_anova_{vec_taxonomic_resolutions}"
          )
        )
    ),
    anova_results = purrr::map2(
      .x = store_path,
      .y = vec_model_anova_targets,
      .f = ~ {
        store_path_current <- .x
        vec_model_anova_targets_current <- .y

        if (
          base::length(vec_model_anova_targets_current) == 0L
        ) {
          return(
            tibble::tibble(
              taxonomic_scale = base::character(length = 0L),
              component = base::character(length = 0L),
              R2_Nagelkerke_percentage = base::numeric(length = 0L)
            )
          )
        }

        vec_model_anova_targets_current |>
          purrr::set_names(
            nm = stringr::str_remove(
              string = vec_model_anova_targets_current,
              pattern = "^model_anova_"
            )
          ) |>
          purrr::map(
            .f = ~ targets::tar_read_raw(
              name = .x,
              store = store_path_current
            )
          ) |>
          purrr::imap(
            .f = ~ {
              data_anova_components <-
                extract_anova_fractions(
                  anova_object = .x,
                  clamp_negative = TRUE
                ) |>
                dplyr::mutate(age = 0) |>
                recalculate_anova_components()

              data_anova_components |>
                dplyr::mutate(
                  taxonomic_scale = .y
                ) |>
                dplyr::select(
                  taxonomic_scale,
                  component,
                  R2_Nagelkerke_percentage
                )
            }
          ) |>
          purrr::list_rbind()
      }
    )
  ) |>
  dplyr::select(-vec_model_anova_targets) |>
  tidyr::unnest(anova_results) |>
  dplyr::mutate(
    scale = factor(
      scale,
      levels = c("local", "regional", "continental")
    ),
    taxonomic_scale = factor(
      taxonomic_scale,
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

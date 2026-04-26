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
# Loads results from all spatial units and analyses them together to
#   identify general patterns and differences across scales.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")

flag_run_all <- FALSE


#----------------------------------------------------------#
# 1. Run individual spatial analyses -----
#----------------------------------------------------------#

if (
  base::isTRUE(flag_run_all)
) {
  c(
    "continental",
    "regional",
    "local"
  ) |>
    rlang::set_names(
      nm = base::as.character(c(1:3))
    ) |>
    purrr::iwalk(
      .f = ~ here::here(
        "R/02_Main_analyses/01_Spatial/",
        stringr::str_glue("0{.y}_Run_spatial_{.x}.R")
      ) |>
        source()
    )
}


#----------------------------------------------------------#
# 2. Load all results -----
#----------------------------------------------------------#

data_targets_meta <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    store_path = here::here(
      stringr::str_glue("Data/targets/spatial_{scale}"),
      scale_id,
      "pipeline_spatial_resolution"
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
    # Per-resolution success: the key model target (mod_to_use_<res>)
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
          dplyr::filter(.x, name == "mod_to_use_genus")
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
          dplyr::filter(.x, name == "mod_to_use_family")
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
          dplyr::filter(.x, name == "mod_to_use_functional_type")
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
        dplyr::filter(is.na(error)) |>
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

data_anova_results |>
  dplyr::filter(component == "Associations") |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = scale,
      y = taxonomic_scale,
      fill = R2_Nagelkerke_percentage,
      col = R2_Nagelkerke_percentage,
      shape = continent_id
    )
  ) +
  ggplot2::scale_y_discrete(position = "right") +
  ggplot2::scale_shape_manual(
    values = c(
      "america" = 22,
      "asia" = 24,
      "europe" = 25
    ),
    name = "Continent"
  ) +
  ggplot2::scale_fill_viridis_c(
    limits = c(0, 100),
    na.value = "grey90",
    name = expression(R^2 ~ "Nagelkerke (%)")
  ) +
  ggplot2::scale_color_viridis_c(
    limits = c(0, 100),
    na.value = "grey90",
    name = expression(R^2 ~ "Nagelkerke (%)")
  ) +
  ggplot2::labs(
    x = "Spatial scale",
    y = "Taxonomic scale",
    title = "Variance explained by species associations across scales"
  ) +
  ggplot2::theme(
    legend.position = "top",
    # add one legend on top of the other to show fill and color together
    legend.box = "vertical",
  ) +
  ggview::canvas(
    height = graphical_options[["height"]],
    width = graphical_options[["width"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_jitter(
    width = 0.2,
    height = 0.2,
    size = 3,
    alpha = 0.8
  )

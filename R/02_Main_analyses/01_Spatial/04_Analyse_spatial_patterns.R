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

run_all <- FALSE


#----------------------------------------------------------#
# 1. Run individual spatial analyses -----
#----------------------------------------------------------#

if (
  isTRUE(run_all)
) {
  c(
    "continental",
    "regional",
    "local"
  ) |>
    rlang::set_names(
      nm = as.character(c(1:3))
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
      paste0("Data/targets/spatial_", scale),
      scale_id,
      "pipeline_basic"
    )
  ) |>
  dplyr::mutate(
    store_exists = fs::dir_exists(store_path),
    has_errors = purrr::map2_lgl(
      .x = store_path,
      .y = store_exists,
      .f = ~ {
        if (isFALSE(.y)) {
          return(NA)
        }
        targets::tar_meta(
          fields = c("name", "error"),
          complete_only = TRUE,
          store = .x
        ) %>%
          {
            nrow(.) > 0
          }
      }
    ),
    succesfull = store_exists & !has_errors
  )


data_targets_successful <-
  data_targets_meta |>
  dplyr::filter(succesfull)

data_anova_results <-
  data_targets_successful |>
  dplyr::mutate(
    selected_ab_predictors = purrr::map(
      .x = store_path,
      .f = ~ targets::tar_read(
        "abiotic_collinearity",
        store = .x
      ) |>
        purrr::chuck("result", "selection") |>
        as.character()
    ),
    model_anova = purrr::map(
      .x = store_path,
      .f = purrr::possibly(
        ~ targets::tar_read(
          "model_anova",
          store = .x
        ),
        otherwise = NA
      )
    )
  ) |>
  dplyr::filter(!is.na(model_anova)) |>
  dplyr::mutate(
    anova_results = purrr::map(
      .x = model_anova,
      .f = ~ extract_anova_fractions(
        anova_object = .x,
        clamp_negative = TRUE
      ) |>
        dplyr::mutate(age = 0) |>
        recalculate_anova_components() |>
        dplyr::select(component, R2_Nagelkerke_percentage)
    )
  ) |>
  dplyr::select(-c(model_anova, selected_ab_predictors)) |>
  tidyr::unnest(anova_results)



data_anova_results |>
  dplyr::filter(component == "Associations") |>
  dplyr::mutate(
    scale = factor(
      scale,
      levels = c("local", "regional", "continental")
    )
  ) |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = scale,
      y = R2_Nagelkerke_percentage,
      group = scale
    )
  ) +
  # ggplot2::geom_violin() +
  ggplot2::geom_boxplot(
    width = 0.1,
    outlier.shape = NA
  ) +
  ggplot2::geom_point() +
  ggplot2::scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  ggplot2::coord_cartesian(
    ylim = c(0, 100)
  ) +
  ggview::canvas(
    height = get_active_config("graphical")$height,
    width = get_active_config("graphical")$width,
    units = get_active_config("graphical")$units,
    dpi = get_active_config("graphical")$dpi,
    bg = get_active_config("graphical")$bg
  )

#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Diagnose spatial pipeline results
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Aggregates pipeline status, errors, convergence, and model
#   evaluation metrics across all spatial units and scales.
# For a deep-dive into a single spatial unit, see:
#   R/03_Supplementary_analyses/Diagnose_spatial_pipeline_unit.R


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


#----------------------------------------------------------#
# 1. Load all pipeline metadata -----
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
        if (
          isFALSE(.y)
        ) {
          return(NA)
        }
        targets::tar_meta(
          fields = c("name", "error"),
          complete_only = TRUE,
          store = .x
        ) |>
          {
            \(d) nrow(d) > 0
          }()
      }
    ),
    succesfull = store_exists & !has_errors
  )

data_targets_successful <-
  data_targets_meta |>
  dplyr::filter(succesfull)

data_targets_failed <-
  data_targets_meta |>
  dplyr::filter(
    store_exists & !succesfull
  )


#----------------------------------------------------------#
# 2. Pipeline status overview -----
#----------------------------------------------------------#

data_status_overview <-
  data_targets_meta |>
  dplyr::mutate(
    status = dplyr::case_when(
      succesfull ~ "successful",
      store_exists & !succesfull ~ "failed",
      .default = "not_run"
    )
  ) |>
  dplyr::group_by(scale, status) |>
  dplyr::summarise(
    n = dplyr::n(),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = status,
    values_from = n,
    values_fill = 0L
  ) |>
  dplyr::mutate(
    total = dplyr::pick(
      dplyr::any_of(c("successful", "failed", "not_run"))
    ) |>
      rowSums()
  )

print(data_status_overview)


#----------------------------------------------------------#
# 3. Error analysis (failed units) -----
#----------------------------------------------------------#

data_errors_by_target <-
  data_targets_failed |>
  dplyr::pull(store_path) |>
  purrr::set_names(data_targets_failed$scale_id) |>
  purrr::map(
    .f = purrr::possibly(
      ~ targets::tar_meta(
        fields = c("name", "error"),
        complete_only = TRUE,
        store = .x
      ),
      otherwise = NULL
    )
  ) |>
  purrr::compact() |>
  purrr::list_rbind(names_to = "scale_id") |>
  dplyr::left_join(
    data_targets_meta |>
      dplyr::select(scale_id, scale),
    by = dplyr::join_by(scale_id)
  )

# Most common error targets across all failed units
data_error_counts <-
  data_errors_by_target |>
  dplyr::group_by(scale, name, error) |>
  dplyr::summarise(
    n_units = dplyr::n(),
    scale_ids = list(scale_id),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(n_units))

print(data_error_counts, n = Inf)


#----------------------------------------------------------#
# 4. Convergence and model evaluation summary -----
#----------------------------------------------------------#

# Read model_evaluation for every successful unit once;
#   both section 5 (convergence plot grid) and the
#   evaluation table below are derived from this single read.
list_model_evaluation <-
  data_targets_successful |>
  dplyr::pull(store_path) |>
  purrr::set_names(data_targets_successful$scale_id) |>
  purrr::map(
    .f = purrr::possibly(
      ~ targets::tar_read(
        "model_evaluation",
        store = .x
      ),
      otherwise = NULL
    )
  ) |>
  purrr::compact()


#--------------------------------------------------#
## 4.1. Convergence metrics -----
#--------------------------------------------------#

data_convergence_summary <-
  list_model_evaluation |>
  purrr::imap(
    .f = ~ tibble::tibble(
      scale_id = .y,
      linear_trend_slope = purrr::chuck(
        .x, "convergence", "linear_trend_slope"
      ),
      median_diff = purrr::chuck(
        .x, "convergence", "median_diff"
      )
    )
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    # Thresholds per check_convergence_jsdm() documentation:
    #   slope < 0.01 and diff < 1 indicate convergence
    converged = linear_trend_slope < 0.01 & median_diff < 1
  ) |>
  dplyr::left_join(
    data_targets_meta |>
      dplyr::select(scale_id, scale),
    by = dplyr::join_by(scale_id)
  ) |>
  dplyr::arrange(scale, scale_id)

print(data_convergence_summary, n = Inf)


#--------------------------------------------------#
## 4.2. Model R² summary -----
#--------------------------------------------------#

data_model_r2 <-
  list_model_evaluation |>
  purrr::imap(
    .f = ~ {
      vec_r2 <- purrr::chuck(.x, "model")
      tibble::tibble(
        scale_id = .y,
        R2_McFadden = vec_r2["R2-McFadden"],
        R2_Nagelkerke = vec_r2["R2-Nagelkerke"]
      )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::left_join(
    data_targets_meta |>
      dplyr::select(scale_id, scale),
    by = dplyr::join_by(scale_id)
  ) |>
  dplyr::arrange(scale, scale_id)

data_model_r2_summary <-
  data_model_r2 |>
  dplyr::group_by(scale) |>
  dplyr::summarise(
    mean_McFadden = mean(R2_McFadden, na.rm = TRUE),
    mean_Nagelkerke = mean(R2_Nagelkerke, na.rm = TRUE),
    min_Nagelkerke = min(R2_Nagelkerke, na.rm = TRUE),
    max_Nagelkerke = max(R2_Nagelkerke, na.rm = TRUE),
    .groups = "drop"
  )

print(data_model_r2_summary)


#----------------------------------------------------------#
# 5. Convergence plots grid -----
#----------------------------------------------------------#
# One cowplot::plot_grid() per scale so the number of panels
#   stays manageable regardless of how many units exist.

list_convergence_plots <-
  list_model_evaluation |>
  purrr::imap(
    .f = ~ purrr::chuck(.x, "convergence", "convergence_plot") +
      ggplot2::labs(subtitle = .y)
  ) |>
  purrr::keep_at(
    names(list_model_evaluation)
  )

vec_scales <-
  c("continental", "regional", "local") |>
  purrr::set_names()

list_plots <-
  purrr::map(
    .x = vec_scales,
    .f = ~ {
      ids_in_scale <-
        data_targets_successful |>
        dplyr::filter(scale == .x) |>
        dplyr::pull(scale_id)

      plots_in_scale <-
        list_convergence_plots[
          intersect(ids_in_scale, names(list_convergence_plots))
        ]

      if (length(plots_in_scale) == 0L) {
        return(invisible(NULL))
      }

      n_cols <- min(3L, length(plots_in_scale))

      cowplot::plot_grid(
        plotlist = plots_in_scale,
        ncol = n_cols
      )
    }
  )

list_plots[["local"]] +
  ggview::canvas(
    width = graphical_options$width * 2,
    height = graphical_options$height * 8,
    units = graphical_options$units,
    dpi = graphical_options$dpi
  )
list_plots[["regional"]] +
  ggview::canvas(
    width = graphical_options$width * 2,
    height = graphical_options$height * 3,
    units = graphical_options$units,
    dpi = graphical_options$dpi
  )
list_plots[["continental"]]

#----------------------------------------------------------#
# 6. ANOVA fractions summary -----
#----------------------------------------------------------#

list_model_anova <-
  data_targets_successful |>
  dplyr::pull(store_path) |>
  purrr::set_names(data_targets_successful$scale_id) |>
  purrr::map(
    .f = purrr::possibly(
      ~ targets::tar_read(
        "model_anova",
        store = .x
      ),
      otherwise = NULL
    )
  ) |>
  purrr::compact()

data_anova_fractions <-
  list_model_anova |>
  purrr::imap(
    .f = ~ extract_anova_fractions(
      anova_object = .x,
      clamp_negative = TRUE
    ) |>
      dplyr::mutate(
        age = 0,
        scale_id = .y
      ) |>
      recalculate_anova_components()
  ) |>
  purrr::list_rbind() |>
  dplyr::left_join(
    data_targets_meta |>
      dplyr::select(scale_id, scale),
    by = dplyr::join_by(scale_id)
  )

data_anova_summary <-
  data_anova_fractions |>
  dplyr::group_by(scale, component) |>
  dplyr::summarise(
    median_pct = median(R2_Nagelkerke_percentage, na.rm = TRUE),
    min_pct = min(R2_Nagelkerke_percentage, na.rm = TRUE),
    max_pct = max(R2_Nagelkerke_percentage, na.rm = TRUE),
    n_units = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::arrange(scale, dplyr::desc(median_pct))

print(data_anova_summary)

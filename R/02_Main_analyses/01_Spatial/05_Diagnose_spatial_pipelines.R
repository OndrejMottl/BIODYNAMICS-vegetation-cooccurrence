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
      "pipeline_spatial_resolution"
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

vec_tax_res <-
  c("genus", "family", "functional_type") |>
  purrr::set_names()

# Read model_evaluation for every successful unit and all three
#   resolutions; sections 4.1 and 4.2 summarise across all
#   scale_id × tax_res combinations.
list_model_evaluation_all <-
  vec_tax_res |>
  purrr::map(
    .f = ~ {
      res_i <- .x
      data_targets_successful |>
        dplyr::pull(store_path) |>
        purrr::set_names(
          dplyr::pull(data_targets_successful, scale_id)
        ) |>
        purrr::map(
          .f = purrr::possibly(
            ~ targets::tar_read_raw(
              name = stringr::str_glue("model_evaluation_{res_i}"),
              store = .x
            ),
            otherwise = NULL
          )
        ) |>
        purrr::compact()
    }
  )


# Genus-only flat list retained for section 5 convergence plot
#   grid (training-loss curves; one panel per spatial unit).
list_model_evaluation <- list_model_evaluation_all[["genus"]]


#--------------------------------------------------#
## 4.1. Convergence metrics -----
#--------------------------------------------------#

data_convergence_summary <-
  list_model_evaluation_all |>
  purrr::imap(
    .f = ~ {
      list_by_scale_i <- .x
      res_i <- .y
      list_by_scale_i |>
        purrr::imap(
          .f = ~ {
            tibble::tibble(
              tax_res = res_i,
              scale_id = .y,
              linear_trend_slope = purrr::chuck(
                .x, "convergence", "linear_trend_slope"
              ),
              median_diff = purrr::chuck(
                .x, "convergence", "median_diff"
              )
            )
          }
        ) |>
        purrr::list_rbind()
    }
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
  dplyr::select(scale, scale_id, tax_res, converged) |>
  tidyr::pivot_wider(
    names_from = tax_res,
    values_from = converged,
    names_prefix = "converged_"
  )

print(data_convergence_summary, n = Inf)

# Non-converged units (any resolution)
data_convergence_summary |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("converged_"),
    names_to = "tax_res",
    values_to = "converged",
    names_prefix = "converged_"
  ) |>
  dplyr::filter(!converged) |>
  dplyr::select(scale, scale_id, tax_res)



#----------------------------------------------------------#
# 5. Convergence plots grid -----
#----------------------------------------------------------#
# One cowplot::plot_grid() per tax_res x scale combination
#   so the number of panels stays manageable regardless of
#   how many units exist.

vec_scales <-
  c("continental", "regional", "local") |>
  purrr::set_names()

list_plots <-
  vec_scales |>
  purrr::map(
    .f = ~ {
      scale_i <- .x

      ids_in_scale <-
        data_targets_successful |>
        dplyr::filter(scale == scale_i) |>
        dplyr::pull(scale_id)

      vec_tax_res |>
        purrr::map(
          .f = ~ {
            tax_res_i <- .x

            list_convergence_plots_i <-
              list_model_evaluation_all[[tax_res_i]] |>
              purrr::imap(
                .f = ~ purrr::chuck(.x, "convergence", "convergence_plot") +
                  ggplot2::labs(subtitle = .y, title = NULL) +
                  ggplot2::theme(
                    title = ggplot2::element_blank(),
                    axis.title = ggplot2::element_blank()
                  )
              ) |>
              purrr::keep_at(
                names(list_model_evaluation_all[[tax_res_i]])
              )

            plots_in_scale <-
              list_convergence_plots_i[
                intersect(ids_in_scale, names(list_convergence_plots_i))
              ]

            if (length(plots_in_scale) == 0L) {
              return(invisible(NULL))
            }

            n_cols <- min(3L, length(plots_in_scale))

            plot_title <-
              cowplot::ggdraw() +
              cowplot::draw_label(
                label = stringr::str_glue(
                  "{scale_i} | {tax_res_i}"
                ),
                fontface = "bold",
                size = 14
              )

            cowplot::plot_grid(
              plot_title,
              cowplot::plot_grid(
                plotlist = plots_in_scale,
                ncol = n_cols
              ),
              ncol = 1L,
              rel_heights = c(0.05, 1)
            )
          }
        )
    }
  )


list_plots[["continental"]][["genus"]] +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )
list_plots[["continental"]][["family"]] +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )
list_plots[["continental"]][["functional_type"]] +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )

list_plots[["regional"]][["genus"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )
list_plots[["regional"]][["family"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )
list_plots[["regional"]][["functional_type"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]]
  )

list_plots[["local"]][["genus"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2
  )
list_plots[["local"]][["family"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2
  )
list_plots[["local"]][["functional_type"]] +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2
  )

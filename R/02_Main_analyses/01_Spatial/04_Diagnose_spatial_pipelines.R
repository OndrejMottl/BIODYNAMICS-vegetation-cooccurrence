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

base::source(
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
      stringr::str_glue("Data/targets/spatial_{scale}"),
      scale_id,
      "pipeline_spatial_resolution"
    )
  ) |>
  dplyr::mutate(
    store_exists = fs::dir_exists(store_path),
    # Read pipeline metadata once per unit; NULL for non-existent stores.
    # Cached in a list-column so each resolution check below re-uses it
    # without a second disk read.
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
    # This allows other branches to error (e.g. insufficient-data
    # branches) while still tracking which resolution branches
    # produced a usable model.
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

# All units where the pipeline store exists (regardless of per-resolution
# success). Sections 4 and 5 use purrr::possibly() when reading per-
# resolution targets, so failures are handled gracefully downstream.
data_targets_successful <-
  data_targets_meta |>
  dplyr::filter(store_exists)

# Units where the store exists but at least one resolution branch's key
# model target (mod_to_use_<res>) did not succeed.
data_targets_failed <-
  data_targets_meta |>
  dplyr::filter(
    store_exists &
      (!successful_genus | !successful_family | !successful_functional_type)
  )


#----------------------------------------------------------#
# 2. Pipeline status overview -----
#----------------------------------------------------------#

data_status_overview <-
  data_targets_meta |>
  dplyr::group_by(scale) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    n_not_run = base::sum(!store_exists),
    n_successful_genus = base::sum(successful_genus),
    n_successful_family = base::sum(successful_family),
    n_successful_functional_type = base::sum(successful_functional_type),
    .groups = "drop"
  )

base::print(data_status_overview)


#----------------------------------------------------------#
# 3. Error analysis (failed units) -----
#----------------------------------------------------------#

data_errors_by_target <-
  data_targets_failed |>
  dplyr::pull(store_path) |>
  purrr::set_names(dplyr::pull(data_targets_failed, scale_id)) |>
  purrr::map(
    .f = purrr::possibly(
      ~ targets::tar_meta(
        fields = c("name", "error"),
        complete_only = TRUE,
        store = .x
      ) |>
        dplyr::filter(!base::is.na(error)),
      otherwise = NULL
    )
  ) |>
  purrr::compact() |>
  purrr::list_rbind(names_to = "scale_id") |>
  dplyr::left_join(
    data_targets_meta |>
      dplyr::select(scale_id, scale),
    by = dplyr::join_by(scale_id)
  ) |>
  dplyr::filter(
    !stringr::str_starts(error, "could not load dependency")
  )

# Most common error targets across all failed units
data_error_counts <-
  data_errors_by_target |>
  dplyr::group_by(scale, name, error) |>
  dplyr::summarise(
    n_units = dplyr::n(),
    scale_ids = base::list(scale_id),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(n_units))

base::print(data_error_counts, n = Inf)


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

base::print(data_convergence_summary, n = Inf)
# Note: NA means that the model did not run

# Non-converged units (any resolution)
data_convergence_summary |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("converged_"),
    names_to = "tax_res",
    values_to = "converged",
    names_prefix = "converged_"
  ) |>
  dplyr::filter(!converged) |>
  dplyr::select(scale, scale_id, tax_res) |>
  View()


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
              purrr::chuck(list_model_evaluation_all, tax_res_i) |>
              purrr::imap(
                .f = ~ purrr::chuck(.x, "convergence", "convergence_plot") +
                  ggplot2::labs(subtitle = .y, title = NULL) +
                  ggplot2::theme(
                    title = ggplot2::element_blank(),
                    axis.title = ggplot2::element_blank()
                  )
              ) |>
              purrr::keep_at(
                base::names(purrr::chuck(list_model_evaluation_all, tax_res_i))
              )

            plots_in_scale <-
              list_convergence_plots_i[
                base::intersect(
                  ids_in_scale,
                  base::names(list_convergence_plots_i)
                )
              ]

            if (
              base::length(plots_in_scale) == 0L
            ) {
              return(base::invisible(NULL))
            }

            n_cols <-
              base::min(3L, base::length(plots_in_scale))

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

purrr::chuck(list_plots, "continental", "genus") +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "continental", "family") +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "continental", "functional_type") +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

purrr::chuck(list_plots, "regional", "genus") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "regional", "family") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "regional", "functional_type") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 3,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

purrr::chuck(list_plots, "local", "genus") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2,
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "local", "family") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2,
    bg = graphical_options[["bg"]]
  )
purrr::chuck(list_plots, "local", "functional_type") +
  ggview::canvas(
    width = graphical_options[["width"]] * 2,
    height = graphical_options[["height"]] * 8,
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]] * 2,
    bg = graphical_options[["bg"]]
  )

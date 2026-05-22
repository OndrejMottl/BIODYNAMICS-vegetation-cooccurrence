#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Tune modern spatial model convergence
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads convergence diagnostics from completed modern spatial
#   targets stores and prints diagnostics for direct manual/agent
#   tuning in Data/Input/Model_tuning/.
#
# WORKFLOW:
#   1. Run Sections 0-4 and inspect the console diagnostics.
#   2. Adjust Data/Input/Model_tuning/*.csv directly.
#   3. Set flag_rerun_non_converged TRUE to rerun affected units.
#   4. Repeat until all completed models converge.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

vec_scales_to_check <-
  c("continental", "regional", "local")

vec_resolution_ids <-
  c("genus", "family", "ft_modern")

flag_rerun_non_converged <- FALSE
flag_save_plot_grids <- FALSE

threshold_linear_trend_slope <- 0.01
threshold_median_diff <- 1

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")

path_output_figures <-
  here::here("Outputs/Figures/Model_tuning")

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Read target metadata -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "modern",
    scales = vec_scales_to_check
  ) |>
  dplyr::mutate(
    store_path_display = fs::path_rel(
      path = .data$store_path,
      start = here::here()
    ) |>
      base::as.character(),
    data_meta = purrr::map(
      .x = .data$store_path,
      .f = ~ {
        if (
          fs::dir_exists(.x)
        ) {
          return(read_targets_store_meta(.x))
        }
        return(NULL)
      }
    )
  )

data_status_overview <-
  data_store_index |>
  dplyr::mutate(
    n_finished_resolutions = purrr::map_int(
      .x = .data$data_meta,
      .f = ~ {
        data_meta_i <- .x

        res <-
          vec_resolution_ids |>
          purrr::map_lgl(
            .f = ~ {
              resolution_id <- .x

              check_target_succeeded(
                data_meta = data_meta_i,
                target_name = stringr::str_glue(
                  "model_evaluation_{resolution_id}"
                )
              )
            }
          ) |>
          base::sum()

        return(res)
      }
    )
  ) |>
  dplyr::group_by(.data$scale) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    n_stores = base::sum(.data$store_exists),
    n_with_any_finished_model = base::sum(
      .data$n_finished_resolutions > 0L
    ),
    n_finished_resolution_branches = base::sum(
      .data$n_finished_resolutions
    ),
    .groups = "drop"
  )

base::print(data_status_overview)


#----------------------------------------------------------#
# 2. Extract convergence diagnostics -----
#----------------------------------------------------------#

data_convergence <-
  data_store_index |>
  dplyr::filter(.data$store_exists) |>
  dplyr::mutate(row_id = dplyr::row_number()) |>
  dplyr::group_split(.data$row_id, .keep = FALSE) |>
  purrr::map(
    .f = ~ {
      data_store_row <- .x
      data_meta <- data_store_row[["data_meta"]][[1L]]

      vec_resolution_ids |>
        purrr::map(
          .f = ~ {
            resolution_id <- .x
            target_name <-
              stringr::str_glue("model_evaluation_{resolution_id}")

            data_target_row <-
              if (
                base::is.null(data_meta) ||
                  !base::all(
                    c("name", "error") %in% base::colnames(data_meta)
                  )
              ) {
                tibble::tibble(
                  name = base::character(),
                  error = base::character()
                )
              } else {
                data_meta |>
                  dplyr::filter(
                    .data$name == .env$target_name
                  )
              }

            data_resolution_errors <-
              if (
                base::is.null(data_meta) ||
                  !base::all(
                    c("name", "error") %in% base::colnames(data_meta)
                  )
              ) {
                tibble::tibble(
                  name = base::character(),
                  error = base::character()
                )
              } else {
                data_meta |>
                  dplyr::filter(
                    stringr::str_ends(
                      .data$name,
                      stringr::str_glue("_{resolution_id}")
                    ),
                    !base::is.na(.data$error)
                  ) |>
                  dplyr::select(name, error)
              }

            branch_error <-
              if (
                base::nrow(data_resolution_errors) == 0L
              ) {
                NA_character_
              } else {
                data_resolution_errors |>
                  dplyr::mutate(
                    message = stringr::str_glue(
                      "{.data$name}: {.data$error}"
                    )
                  ) |>
                  dplyr::pull(message) |>
                  stringr::str_c(collapse = " | ")
              }

            model_ran <-
              check_target_succeeded(
                data_meta = data_meta,
                target_name = target_name
              )

            model_evaluation_i <-
              if (
                base::isTRUE(model_ran)
              ) {
                read_model_evaluation_target(
                  store_path = data_store_row[["store_path"]],
                  resolution_id = resolution_id
                )
              } else {
                NULL
              }

            tibble::tibble(
              data_source = data_store_row[["data_source"]],
              scale = data_store_row[["scale"]],
              scale_id = data_store_row[["scale_id"]],
              pipeline_name = data_store_row[["pipeline_name"]],
              store_path = data_store_row[["store_path"]],
              store_path_display = data_store_row[["store_path_display"]],
              resolution_id = resolution_id,
              model_ran = !base::is.null(model_evaluation_i),
              target_status = dplyr::case_when(
                !base::is.null(model_evaluation_i) ~ "succeeded",
                !base::is.na(branch_error) ~ "errored",
                base::nrow(data_target_row) == 0L ~ "not_built",
                .default = "not_successful"
              ),
              target_error = branch_error,
              model_evaluation = base::list(model_evaluation_i),
              linear_trend_slope = purrr::pluck(
                model_evaluation_i,
                "convergence",
                "linear_trend_slope",
                .default = NA_real_
              ),
              median_diff = purrr::pluck(
                model_evaluation_i,
                "convergence",
                "median_diff",
                .default = NA_real_
              ),
              epochs_run = purrr::pluck(
                model_evaluation_i,
                "convergence",
                "epochs_run",
                .default = NA_integer_
              ),
              early_stopping_triggered = purrr::pluck(
                model_evaluation_i,
                "convergence",
                "early_stopping_triggered",
                .default = NA
              )
            )
          }
        ) |>
        purrr::list_rbind()
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    converged = .data$linear_trend_slope <
      threshold_linear_trend_slope &
      .data$median_diff < threshold_median_diff
  )

data_convergence_table <-
  data_convergence |>
  dplyr::select(-model_evaluation)

data_non_converged <-
  data_convergence |>
  dplyr::filter(
    .data$model_ran &
      !.data$converged
  )

data_model_evaluation_unsuccessful <-
  data_convergence_table |>
  dplyr::filter(!.data$model_ran) |>
  dplyr::select(
    scale,
    scale_id,
    resolution_id,
    target_status,
    target_error,
    store_path_display
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$scale_id,
    .data$resolution_id
  )

data_diagnostic_summary <-
  data_non_converged |>
  dplyr::mutate(
    model_tuning = purrr::map2(
      .x = .data$scale_id,
      .y = .data$resolution_id,
      .f = ~ get_model_tuning_params(
        analysis_id = "modern_spatial",
        scale_id = .x,
        resolution_id = .y
      )
    ),
    n_iter = purrr::map_int(
      .x = .data$model_tuning,
      .f = ~ purrr::chuck(.x, "n_iter")
    ),
    n_step_size = purrr::map_int(
      .x = .data$model_tuning,
      .f = ~ coerce_null_to_na_integer(
        purrr::pluck(.x, "n_step_size")
      )
    ),
    n_sampling = purrr::map_int(
      .x = .data$model_tuning,
      .f = ~ purrr::chuck(.x, "n_sampling")
    ),
    n_samples_anova = purrr::map_int(
      .x = .data$model_tuning,
      .f = ~ purrr::chuck(.x, "n_samples_anova")
    ),
    n_early_stopping = purrr::map_int(
      .x = .data$model_tuning,
      .f = ~ coerce_null_to_na_integer(
        purrr::pluck(.x, "n_early_stopping")
      )
    )
  ) |>
  dplyr::select(
    scale,
    scale_id,
    resolution_id,
    n_iter,
    n_step_size,
    n_sampling,
    n_samples_anova,
    n_early_stopping,
    linear_trend_slope,
    median_diff,
    epochs_run,
    early_stopping_triggered
  ) |>
  dplyr::arrange(
    .data$scale,
    .data$scale_id,
    .data$resolution_id
  )

base::message("\nModel evaluation branches without successful output:")
if (
  base::nrow(data_model_evaluation_unsuccessful) == 0L
) {
  base::message("None.")
} else {
  base::print(
    data_model_evaluation_unsuccessful,
    n = Inf,
    width = Inf
  )
}

base::message("\nNon-converged completed models with current tuning:")
if (
  base::nrow(data_diagnostic_summary) == 0L
) {
  base::message("None.")
} else {
  base::print(data_diagnostic_summary, n = Inf, width = Inf)
}


#----------------------------------------------------------#
# 3. Optional convergence plot grids -----
#----------------------------------------------------------#

if (
  base::isTRUE(flag_save_plot_grids)
) {
  vec_scales_to_check |>
    purrr::walk(
      .f = ~ {
        scale_i <- .x

        vec_resolution_ids |>
          purrr::walk(
            .f = ~ {
              resolution_id_i <- .x

              data_plot_source <-
                data_convergence |>
                dplyr::filter(
                  .data$model_ran,
                  .data$scale == .env$scale_i,
                  .data$resolution_id == .env$resolution_id_i
                )

              if (
                base::nrow(data_plot_source) == 0L
              ) {
                return(base::invisible(NULL))
              }

              list_convergence_plots <-
                purrr::map2(
                  .x = data_plot_source[["model_evaluation"]],
                  .y = data_plot_source[["scale_id"]],
                  .f = ~ purrr::chuck(
                    .x,
                    "convergence",
                    "convergence_plot"
                  ) +
                    ggplot2::labs(
                      title = NULL,
                      subtitle = .y
                    ) +
                    ggplot2::theme(
                      axis.title = ggplot2::element_blank()
                    )
                )

              n_cols <-
                base::min(3L, base::length(list_convergence_plots))

              plot_title <-
                cowplot::ggdraw() +
                cowplot::draw_label(
                  label = stringr::str_glue(
                    "modern | {scale_i} | {resolution_id_i}"
                  ),
                  fontface = "bold",
                  size = 14
                )

              plot_grid <-
                cowplot::plot_grid(
                  plot_title,
                  cowplot::plot_grid(
                    plotlist = list_convergence_plots,
                    ncol = n_cols
                  ),
                  ncol = 1L,
                  rel_heights = c(0.05, 1)
                ) +
                ggview::canvas(
                  width = graphical_options[["width"]] * 2,
                  height = graphical_options[["height"]] * 2,
                  units = graphical_options[["units"]],
                  dpi = graphical_options[["dpi"]],
                  bg = graphical_options[["bg"]]
                )

              file_plot <-
                base::file.path(
                  path_output_figures,
                  stringr::str_glue(
                    "modern_spatial_convergence_",
                    "{scale_i}_{resolution_id_i}_{tag_date}.png"
                  )
                )

              base::dir.create(
                path = path_output_figures,
                showWarnings = FALSE,
                recursive = TRUE
              )

              ggview::save_ggplot(
                plot = plot_grid,
                file = file_plot
              )
            }
          )
      }
    )
}


#----------------------------------------------------------#
# 4. Rerun affected spatial units -----
#----------------------------------------------------------#

data_units_to_rerun <-
  data_non_converged |>
  dplyr::distinct(
    scale,
    scale_id
  )

if (
  base::isTRUE(flag_rerun_non_converged) &&
    base::nrow(data_units_to_rerun) > 0L
) {
  vec_scales_to_check |>
    purrr::walk(
      .f = ~ {
        scale_i <- .x

        vec_ids_i <-
          data_units_to_rerun |>
          dplyr::filter(.data$scale == .env$scale_i) |>
          dplyr::pull(scale_id)

        if (
          base::length(vec_ids_i) == 0L
        ) {
          base::message(
            stringr::str_glue(
              "No non-converged modern units for scale: {scale_i}"
            )
          )
          return(base::invisible(NULL))
        }

        base::Sys.setenv(
          R_CONFIG_ACTIVE = stringr::str_glue(
            "project_modern_spatial_{scale_i}"
          )
        )

        tictoc::tic(
          stringr::str_glue(
            "Rerunning non-converged modern units for {scale_i}"
          )
        )

        vec_ids_i |>
          purrr::walk(
            .progress = TRUE,
            .f = ~ {
              base::message(
                stringr::str_glue("\n\nRerunning modern unit: {.x}\n\n")
              )
              run_pipeline(
                sel_script = here::here(
                  "R/Pipelines/pipeline_modern_spatial_resolution.R"
                ),
                store_suffix = .x
              )
            }
          )

        tictoc::toc()
      }
    )
} else if (
  base::isFALSE(flag_rerun_non_converged)
) {
  base::message(
    "\nNo pipelines were rerun. Set flag_rerun_non_converged TRUE ",
    "after editing Data/Input/Model_tuning/*.csv."
  )
}

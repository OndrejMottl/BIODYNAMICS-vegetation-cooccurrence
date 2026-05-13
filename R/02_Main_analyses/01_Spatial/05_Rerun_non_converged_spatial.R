#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         Re-run non-converged spatial model units
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Detects spatial units where pipeline_paleo_spatial_resolution did
#   not converge at any taxonomic resolution, prints a
#   diagnostic summary to guide model tuning adjustments,
#   then reruns the non-converged units.
#
# WORKFLOW:
#   1. Run Sections 0–3 to identify non-converged units and
#      review their tuning parameters and convergence metrics.
#   2. Adjust Data/Input/Model_tuning/*.csv as needed.
#   3. Run Section 4 to rerun the non-converged units.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Load spatial grid and build store paths -----
#----------------------------------------------------------#

data_grid <-
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
    store_exists = fs::dir_exists(store_path)
  )


#----------------------------------------------------------#
# 2. Read model evaluation and extract convergence metrics -----
#----------------------------------------------------------#

vec_tax_res <-
  c("genus", "family", "functional_type") |>
  rlang::set_names()

# Only attempt reads for units where the store exists.
data_grid_with_store <-
  data_grid |>
  dplyr::filter(store_exists)

# Read model_evaluation_<res> for every unit × resolution and extract
# convergence metrics. purrr::possibly() ensures NULL is returned
# gracefully for any unit that did not reach this target.
data_convergence <-
  vec_tax_res |>
  purrr::imap(
    .f = ~ {
      tax_res_element_i <- .x
      tax_res_i <- .y
      data_grid_with_store |>
        dplyr::mutate(
          model_evaluation = purrr::map(
            .x = store_path,
            .f = purrr::possibly(
              ~ targets::tar_read_raw(
                name = stringr::str_glue(
                  "model_evaluation_{tax_res_i}"
                ),
                store = .x
              ),
              otherwise = NULL
            )
          ),
          tax_res = tax_res_i,
          linear_trend_slope = purrr::map_dbl(
            .x = model_evaluation,
            .f = ~ purrr::pluck(
              .x, "convergence", "linear_trend_slope",
              .default = NA_real_
            )
          ),
          median_diff = purrr::map_dbl(
            .x = model_evaluation,
            .f = ~ purrr::pluck(
              .x, "convergence", "median_diff",
              .default = NA_real_
            )
          ),
          epochs_run = purrr::map_int(
            .x = model_evaluation,
            .f = ~ purrr::pluck(
              .x, "convergence", "epochs_run",
              .default = NA_integer_
            )
          ),
          early_stopping_triggered = purrr::map_lgl(
            .x = model_evaluation,
            .f = ~ purrr::pluck(
              .x, "convergence", "early_stopping_triggered",
              .default = NA
            )
          ),
          # TRUE only when the model target was actually computed; FALSE
          # when purrr::possibly() returned NULL (model did not run).
          model_ran = purrr::map_lgl(
            .x = model_evaluation,
            .f = ~ !base::is.null(.x)
          )
        ) |>
        dplyr::select(-model_evaluation)
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    # Thresholds per check_convergence_jsdm() documentation:
    #   slope < 0.01 and diff < 1 indicate convergence
    converged = linear_trend_slope < 0.01 & median_diff < 1
  )

# Non-converged: model must have run AND must not have converged.
# Units where the model did not run at all (model_ran == FALSE) are
# excluded — they need separate investigation, not a rerun.
data_non_converged <-
  data_convergence |>
  dplyr::filter(model_ran & !converged)

#----------------------------------------------------------#
# 3. Print diagnostic summary -----
#----------------------------------------------------------#

# Load tuning parameters for easy cross-resolution comparison in the
# printed summary.
data_diagnostic_summary <-
  data_non_converged |>
  dplyr::mutate(
    model_tuning = purrr::map2(
      .x = scale_id,
      .y = tax_res,
      .f = ~ get_model_tuning_params(
        analysis_id = "paleo_spatial",
        scale_id = .x,
        resolution_id = .y
      )
    ),
    n_iter = purrr::map_int(
      .x = model_tuning,
      .f = ~ purrr::chuck(.x, "n_iter")
    ),
    n_step_size = purrr::map_int(
      .x = model_tuning,
      .f = ~ {
        value <- purrr::pluck(.x, "n_step_size")
        if (base::is.null(value)) NA_integer_ else value
      }
    ),
    n_sampling = purrr::map_int(
      .x = model_tuning,
      .f = ~ purrr::chuck(.x, "n_sampling")
    ),
    n_samples_anova = purrr::map_int(
      .x = model_tuning,
      .f = ~ purrr::chuck(.x, "n_samples_anova")
    ),
    n_early_stopping = purrr::map_int(
      .x = model_tuning,
      .f = ~ {
        value <- purrr::pluck(.x, "n_early_stopping")
        if (base::is.null(value)) NA_integer_ else value
      }
    )
  ) |>
  dplyr::select(
    scale,
    scale_id,
    tax_res,
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
  dplyr::arrange(scale, scale_id, tax_res)

# Review this output and adjust Data/Input/Model_tuning/*.csv before
# running Section 4.
base::print(data_diagnostic_summary, n = Inf)


#----------------------------------------------------------#
# 4. Re-run non-converged spatial units -----
#----------------------------------------------------------#
# Run this section ONLY after:
#   (a) reviewing the diagnostic summary above, and
#   (b) adjusting Data/Input/Model_tuning/*.csv as needed.

vec_units_to_rerun <-
  data_non_converged |>
  dplyr::distinct(scale, scale_id)

c("continental", "regional", "local") |>
  purrr::walk(
    .f = ~ {
      scale_i <- .x

      vec_ids_i <-
        vec_units_to_rerun |>
        dplyr::filter(scale == scale_i) |>
        dplyr::pull(scale_id)

      if (
        base::length(vec_ids_i) == 0L
      ) {
        base::message(
          stringr::str_glue(
            "No non-converged units for scale: {scale_i}"
          )
        )
        return(base::invisible(NULL))
      }

      base::message(
        stringr::str_glue(
          "\n\nRe-running {base::length(vec_ids_i)}",
          " unit(s) for scale: {scale_i}\n\n"
        )
      )

      base::Sys.setenv(
        R_CONFIG_ACTIVE = stringr::str_glue(
          "project_paleo_spatial_{scale_i}"
        )
      )

      tictoc::tic(
        stringr::str_glue(
          "Re-running non-converged units for scale: {scale_i}"
        )
      )

      vec_ids_i |>
        purrr::walk(
          .progress = TRUE,
          .f = ~ {
            base::message(
              stringr::str_glue("\n\nRe-running: {.x}\n\n")
            )
            run_pipeline(
              sel_script = here::here(
                "R/02_Main_analyses/pipeline_paleo_spatial_resolution.R"
              ),
              store_suffix = .x
            )
          }
        )

      tictoc::toc()
    }
  )

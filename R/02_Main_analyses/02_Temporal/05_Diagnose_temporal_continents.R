#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Diagnose temporal pipeline convergence: all continents
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Checks pipeline status, convergence, and model R² for every
#   time slice across all continental temporal configurations.
# Continental configurations are derived from spatial_grid.csv
#   (scale == "continental"), mapped to config names as
#   project_temporal_{scale_id} (e.g. project_temporal_europe).
# Requires that the corresponding Run_temporal_*.R scripts have
#   been executed (pipeline_time.R).


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Build continental configuration inventory -----
#----------------------------------------------------------#

data_continents <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(scale == "continental") |>
  dplyr::select(scale_id) |>
  dplyr::mutate(
    config_name = base::paste0("project_temporal_", scale_id),
    store_path = here::here(
      base::paste0(
        "Data/targets/", config_name, "/pipeline_time/"
      )
    ),
    store_exists = fs::dir_exists(store_path)
  )

base::message(
  "Continental configurations found: ",
  base::paste(data_continents$config_name, collapse = ", ")
)

base::message(
  "Stores present: ",
  base::paste(
    data_continents$config_name[data_continents$store_exists],
    collapse = ", "
  )
)


#----------------------------------------------------------#
# 2. Diagnose per continent -----
#----------------------------------------------------------#

purrr::pwalk(
  .l = list(
    scale_id = data_continents$scale_id,
    config_name = data_continents$config_name,
    store_path = data_continents$store_path,
    store_exists = data_continents$store_exists
  ),
  .f = function(
    scale_id,
    config_name,
    store_path,
    store_exists
  ) {
    base::message(
      "\n", base::strrep("=", 60),
      "\nCONTINENT: ", config_name,
      "\n", base::strrep("=", 60)
    )

    if (
      isFALSE(store_exists)
    ) {
      base::warning(
        "Target store not found for '", config_name, "': ", store_path,
        "\nSkipping. Run the corresponding 0*_Run_temporal_",
        scale_id, ".R script first."
      )
      return(invisible(NULL))
    }

    Sys.setenv(R_CONFIG_ACTIVE = config_name)

    graphical_options <-
      get_active_config("graphical")


    #--------------------------------------------------#
    ## 2.1. Build time-slice inventory -----
    #--------------------------------------------------#

    vec_age_lim <-
      get_active_config(c("vegvault_data", "age_lim"))

    n_time_step <-
      get_active_config(c("data_processing", "time_step"))

    data_to_map_age <-
      tibble::tibble(
        age = base::seq(
          from = base::min(vec_age_lim),
          to = base::max(vec_age_lim),
          by = n_time_step
        )
      ) |>
      dplyr::mutate(
        age_name = base::paste0("timeslice_", age),
        target_name = base::paste0("model_evaluation_", age_name)
      )

    base::message(
      "Time slices: ",
      base::nrow(data_to_map_age),
      " (", base::min(data_to_map_age$age), "\u2013",
      base::max(data_to_map_age$age), " yr BP by ", n_time_step, " yr)"
    )


    #--------------------------------------------------#
    ## 2.2. Pipeline status overview -----
    #--------------------------------------------------#

    data_tar_meta <-
      targets::tar_meta(
        fields = c("name", "error"),
        store = store_path
      )

    data_slice_status <-
      data_to_map_age |>
      dplyr::left_join(
        data_tar_meta |>
          dplyr::filter(
            stringr::str_detect(
              string = name,
              pattern = "^model_evaluation_timeslice_"
            )
          ) |>
          dplyr::rename(target_name = name),
        by = dplyr::join_by(target_name)
      ) |>
      dplyr::mutate(
        status = dplyr::case_when(
          !base::is.na(error) ~ "failed",
          base::is.na(error) & target_name %in% data_tar_meta$name ~ "successful",
          .default = "not_run"
        )
      )

    data_status_overview <-
      data_slice_status |>
      dplyr::group_by(status) |>
      dplyr::summarise(
        n = dplyr::n(),
        ages = base::paste(age, collapse = ", "),
        .groups = "drop"
      ) |>
      dplyr::arrange(
        base::match(status, c("successful", "failed", "not_run"))
      )

    base::message("\n--- Pipeline status overview ---")
    print(data_status_overview)

    data_slices_successful <-
      data_slice_status |>
      dplyr::filter(status == "successful")

    data_slices_failed <-
      data_slice_status |>
      dplyr::filter(status == "failed")


    #--------------------------------------------------#
    ## 2.3. Error analysis (failed slices) -----
    #--------------------------------------------------#

    if (
      base::nrow(data_slices_failed) > 0L
    ) {
      base::message("\n--- Errors in failed slices ---")

      data_errors <-
        data_slices_failed |>
        dplyr::select(age, age_name, target_name, error) |>
        dplyr::arrange(age)

      print(data_errors, n = Inf)
    } else {
      base::message("\nNo failed slices.")
    }

    if (
      base::nrow(data_slices_successful) == 0L
    ) {
      base::message(
        "No successful model_evaluation targets for '",
        config_name, "'. Skipping metrics."
      )
      return(invisible(NULL))
    }


    #--------------------------------------------------#
    ## 2.4. Read model evaluation targets -----
    #--------------------------------------------------#

    list_model_evaluation <-
      data_slices_successful |>
      dplyr::pull(target_name) |>
      purrr::set_names(
        data_slices_successful |>
          dplyr::pull(age_name)
      ) |>
      purrr::map(
        .f = purrr::possibly(
          ~ targets::tar_read_raw(
            name = .x,
            store = store_path
          ),
          otherwise = NULL
        )
      ) |>
      purrr::compact()

    if (
      base::length(list_model_evaluation) == 0L
    ) {
      base::message(
        "No model_evaluation targets readable for '", config_name,
        "'. Skipping metrics."
      )
      return(invisible(NULL))
    }


    #--------------------------------------------------#
    ## 2.5. Convergence metrics -----
    #--------------------------------------------------#

    base::message("\n--- Convergence metrics ---")

    data_convergence_summary <-
      list_model_evaluation |>
      purrr::imap(
        .f = ~ tibble::tibble(
          age_name = .y,
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
        #   slope < 0.01 and diff < 1 indicate convergence.
        converged = linear_trend_slope < 0.01 & median_diff < 1
      ) |>
      dplyr::left_join(
        data_to_map_age |>
          dplyr::select(age_name, age),
        by = dplyr::join_by(age_name)
      ) |>
      dplyr::select(age, age_name, linear_trend_slope, median_diff, converged) |>
      dplyr::arrange(age)

    print(data_convergence_summary, n = Inf)

    vec_non_converged_ages <-
      data_convergence_summary |>
      dplyr::filter(!converged) |>
      dplyr::pull(age)

    if (
      base::length(vec_non_converged_ages) == 0L
    ) {
      base::message("All evaluated slices have converged.")
    } else {
      base::message(
        "Non-converged slices (yr BP): ",
        base::paste(vec_non_converged_ages, collapse = ", ")
      )
    }


    #--------------------------------------------------#
    ## 2.6. Model R² summary -----
    #--------------------------------------------------#

    base::message("\n--- Model R\u00b2 per slice ---")

    data_model_r2 <-
      list_model_evaluation |>
      purrr::imap(
        .f = ~ {
          vec_r2 <-
            purrr::chuck(.x, "model")
          tibble::tibble(
            age_name = .y,
            R2_McFadden = vec_r2["R2-McFadden"],
            R2_Nagelkerke = vec_r2["R2-Nagelkerke"]
          )
        }
      ) |>
      purrr::list_rbind() |>
      dplyr::left_join(
        data_to_map_age |>
          dplyr::select(age_name, age),
        by = dplyr::join_by(age_name)
      ) |>
      dplyr::select(age, R2_McFadden, R2_Nagelkerke) |>
      dplyr::arrange(age)

    print(data_model_r2, n = Inf)

    data_model_r2_summary <-
      data_model_r2 |>
      dplyr::summarise(
        mean_McFadden = mean(R2_McFadden, na.rm = TRUE),
        mean_Nagelkerke = mean(R2_Nagelkerke, na.rm = TRUE),
        min_Nagelkerke = min(R2_Nagelkerke, na.rm = TRUE),
        max_Nagelkerke = max(R2_Nagelkerke, na.rm = TRUE)
      )

    base::message("\nR\u00b2 summary across all evaluated slices:")
    print(data_model_r2_summary)


    #--------------------------------------------------#
    ## 2.7. Convergence plots grid -----
    #--------------------------------------------------#

    list_convergence_plots <-
      list_model_evaluation |>
      purrr::imap(
        .f = ~ {
          slice_age <-
            data_to_map_age |>
            dplyr::filter(age_name == .y) |>
            dplyr::pull(age)

          purrr::chuck(.x, "convergence", "convergence_plot") +
            ggplot2::labs(
              subtitle = base::paste0(slice_age, " yr BP"),
              title = NULL
            ) +
            ggplot2::theme(
              axis.title = ggplot2::element_blank()
            )
        }
      )

    n_slices <-
      base::length(list_convergence_plots)

    n_cols <-
      base::min(3L, n_slices)

    cowplot::plot_grid(
      plotlist = list_convergence_plots,
      ncol = n_cols
    ) +
      ggview::canvas(
        width = graphical_options[["width"]] * 2,
        height = graphical_options[["height"]] * 4,
        units = graphical_options[["units"]],
        dpi = graphical_options[["dpi"]]
      )
  }
)

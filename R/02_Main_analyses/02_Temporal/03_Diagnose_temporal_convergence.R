#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Diagnose temporal pipeline convergence
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Checks pipeline status, convergence, and model R² for
#   every time slice in the active temporal configuration.
# Set R_CONFIG_ACTIVE before sourcing, e.g.:
#   Sys.setenv(R_CONFIG_ACTIVE = "project_temporal_europe")
# Requires that the pipeline_time.R pipeline has been run.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_temporal_europe")


set_store <-
  here::here(
    base::paste0(
      get_active_config("target_store"), "/pipeline_time/"
    )
  )


# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Build time-slice inventory -----
#----------------------------------------------------------#

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
  "Time slices defined: ",
  base::nrow(data_to_map_age),
  " (", base::min(data_to_map_age$age), " \u2013 ",
  base::max(data_to_map_age$age), " yr BP by ", n_time_step, " yr)"
)


#----------------------------------------------------------#
# 2. Pipeline status overview -----
#----------------------------------------------------------#

flag_store_exists <-
  fs::dir_exists(set_store)

if (
  isFALSE(flag_store_exists)
) {
  base::warning(
    "Target store does not exist: ", set_store,
    "\nHas the pipeline been run? See 01_Run_temporal_europe.R"
  )
}

data_tar_meta <-
  if (
    isTRUE(flag_store_exists)
  ) {
    targets::tar_meta(
      fields = c("name", "error"),
      store = set_store
    )
  } else {
    tibble::tibble(
      name = base::character(0),
      error = base::character(0)
    )
  }

# Filter to model_evaluation targets only, then left-join to full inventory.
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
      # tar_meta only lists targets that have been built; error == NA means
      # the target completed without error.
      !base::is.na(error) ~ "failed",
      # A row exists in tar_meta with no error → successful.
      base::is.na(error) & target_name %in% data_tar_meta$name ~ "successful",
      # No row in tar_meta at all → not yet run.
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


#----------------------------------------------------------#
# 3. Error analysis (failed slices) -----
#----------------------------------------------------------#

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


#----------------------------------------------------------#
# 4. Convergence and model evaluation summary -----
#----------------------------------------------------------#

# Read model_evaluation for every successful slice once;
#   both section 4.1 (convergence metrics) and 4.2 (R²) are
#   derived from this single read.
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
        store = set_store
      ),
      otherwise = NULL
    )
  ) |>
  purrr::compact()

if (
  base::length(list_model_evaluation) == 0L
) {
  base::message("No model_evaluation targets available yet. Aborting.")
  base::stop(
    "No model_evaluation targets available in '", set_store, "'."
  )
}


#--------------------------------------------------#
## 4.1. Convergence metrics -----
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
## 4.2. Model R² summary -----
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


#----------------------------------------------------------#
# 5. Convergence plots grid -----
#----------------------------------------------------------#

list_convergence_plots <-
  list_model_evaluation |>
  purrr::imap(
    .f = ~ {
      # Extract numeric age from age_name for a readable panel subtitle.
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

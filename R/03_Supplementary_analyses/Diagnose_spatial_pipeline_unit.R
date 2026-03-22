#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Diagnose spatial pipeline — single unit deep-dive
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Detailed diagnostics for ONE spatial unit. Set `sel_scale_id`
#   at the top and source the script interactively to inspect:
#   - target build/error status
#   - model convergence plot
#   - species-level evaluation metrics
#   - ANOVA variance partition fractions


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Edit this to switch between spatial units.
sel_scale_id <- "eu_r005"

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Derive store path -----
#----------------------------------------------------------#

data_grid <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  )

sel_scale <-
  data_grid |>
  dplyr::filter(scale_id == sel_scale_id) |>
  dplyr::pull(scale)

sel_store_path <-
  here::here(
    paste0("Data/targets/spatial_", sel_scale),
    sel_scale_id,
    "pipeline_basic"
  )

message("Inspecting: ", sel_scale_id, "  (scale: ", sel_scale, ")")
message("Store path: ", sel_store_path)

if (
  !fs::dir_exists(sel_store_path)
) {
  stop(
    "Store path does not exist: ", sel_store_path,
    "\nHas the pipeline been run for this unit?"
  )
}


#----------------------------------------------------------#
# 2. Target-level build status -----
#----------------------------------------------------------#

data_targets_all <-
  targets::tar_meta(
    fields = c("name", "type", "time", "seconds", "error"),
    complete_only = FALSE,
    store = sel_store_path
  )

# Overview: which targets are built vs. errored
data_targets_all |>
  dplyr::mutate(
    status = dplyr::case_when(
      !is.na(error) ~ "error",
      !is.na(time) ~ "built",
      .default = "not_built"
    )
  ) |>
  dplyr::select(name, type, status, seconds, time) |>
  dplyr::arrange(status, name) |>
  print(n = Inf)


#----------------------------------------------------------#
# 3. Error details -----
#----------------------------------------------------------#

data_target_errors <-
  targets::tar_meta(
    fields = c("name", "error"),
    complete_only = TRUE,
    store = sel_store_path
  )

if (nrow(data_target_errors) == 0L) {
  message("No errors found for unit: ", sel_scale_id)
} else {
  message(
    nrow(data_target_errors), " target(s) with errors:"
  )
  data_target_errors |>
    print(n = Inf)
}


#----------------------------------------------------------#
# 4. Convergence diagnostics -----
#----------------------------------------------------------#

model_evaluation <-
  purrr::possibly(
    ~ targets::tar_read(
      "model_evaluation",
      store = sel_store_path
    ),
    otherwise = NULL
  )()

if (
  is.null(model_evaluation)
) {
  message("Target 'model_evaluation' not available.")
} else {
  convergence_info <- model_evaluation$convergence

  message(
    "Convergence diagnostic for: ", sel_scale_id, "\n",
    "  Linear trend slope : ", convergence_info$linear_trend_slope,
    "  (threshold < 0.01)\n",
    "  Median diff        : ", convergence_info$median_diff,
    "  (threshold < 1)\n",
    "  Note               : ", convergence_info$note
  )

  plot(convergence_info$convergence_plot)
}


#----------------------------------------------------------#
# 5. Species-level evaluation -----
#----------------------------------------------------------#

if (
  !is.null(model_evaluation)
) {
  data_species_eval <-
    model_evaluation |>
    purrr::chuck("species")

  n_species <- nrow(data_species_eval)

  message(n_species, " species evaluated.")

  # Top 10 by AUC
  message("\nTop 10 species (highest AUC):")
  data_species_eval |>
    dplyr::arrange(dplyr::desc(AUC)) |>
    dplyr::slice_head(n = 10L) |>
    print()

  # Bottom 10 by AUC
  message("\nBottom 10 species (lowest AUC):")
  data_species_eval |>
    dplyr::arrange(AUC) |>
    dplyr::slice_head(n = 10L) |>
    print()
}


#----------------------------------------------------------#
# 6. ANOVA variance partition detail -----
#----------------------------------------------------------#

model_anova <-
  purrr::possibly(
    ~ targets::tar_read(
      "model_anova",
      store = sel_store_path
    ),
    otherwise = NULL
  )()

if (
  is.null(model_anova)
) {
  message("Target 'model_anova' not available.")
} else {
  data_anova_fractions <-
    extract_anova_fractions(
      anova_object = model_anova,
      clamp_negative = TRUE
    ) |>
    dplyr::mutate(age = 0) |>
    recalculate_anova_components() |>
    dplyr::arrange(dplyr::desc(R2_Nagelkerke_percentage))

  message("ANOVA fractions for: ", sel_scale_id)
  print(data_anova_fractions)

  # Bar chart of component percentages
  plot_anova_bar <-
    data_anova_fractions |>
    dplyr::mutate(
      component = forcats::fct_reorder(
        component,
        R2_Nagelkerke_percentage
      )
    ) |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = component,
        y = R2_Nagelkerke_percentage,
        fill = component
      )
    ) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(scale = 1),
      limits = c(0, 100)
    ) +
    ggplot2::labs(
      title = paste0("Variance partition — ", sel_scale_id),
      x = NULL,
      y = expression(
        "Percentage of variance explained" ~
          "(" ~ R^2 ~ "Nagelkerke)"
      )
    ) +
    ggplot2::theme_minimal() +
    ggview::canvas(
      width = graphical_options[["width"]],
      height = graphical_options[["height"]],
      units = graphical_options[["units"]],
      dpi = graphical_options[["dpi"]],
      bg = graphical_options[["bg"]]
    )

  plot(plot_anova_bar)
}

#' @title Summarise Fossil-Core Age Iterations
#' @description
#' Interpolates bounded batches of fossil age-model iterations and returns
#' median community proportions across all iterations.
#' @param dataset_name
#' Fossil-core dataset identifier.
#' @param data_community
#' Nested community proportions for one fossil core.
#' @param data_age_uncertainty
#' Nested age-model iteration records for the same fossil core.
#' @param max_expanded_rows
#' Maximum approximate expanded observation rows processed per batch.
#' @param list_interpolation_arguments
#' Additional arguments forwarded to [interpolate_grouped_time_series()].
#' @param interpolate_grouped_time_series_function
#' Grouped interpolation function supplied explicitly for dependency-safe
#' execution inside a dynamic target branch.
#' @return
#' Median interpolated proportions by dataset, taxon, and age.
#' @keywords internal
.summarise_fossil_core_age_iterations <- function(
    dataset_name,
    data_community,
    data_age_uncertainty,
    max_expanded_rows,
    list_interpolation_arguments,
    interpolate_grouped_time_series_function) {
  n_iterations_per_batch <-
    base::max(
      1L,
      base::as.integer(
        max_expanded_rows /
          base::nrow(data_community)
      )
    )

  vec_iterations <-
    data_age_uncertainty |>
    dplyr::pull(iteration) |>
    base::unique()

  list_iteration_batches <-
    vec_iterations |>
    base::split(
      base::ceiling(
        base::seq_along(vec_iterations) /
          n_iterations_per_batch
      )
    )

  data_community_interpolated <-
    list_iteration_batches |>
    purrr::map(
      .f = .interpolate_fossil_age_iteration_batch,
      dataset_name = dataset_name,
      data_community = data_community,
      data_age_uncertainty = data_age_uncertainty,
      list_interpolation_arguments = list_interpolation_arguments,
      interpolate_grouped_time_series_function =
        interpolate_grouped_time_series_function
    ) |>
    purrr::list_rbind()

  data_community_summarised <-
    data_community_interpolated |>
    dplyr::summarise(
      value = stats::median(value, na.rm = TRUE),
      .by = dplyr::all_of(
        base::c("dataset_name", "taxon", "age")
      )
    ) |>
    dplyr::filter(!base::is.na(value))

  base::return(data_community_summarised)
}

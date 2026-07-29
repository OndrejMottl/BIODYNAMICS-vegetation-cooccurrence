#' @title Interpolate One Fossil Age-Iteration Batch
#' @description
#' Expands one fossil community dataset across selected age-model iterations
#' and interpolates each taxon-iteration series on a shared age grid.
#' @param vec_iterations
#' Integer age-model iterations included in the batch.
#' @param dataset_name
#' Dataset identifier restored after joining the nested community records.
#' @param data_community
#' Nested community proportions with `sample_name`, `taxon`, and `value`.
#' @param data_age_uncertainty
#' Nested age-model records with `sample_name`, `iteration`, and
#' `age_uncertainty`.
#' @param list_interpolation_arguments
#' Additional arguments forwarded to [interpolate_grouped_time_series()].
#' @param interpolate_grouped_time_series_function
#' Grouped interpolation function supplied explicitly for dependency-safe
#' execution inside a dynamic target branch.
#' @return
#' Interpolated community proportions for every selected age-model iteration.
#' @keywords internal
.interpolate_fossil_age_iteration_batch <- function(
    vec_iterations,
    dataset_name,
    data_community,
    data_age_uncertainty,
    list_interpolation_arguments,
    interpolate_grouped_time_series_function) {
  data_community_expanded <-
    data_community |>
    dplyr::inner_join(
      data_age_uncertainty |>
        dplyr::filter(iteration %in% vec_iterations),
      by = dplyr::join_by(sample_name),
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(dataset_name = .env[["dataset_name"]]) |>
    dplyr::rename(age = age_uncertainty) |>
    dplyr::filter(!base::is.na(age))

  data_community_interpolated <-
    rlang::exec(
      .fn = interpolate_grouped_time_series_function,
      data_time_series = data_community_expanded,
      !!!list_interpolation_arguments,
      grouping_variables = base::c(
        "dataset_name", "taxon", "iteration"
      ),
      n_cores = 1L
    )

  base::return(data_community_interpolated)
}

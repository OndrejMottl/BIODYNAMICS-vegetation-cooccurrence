#' @title Get Decomposition Route Sample IDs
#' @description
#' Selects sample IDs for one decomposition diagnostic route.
#' @param route
#' One-row route data frame or named list from
#' `make_decomposition_diagnostic_routes()`.
#' @param inputs
#' List returned by `load_decomposition_diagnostic_inputs()`.
#' @return
#' Data frame with `dataset_name`, `age`, and `.row_name`.
#' @export
get_decomposition_route_sample_ids <- function(
    route = NULL,
    inputs = NULL) {
  assertthat::assert_that(
    base::is.data.frame(route) || base::is.list(route),
    msg = "`route` must be a one-row data frame or named list."
  )

  assertthat::assert_that(
    base::is.list(inputs),
    msg = "`inputs` must be a list."
  )

  vec_required_inputs <-
    c(
      "data_sample_ids",
      "data_community_matrix",
      "config_model_fitting",
      "config_data_processing"
    )

  assertthat::assert_that(
    base::all(vec_required_inputs %in% base::names(inputs)),
    msg = "`inputs` is missing required diagnostic elements."
  )

  sample_mode <-
    route[["sample_mode"]][[1L]]

  data_sample_ids <-
    inputs |>
    purrr::chuck("data_sample_ids") |>
    dplyr::mutate(
      .row_name = stringr::str_glue("{.data$dataset_name}__{.data$age}")
    ) |>
    dplyr::arrange(.data$dataset_name, .data$age)

  if (
    sample_mode == "pooled"
  ) {
    return(data_sample_ids)
  }

  if (
    sample_mode != "temporal_best_slice"
  ) {
    cli::cli_abort(
      stringr::str_glue("Unknown sample mode: {sample_mode}.")
    )
  }

  data_community_matrix <-
    inputs |>
    purrr::chuck("data_community_matrix")

  config_model_fitting <-
    inputs |>
    purrr::chuck("config_model_fitting")

  config_data_processing <-
    inputs |>
    purrr::chuck("config_data_processing")

  error_family <-
    config_model_fitting[["error_family"]]

  min_n_taxa <-
    config_data_processing[["min_n_taxa"]]

  data_age_scores <-
    data_sample_ids |>
    dplyr::group_by(.data$age) |>
    dplyr::group_split() |>
    purrr::map(
      .f = ~ {
        data_age_sample_ids <-
          .x

        vec_row_names <-
          data_age_sample_ids |>
          dplyr::pull(.data$.row_name)

        data_community_age <-
          data_community_matrix[
            vec_row_names,
            ,
            drop = FALSE
          ]

        data_community_prepared <-
          if (
            error_family == "binomial"
          ) {
            binarize_community_data(
              data_community_matrix = data_community_age
            )
          } else {
            data_community_age
          }

        data_community_filtered <-
          filter_constant_taxa(
            data_community_matrix = data_community_prepared
          )

        tibble::tibble(
          age = data_age_sample_ids[["age"]][[1L]],
          n_samples = base::nrow(data_age_sample_ids),
          n_taxa = base::ncol(data_community_filtered),
          valid = base::ncol(data_community_filtered) >= min_n_taxa
        )
      }
    ) |>
    purrr::list_rbind()

  data_best_age <-
    data_age_scores |>
    dplyr::filter(.data$valid) |>
    dplyr::arrange(
      dplyr::desc(.data$n_samples),
      dplyr::desc(.data$n_taxa),
      .data$age
    ) |>
    dplyr::slice(1L)

  if (
    base::nrow(data_best_age) == 0L
  ) {
    cli::cli_abort("No valid temporal diagnostic age slice was found.")
  }

  best_age <-
    data_best_age[["age"]][[1L]]

  res <-
    data_sample_ids |>
    dplyr::filter(.data$age == .env$best_age)

  return(res)
}

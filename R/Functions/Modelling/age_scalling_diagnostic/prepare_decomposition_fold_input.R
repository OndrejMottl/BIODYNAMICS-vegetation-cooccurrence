#' @title Prepare Decomposition Fold Input
#' @description
#' Rebuilds model input for one route and one train/test split using
#' fold-local response filtering and train-only predictor scaling.
#' @param route
#' One-row route data frame or named list.
#' @param inputs
#' List returned by `load_decomposition_diagnostic_inputs()`.
#' @param train_ids
#' Character vector of training sample row names.
#' @param test_ids
#' Character vector of test sample row names.
#' @return
#' Named list with training input, test input, test observations, and
#' fold diagnostics.
#' @export
prepare_decomposition_fold_input <- function(
    route = NULL,
    inputs = NULL,
    train_ids = NULL,
    test_ids = NULL) {
  assertthat::assert_that(
    base::is.data.frame(route) || base::is.list(route),
    msg = "`route` must be a one-row data frame or named list."
  )

  assertthat::assert_that(
    base::is.list(inputs),
    msg = "`inputs` must be a list."
  )

  assertthat::assert_that(
    base::is.character(train_ids),
    base::length(train_ids) > 0L,
    msg = "`train_ids` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(test_ids),
    base::length(test_ids) > 0L,
    msg = "`test_ids` must be a non-empty character vector."
  )

  spatial_mode <-
    route[["spatial_mode"]][[1L]]

  age_scale_mode <-
    if (
      "age_scale_mode" %in% base::names(route)
    ) {
      route[["age_scale_mode"]][[1L]]
    } else {
      "center"
    }

  assertthat::assert_that(
    age_scale_mode %in% c("center", "z_score"),
    msg = "`age_scale_mode` must be either 'center' or 'z_score'."
  )

  data_sample_ids_route <-
    get_decomposition_route_sample_ids(
      route = route,
      inputs = inputs
    )

  data_community_matrix <-
    inputs |>
    purrr::chuck("data_community_matrix")

  data_abiotic_wide <-
    inputs |>
    purrr::chuck("data_abiotic_wide")

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

  make_abiotic_raw <- function(vec_row_names) {
    data_abiotic_wide |>
      dplyr::mutate(
        .row_name = stringr::str_c(
          .data$dataset_name,
          "__",
          .data$age
        )
      ) |>
      dplyr::filter(.data$.row_name %in% .env$vec_row_names) |>
      dplyr::arrange(.data$dataset_name, .data$age) |>
      tidyr::drop_na() |>
      dplyr::select(-"dataset_name") |>
      tibble::column_to_rownames(".row_name")
  }

  make_spatial_raw <- function() {
    if (
      spatial_mode == "spatial"
    ) {
      data_spatial_mev_core <-
        inputs[["data_spatial_mev_core"]]

      if (
        base::is.null(data_spatial_mev_core)
      ) {
        data_spatial_mev_core <-
          compute_spatial_mev(
            data_coords_projected = inputs[["data_coords_projected"]],
            n_mev = inputs[["config_spatial_predictors"]][["n_mev"]]
          )
      }

      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial_mev_core,
        data_sample_ids = data_sample_ids_route
      )
    } else if (
      spatial_mode == "spatiotemporal"
    ) {
      compute_spatiotemporal_mev(
        data_coords_projected = inputs[["data_coords_projected"]],
        data_sample_ids = data_sample_ids_route,
        n_mev = inputs[["config_spatial_predictors"]][["n_mev"]]
      )
    } else {
      cli::cli_abort(
        stringr::str_glue("Unknown spatial mode: {spatial_mode}.")
      )
    }
  }

  data_community_train <-
    data_community_matrix[
      train_ids,
      ,
      drop = FALSE
    ]

  data_community_test <-
    data_community_matrix[
      test_ids,
      ,
      drop = FALSE
    ]

  data_community_train_prepared <-
    if (
      error_family == "binomial"
    ) {
      binarize_community_data(
        data_community_matrix = data_community_train
      )
    } else {
      data_community_train
    }

  data_community_test_prepared <-
    if (
      error_family == "binomial"
    ) {
      binarize_community_data(
        data_community_matrix = data_community_test
      )
    } else {
      data_community_test
    }

  data_abiotic_train_raw <-
    make_abiotic_raw(vec_row_names = train_ids)

  data_abiotic_scaled_list_train <-
    scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_train_raw |>
        tibble::rownames_to_column(".row_name") |>
        tidyr::separate_wider_delim(
          cols = ".row_name",
          delim = "__",
          names = c("dataset_name", ".age_row")
        ) |>
        dplyr::select(-".age_row")
    )

  data_abiotic_train_scaled <-
    data_abiotic_scaled_list_train |>
    purrr::chuck("data_abiotic_scaled")

  data_abiotic_test_raw <-
    make_abiotic_raw(vec_row_names = test_ids)

  data_abiotic_test_scaled <-
    apply_decomposition_scale_attributes(
      data_predictors = data_abiotic_test_raw,
      scale_attributes = data_abiotic_scaled_list_train[[
        "scale_attributes"
      ]]
    )

  age_scale_value <-
    NA_real_

  if (
    age_scale_mode == "z_score" &&
      "age" %in% base::colnames(data_abiotic_train_scaled)
  ) {
    age_scale_value <-
      stats::sd(data_abiotic_train_scaled[["age"]], na.rm = TRUE)

    if (
      !base::is.finite(age_scale_value) ||
        age_scale_value == 0
    ) {
      cli::cli_abort(
        "`age_scale_mode = 'z_score'` requires variable training age."
      )
    }

    data_abiotic_train_scaled[["age"]] <-
      data_abiotic_train_scaled[["age"]] / age_scale_value

    data_abiotic_test_scaled[["age"]] <-
      data_abiotic_test_scaled[["age"]] / age_scale_value

    data_abiotic_scaled_list_train[[
      "scale_attributes"
    ]][["age"]][["scaled:scale"]] <-
      age_scale_value
  }

  data_spatial_raw <-
    make_spatial_raw()

  data_spatial_train_raw <-
    data_spatial_raw[
      train_ids,
      ,
      drop = FALSE
    ]

  data_spatial_test_raw <-
    data_spatial_raw[
      test_ids,
      ,
      drop = FALSE
    ]

  data_spatial_scaled_list_train <-
    scale_spatial_for_fit(data_spatial = data_spatial_train_raw)

  data_spatial_train_scaled <-
    data_spatial_scaled_list_train |>
    purrr::chuck("data_spatial_scaled")

  data_spatial_test_scaled <-
    apply_decomposition_scale_attributes(
      data_predictors = data_spatial_test_raw,
      scale_attributes = data_spatial_scaled_list_train[[
        "spatial_scale_attributes"
      ]]
    )

  vec_train_common_ids <-
    base::list(
      base::rownames(data_community_train_prepared),
      base::rownames(data_abiotic_train_scaled),
      base::rownames(data_spatial_train_scaled)
    ) |>
    purrr::reduce(.f = base::intersect)

  vec_train_common_ids <-
    train_ids[train_ids %in% vec_train_common_ids]

  if (
    base::length(vec_train_common_ids) == 0L
  ) {
    cli::cli_abort("No training rows remain after fold preparation.")
  }

  data_community_train_aligned <-
    data_community_train_prepared[
      vec_train_common_ids,
      ,
      drop = FALSE
    ]

  data_community_train_filtered <-
    filter_constant_taxa(
      data_community_matrix = data_community_train_aligned
    )

  data_community_train_checked <-
    filter_community_by_n_taxa(
      data_community_matrix = data_community_train_filtered,
      min_n_taxa = min_n_taxa
    )

  vec_retained_taxa <-
    base::colnames(data_community_train_checked)

  vec_test_common_ids <-
    base::list(
      base::rownames(data_community_test_prepared),
      base::rownames(data_abiotic_test_scaled),
      base::rownames(data_spatial_test_scaled)
    ) |>
    purrr::reduce(.f = base::intersect)

  vec_test_common_ids <-
    test_ids[test_ids %in% vec_test_common_ids]

  if (
    base::length(vec_test_common_ids) == 0L
  ) {
    cli::cli_abort("No test rows remain after fold preparation.")
  }

  data_community_test_aligned <-
    data_community_test_prepared[
      vec_test_common_ids,
      vec_retained_taxa,
      drop = FALSE
    ]

  data_abiotic_scaled_list_aligned <-
    base::list(
      data_abiotic_scaled = data_abiotic_train_scaled[
        vec_train_common_ids,
        ,
        drop = FALSE
      ],
      scale_attributes = data_abiotic_scaled_list_train[[
        "scale_attributes"
      ]]
    )

  data_spatial_scaled_list_aligned <-
    base::list(
      data_spatial_scaled = data_spatial_train_scaled[
        vec_train_common_ids,
        ,
        drop = FALSE
      ],
      spatial_scale_attributes = data_spatial_scaled_list_train[[
        "spatial_scale_attributes"
      ]]
    )

  data_train_input <-
    assemble_data_to_fit(
      data_community_filtered = data_community_train_checked,
      data_abiotic_scaled_list = data_abiotic_scaled_list_aligned,
      data_spatial_scaled_list = data_spatial_scaled_list_aligned
    )

  data_test_input <-
    base::list(
      data_abiotic_to_fit = data_abiotic_test_scaled[
        vec_test_common_ids,
        ,
        drop = FALSE
      ],
      data_spatial_to_fit = data_spatial_test_scaled[
        vec_test_common_ids,
        ,
        drop = FALSE
      ]
    )

  n_taxa_raw <-
    base::ncol(data_community_train_prepared)

  n_taxa_retained <-
    base::length(vec_retained_taxa)

  data_diagnostics <-
    tibble::tibble(
      n_train_samples = base::nrow(data_community_train_checked),
      n_test_samples = base::nrow(data_community_test_aligned),
      n_taxa_raw = n_taxa_raw,
      n_taxa_retained = n_taxa_retained,
      n_taxa_dropped = n_taxa_raw - n_taxa_retained,
      age_scale_mode = age_scale_mode,
      age_scale_value = age_scale_value
    )

  res <-
    base::list(
      data_train_input = data_train_input,
      data_test_input = data_test_input,
      data_test_observed = data_community_test_aligned,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

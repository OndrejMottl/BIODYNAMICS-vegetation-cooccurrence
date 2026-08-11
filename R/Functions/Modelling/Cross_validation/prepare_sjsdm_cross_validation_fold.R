#' @title Prepare One sjSDM Cross-Validation Fold
#' @description
#' Converts location-assignment row indices to sample identifiers, rebuilds
#' fold-local spatial predictors when needed, and prepares train/test model
#' inputs with training-only response filtering and predictor scaling.
#' @param data_community_matrix
#' Raw community matrix with sample identifiers as row names.
#' @param data_abiotic_wide
#' Wide abiotic data frame with `dataset_name`, `age`, and predictors.
#' @param data_coords_projected
#' Projected coordinates used for fold-local MEM construction.
#' @param data_sample_ids
#' Sample metadata containing `dataset_name` and `age`. Optional `sample_id`,
#' `row_index`, and `location_id` columns are derived when absent.
#' @param train_indices,test_indices
#' Integer row indices defining the fold training and held-out samples.
#' @param config_model_fitting,config_data_processing
#' Active project configuration lists.
#' @param repeat_id,fold_id
#' Fold identifiers. They are accepted for runner compatibility and retained
#' by downstream diagnostics.
#' @param compute_spatial_function,compute_spatiotemporal_function
#' Functions used by [prepare_fold_spatial_predictors()] to build MEMs.
#' @param interpolate_spatial_function,interpolate_spatiotemporal_function
#' Functions used by [prepare_fold_spatial_predictors()] to project MEMs.
#' @return
#' Named list returned by [prepare_model_fold_input()], with optional
#' `data_spatial_diagnostics` when spatial predictors are enabled.
#' @details
#' This helper is the production adapter between location-level CV assignment
#' tables and the generic fold-local preparation functions shared with
#' decomposition diagnostics.
#' @export
prepare_sjsdm_cross_validation_fold <- function(
    data_community_matrix = NULL,
    data_abiotic_wide = NULL,
    data_coords_projected = NULL,
    data_sample_ids = NULL,
    train_indices = NULL,
    test_indices = NULL,
    config_model_fitting = NULL,
    config_data_processing = NULL,
    repeat_id = NULL,
    fold_id = NULL,
    compute_spatial_function = compute_spatial_mev,
    compute_spatiotemporal_function = compute_spatiotemporal_mev,
    interpolate_spatial_function = interpolate_mev_to_grid,
    interpolate_spatiotemporal_function = interpolate_st_mev_to_grid) {
  assertthat::assert_that(
    base::is.data.frame(data_sample_ids),
    base::all(
      base::c(
        "dataset_name",
        "age"
      ) %in% base::colnames(data_sample_ids)
    ),
    msg = "`data_sample_ids` must contain `dataset_name` and `age`."
  )

  vec_sample_id <-
    if (
      "sample_id" %in% base::colnames(data_sample_ids)
    ) {
      base::as.character(data_sample_ids[["sample_id"]])
    } else {
      stringr::str_c(
        data_sample_ids[["dataset_name"]],
        "__",
        data_sample_ids[["age"]]
      )
    }

  vec_row_index <-
    if (
      "row_index" %in% base::colnames(data_sample_ids)
    ) {
      base::as.integer(data_sample_ids[["row_index"]])
    } else {
      base::seq_len(base::nrow(data_sample_ids))
    }

  vec_location_id <-
    if (
      "location_id" %in% base::colnames(data_sample_ids)
    ) {
      base::as.character(data_sample_ids[["location_id"]])
    } else {
      base::as.character(data_sample_ids[["dataset_name"]])
    }

  data_sample_ids_normalized <-
    data_sample_ids |>
    dplyr::mutate(
      sample_id = .env[["vec_sample_id"]],
      row_index = .env[["vec_row_index"]],
      location_id = .env[["vec_location_id"]]
    )

  assertthat::assert_that(
    base::is.character(data_sample_ids_normalized[["sample_id"]]),
    !base::any(base::is.na(data_sample_ids_normalized[["sample_id"]])),
    !base::any(base::duplicated(data_sample_ids_normalized[["sample_id"]])),
    base::is.numeric(data_sample_ids_normalized[["row_index"]]),
    !base::any(base::duplicated(data_sample_ids_normalized[["row_index"]])),
    msg = "Derived sample and row identifiers must be unique."
  )

  assertthat::assert_that(
    base::is.list(config_model_fitting),
    base::is.list(config_data_processing),
    msg = "Model and data-processing configuration must be lists."
  )

  assertthat::assert_that(
    base::is.numeric(train_indices),
    base::is.numeric(test_indices),
    base::length(train_indices) > 0L,
    base::length(test_indices) > 0L,
    msg = "Train and test indices must be non-empty numeric vectors."
  )

  train_indices_integer <-
    base::as.integer(train_indices)

  test_indices_integer <-
    base::as.integer(test_indices)

  assertthat::assert_that(
    base::all(train_indices == train_indices_integer),
    base::all(test_indices == test_indices_integer),
    base::length(
      base::intersect(train_indices_integer, test_indices_integer)
    ) == 0L,
    msg = "Train and test row indices must be disjoint integers."
  )

  data_train_samples <-
    prepare_ordered_fold_partition(
      data_partition_source = data_sample_ids_normalized,
      partition_ids = train_indices_integer,
      id_column = "row_index"
    )

  data_test_samples <-
    prepare_ordered_fold_partition(
      data_partition_source = data_sample_ids_normalized,
      partition_ids = test_indices_integer,
      id_column = "row_index"
    )

  if (
    base::nrow(data_train_samples) !=
      base::length(train_indices_integer) ||
      base::nrow(data_test_samples) !=
      base::length(test_indices_integer)
  ) {
    cli::cli_abort("Every fold row index must have sample metadata.")
  }

  vec_train_ids <-
    data_train_samples |>
    dplyr::pull("sample_id")

  vec_test_ids <-
    data_test_samples |>
    dplyr::pull("sample_id")

  flag_use_spatial <-
    config_model_fitting[["use_spatial"]] |>
    base::isTRUE()

  list_spatial_fold <-
    if (
      flag_use_spatial
    ) {
      prepare_fold_spatial_predictors(
        data_coords_projected = data_coords_projected,
        data_sample_ids = data_sample_ids_normalized,
        train_ids = vec_train_ids,
        test_ids = vec_test_ids,
        spatial_mode = config_model_fitting[["spatial_mode"]],
        n_mev = config_model_fitting[["n_mev"]],
        spatial_mev_config = config_model_fitting[["spatial_mev"]],
        compute_spatial_function = compute_spatial_function,
        compute_spatiotemporal_function = compute_spatiotemporal_function,
        interpolate_spatial_function = interpolate_spatial_function,
        interpolate_spatiotemporal_function =
          interpolate_spatiotemporal_function
      )
    } else {
      base::list(
        data_spatial_train = NULL,
        data_spatial_test = NULL,
        data_diagnostics = NULL
      )
    }

  age_scale_mode <-
    config_model_fitting[["age_scale_mode"]]

  if (
    base::is.null(age_scale_mode)
  ) {
    age_scale_mode <- "z_score"
  }

  res_model_input <-
    prepare_model_fold_input(
      data_community_matrix = data_community_matrix,
      data_abiotic_wide = data_abiotic_wide,
      data_spatial_train = list_spatial_fold[["data_spatial_train"]],
      data_spatial_test = list_spatial_fold[["data_spatial_test"]],
      train_ids = vec_train_ids,
      test_ids = vec_test_ids,
      error_family = config_model_fitting[["error_family"]],
      minimum_taxon_count = config_data_processing[["min_n_taxa"]],
      age_scale_mode = age_scale_mode
    )

  res <-
    if (
      flag_use_spatial
    ) {
      base::c(
        res_model_input,
        base::list(
          data_spatial_diagnostics =
            list_spatial_fold[["data_diagnostics"]],
          data_spatial_provenance =
            list_spatial_fold[["data_provenance"]]
        )
      )
    } else {
      res_model_input
    }

  return(res)
}

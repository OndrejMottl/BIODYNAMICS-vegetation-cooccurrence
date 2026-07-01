#' @title Prepare Train and Test Model Inputs for One Fold
#' @description
#' Prepares one model fold without using held-out responses or predictors to
#' learn taxon filtering or predictor scaling. Spatial predictors must already
#' represent the training-only construction and held-out projection paths.
#' @param data_community_matrix
#' Numeric community matrix with named sample rows and taxon columns.
#' @param data_abiotic_wide
#' Wide abiotic data frame with `dataset_name`, `age`, and predictor columns.
#' @param data_spatial_train,data_spatial_test
#' Optional raw spatial predictor data frames for training and test samples.
#' Both must be supplied together and have sample identifiers as row names.
#' @param train_ids,test_ids
#' Disjoint character vectors of training and test sample identifiers.
#' @param error_family
#' Character scalar naming the model error family. Binomial responses are
#' converted to presence-absence before training-only taxon filtering.
#' @param min_n_taxa
#' Positive integer giving the minimum retained training taxa.
#' @param age_scale_mode
#' Character scalar passed to `scale_abiotic_for_fit()`. Supported values are
#' `"z_score"` and `"center"`.
#' @return
#' Named list containing assembled training input, scaled test predictors,
#' aligned test observations, an explicit taxon mapping, and fold diagnostics.
#' Diagnostics record requested and aligned row counts, missing abiotic and
#' spatial predictor rows, exact-alignment flags, and retained/dropped taxa.
#' @examples
#' data_community <-
#'   base::matrix(
#'     base::c(0, 1, 0, 1),
#'     ncol = 1,
#'     dimnames = base::list(
#'       base::c("a__0", "b__0", "c__0", "d__0"),
#'       "taxon_a"
#'     )
#'   )
#' data_abiotic <-
#'   base::data.frame(
#'     dataset_name = base::c("a", "b", "c", "d"),
#'     age = 0,
#'     temperature = base::c(8, 10, 12, 14)
#'   )
#' prepare_model_fold_input(
#'   data_community_matrix = data_community,
#'   data_abiotic_wide = data_abiotic,
#'   train_ids = base::c("a__0", "b__0", "c__0"),
#'   test_ids = "d__0",
#'   error_family = "binomial",
#'   min_n_taxa = 1L,
#'   age_scale_mode = "center"
#' )
#' @export
prepare_model_fold_input <- function(
    data_community_matrix = NULL,
    data_abiotic_wide = NULL,
    data_spatial_train = NULL,
    data_spatial_test = NULL,
    train_ids = NULL,
    test_ids = NULL,
    error_family = NULL,
    min_n_taxa = NULL,
    age_scale_mode = "z_score") {
  assertthat::assert_that(
    base::is.matrix(data_community_matrix),
    base::is.numeric(data_community_matrix),
    msg = "`data_community_matrix` must be a numeric matrix."
  )

  assertthat::assert_that(
    !base::is.null(base::rownames(data_community_matrix)),
    !base::is.null(base::colnames(data_community_matrix)),
    !base::anyDuplicated(base::rownames(data_community_matrix)),
    !base::anyDuplicated(base::colnames(data_community_matrix)),
    msg = "`data_community_matrix` must have unique row and taxon names."
  )

  assertthat::assert_that(
    base::is.data.frame(data_abiotic_wide),
    base::all(
      base::c("dataset_name", "age") %in%
        base::colnames(data_abiotic_wide)
    ),
    msg = "`data_abiotic_wide` must contain `dataset_name` and `age`."
  )

  assertthat::assert_that(
    base::is.character(train_ids),
    base::length(train_ids) > 0L,
    !base::anyDuplicated(train_ids),
    msg = "`train_ids` must be a non-empty unique character vector."
  )

  assertthat::assert_that(
    base::is.character(test_ids),
    base::length(test_ids) > 0L,
    !base::anyDuplicated(test_ids),
    msg = "`test_ids` must be a non-empty unique character vector."
  )

  assertthat::assert_that(
    base::length(base::intersect(train_ids, test_ids)) == 0L,
    msg = "`train_ids` and `test_ids` must be disjoint."
  )

  vec_partition_ids <-
    base::c(train_ids, test_ids)

  assertthat::assert_that(
    base::all(
      vec_partition_ids %in% base::rownames(data_community_matrix)
    ),
    msg = "Every fold sample must occur in `data_community_matrix`."
  )

  assertthat::assert_that(
    base::is.character(error_family),
    base::length(error_family) == 1L,
    !base::is.na(error_family),
    msg = "`error_family` must be one non-missing character value."
  )

  assertthat::assert_that(
    base::is.numeric(min_n_taxa),
    base::length(min_n_taxa) == 1L,
    base::is.finite(min_n_taxa),
    min_n_taxa >= 1,
    min_n_taxa == base::as.integer(min_n_taxa),
    msg = "`min_n_taxa` must be one finite positive number."
  )

  assertthat::assert_that(
    base::is.character(age_scale_mode),
    base::length(age_scale_mode) == 1L,
    age_scale_mode %in% base::c("z_score", "center"),
    msg = "`age_scale_mode` must be either 'z_score' or 'center'."
  )

  flag_has_spatial_train <-
    !base::is.null(data_spatial_train)

  flag_has_spatial_test <-
    !base::is.null(data_spatial_test)

  assertthat::assert_that(
    base::identical(flag_has_spatial_train, flag_has_spatial_test),
    msg = "Training and test spatial predictors must be supplied together."
  )

  if (
    flag_has_spatial_train
  ) {
    assertthat::assert_that(
      base::is.data.frame(data_spatial_train),
      base::is.data.frame(data_spatial_test),
      msg = "Spatial predictors must be data frames."
    )

    assertthat::assert_that(
      !base::is.null(base::rownames(data_spatial_train)),
      !base::is.null(base::rownames(data_spatial_test)),
      msg = "Spatial predictors must have sample row names."
    )
  }

  data_abiotic_identified <-
    data_abiotic_wide |>
    dplyr::mutate(
      .row_name = stringr::str_c(
        .data[["dataset_name"]],
        "__",
        .data[["age"]]
      )
    )

  if (
    base::anyDuplicated(dplyr::pull(data_abiotic_identified, .row_name))
  ) {
    cli::cli_abort("Abiotic sample identifiers must be unique.")
  }

  make_abiotic_partition <- function(vec_ids) {
    res_partition <-
      data_abiotic_identified |>
      dplyr::filter(.data[[".row_name"]] %in% .env[["vec_ids"]]) |>
      dplyr::mutate(
        .fold_order = base::match(
          .data[[".row_name"]],
          .env[["vec_ids"]]
        )
      ) |>
      dplyr::arrange(.data[[".fold_order"]]) |>
      dplyr::select(-".fold_order") |>
      tidyr::drop_na()

    return(res_partition)
  }

  data_abiotic_train_identified <-
    make_abiotic_partition(vec_ids = train_ids)

  data_abiotic_test_identified <-
    make_abiotic_partition(vec_ids = test_ids)

  vec_abiotic_train_ids <-
    dplyr::pull(data_abiotic_train_identified, .row_name)

  vec_abiotic_test_ids <-
    dplyr::pull(data_abiotic_test_identified, .row_name)

  n_train_missing_abiotic <-
    base::length(base::setdiff(train_ids, vec_abiotic_train_ids))

  n_test_missing_abiotic <-
    base::length(base::setdiff(test_ids, vec_abiotic_test_ids))

  n_train_missing_spatial <-
    if (
      flag_has_spatial_train
    ) {
      base::length(
        base::setdiff(train_ids, base::rownames(data_spatial_train))
      )
    } else {
      0L
    }

  n_test_missing_spatial <-
    if (
      flag_has_spatial_train
    ) {
      base::length(
        base::setdiff(test_ids, base::rownames(data_spatial_test))
      )
    } else {
      0L
    }

  vec_train_alignment_sets_base <-
    base::list(
      base::rownames(data_community_matrix),
      dplyr::pull(data_abiotic_train_identified, .row_name)
    )

  vec_test_alignment_sets_base <-
    base::list(
      base::rownames(data_community_matrix),
      dplyr::pull(data_abiotic_test_identified, .row_name)
    )

  vec_train_alignment_sets <-
    if (
      flag_has_spatial_train
    ) {
      base::c(
        vec_train_alignment_sets_base,
        base::list(base::rownames(data_spatial_train))
      )
    } else {
      vec_train_alignment_sets_base
    }

  vec_test_alignment_sets <-
    if (
      flag_has_spatial_train
    ) {
      base::c(
        vec_test_alignment_sets_base,
        base::list(base::rownames(data_spatial_test))
      )
    } else {
      vec_test_alignment_sets_base
    }

  vec_train_common_ids_unordered <-
    vec_train_alignment_sets |>
    purrr::reduce(.f = base::intersect)

  vec_test_common_ids_unordered <-
    vec_test_alignment_sets |>
    purrr::reduce(.f = base::intersect)

  vec_train_common_ids <-
    train_ids[train_ids %in% vec_train_common_ids_unordered]

  vec_test_common_ids <-
    test_ids[test_ids %in% vec_test_common_ids_unordered]

  n_train_dropped_alignment <-
    base::length(train_ids) - base::length(vec_train_common_ids)

  n_test_dropped_alignment <-
    base::length(test_ids) - base::length(vec_test_common_ids)

  train_alignment_exact <-
    base::identical(vec_train_common_ids, train_ids)

  test_alignment_exact <-
    base::identical(vec_test_common_ids, test_ids)

  if (
    base::length(vec_train_common_ids) == 0L
  ) {
    cli::cli_abort("No training rows remain after fold alignment.")
  }

  if (
    base::length(vec_test_common_ids) == 0L
  ) {
    cli::cli_abort("No test rows remain after fold alignment.")
  }

  data_community_train_raw <-
    data_community_matrix[
      vec_train_common_ids,
      ,
      drop = FALSE
    ]

  data_community_test_raw <-
    data_community_matrix[
      vec_test_common_ids,
      ,
      drop = FALSE
    ]

  data_community_train_prepared <-
    if (
      error_family == "binomial"
    ) {
      binarize_community_data(
        data_community_matrix = data_community_train_raw
      )
    } else {
      data_community_train_raw
    }

  data_community_test_prepared <-
    if (
      error_family == "binomial"
    ) {
      binarize_community_data(
        data_community_matrix = data_community_test_raw
      )
    } else {
      data_community_test_raw
    }

  data_community_train_variable <-
    filter_constant_taxa(
      data_community_matrix = data_community_train_prepared
    )

  data_community_train_checked <-
    filter_community_by_n_taxa(
      data_community_matrix = data_community_train_variable,
      min_n_taxa = min_n_taxa
    )

  vec_taxa_full <-
    base::colnames(data_community_train_prepared)

  vec_taxa_retained <-
    base::colnames(data_community_train_checked)

  vec_taxa_retained_index <-
    base::match(vec_taxa_full, vec_taxa_retained)

  vec_taxa_retained_flag <-
    !base::is.na(vec_taxa_retained_index)

  data_taxa_mapping <-
    tibble::tibble(
      taxon = vec_taxa_full,
      taxon_index_full = base::seq_along(vec_taxa_full),
      taxon_index_retained = base::as.integer(vec_taxa_retained_index),
      retained = vec_taxa_retained_flag,
      status = dplyr::if_else(
        vec_taxa_retained_flag,
        "retained",
        "constant_in_training"
      )
    )

  data_community_test_aligned <-
    data_community_test_prepared[
      vec_test_common_ids,
      vec_taxa_retained,
      drop = FALSE
    ]

  data_abiotic_train_wide <-
    data_abiotic_train_identified |>
    dplyr::filter(
      .data[[".row_name"]] %in% .env[["vec_train_common_ids"]]
    ) |>
    dplyr::mutate(
      .fold_order = base::match(
        .data[[".row_name"]],
        .env[["vec_train_common_ids"]]
      )
    ) |>
    dplyr::arrange(.data[[".fold_order"]]) |>
    dplyr::select(-".row_name", -".fold_order")

  list_abiotic_train_scaled <-
    scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_train_wide,
      age_scale_mode = age_scale_mode
    )

  data_abiotic_train_scaled <-
    list_abiotic_train_scaled |>
    purrr::chuck("data_abiotic_scaled")

  data_abiotic_test_raw <-
    data_abiotic_test_identified |>
    dplyr::filter(
      .data[[".row_name"]] %in% .env[["vec_test_common_ids"]]
    ) |>
    dplyr::mutate(
      .fold_order = base::match(
        .data[[".row_name"]],
        .env[["vec_test_common_ids"]]
      )
    ) |>
    dplyr::arrange(.data[[".fold_order"]]) |>
    dplyr::select(-"dataset_name", -".fold_order") |>
    tibble::column_to_rownames(".row_name")

  data_abiotic_test_scaled <-
    apply_scale_attributes(
      data_predictors = data_abiotic_test_raw,
      scale_attributes = list_abiotic_train_scaled[["scale_attributes"]]
    )

  list_abiotic_train_aligned <-
    base::list(
      data_abiotic_scaled = data_abiotic_train_scaled,
      scale_attributes = list_abiotic_train_scaled[["scale_attributes"]]
    )

  list_spatial_fold <-
    if (
      flag_has_spatial_train
    ) {
      data_spatial_train_aligned <-
        data_spatial_train[
          vec_train_common_ids,
          ,
          drop = FALSE
        ]

      data_spatial_test_aligned <-
        data_spatial_test[
          vec_test_common_ids,
          ,
          drop = FALSE
        ]

      list_spatial_train_fitted <-
        scale_spatial_for_fit(
          data_spatial = data_spatial_train_aligned
        )

      data_spatial_test_transformed <-
        apply_scale_attributes(
          data_predictors = data_spatial_test_aligned,
          scale_attributes = list_spatial_train_fitted[[
            "spatial_scale_attributes"
          ]]
        )

      base::list(
        train = list_spatial_train_fitted,
        test = data_spatial_test_transformed
      )
    } else {
      base::list(
        train = NULL,
        test = NULL
      )
    }

  list_spatial_train_scaled <-
    list_spatial_fold |>
    purrr::chuck("train")

  data_spatial_test_scaled <-
    list_spatial_fold |>
    purrr::chuck("test")

  data_train_input <-
    assemble_data_to_fit(
      data_community_filtered = data_community_train_checked,
      data_abiotic_scaled_list = list_abiotic_train_aligned,
      data_spatial_scaled_list = list_spatial_train_scaled
    )

  data_test_input <-
    if (
      flag_has_spatial_train
    ) {
      base::list(
        data_abiotic_to_fit = data_abiotic_test_scaled,
        data_spatial_to_fit = data_spatial_test_scaled
      )
    } else {
      base::list(
        data_abiotic_to_fit = data_abiotic_test_scaled
      )
    }

  age_scale_value_raw <-
    list_abiotic_train_scaled[["scale_attributes"]][["age"]][[
      "scaled:scale"
    ]]

  age_scale_value <-
    if (
      base::is.null(age_scale_value_raw)
    ) {
      NA_real_
    } else {
      base::as.numeric(age_scale_value_raw)
    }

  data_diagnostics <-
    tibble::tibble(
      n_train_requested = base::length(train_ids),
      n_train_aligned = base::length(vec_train_common_ids),
      n_train_dropped_alignment = n_train_dropped_alignment,
      n_train_missing_abiotic = n_train_missing_abiotic,
      n_train_missing_spatial = n_train_missing_spatial,
      train_alignment_exact = train_alignment_exact,
      n_test_requested = base::length(test_ids),
      n_test_aligned = base::length(vec_test_common_ids),
      n_test_dropped_alignment = n_test_dropped_alignment,
      n_test_missing_abiotic = n_test_missing_abiotic,
      n_test_missing_spatial = n_test_missing_spatial,
      test_alignment_exact = test_alignment_exact,
      n_train_samples = base::nrow(data_community_train_checked),
      n_test_samples = base::nrow(data_community_test_aligned),
      n_taxa_raw = base::length(vec_taxa_full),
      n_taxa_retained = base::length(vec_taxa_retained),
      n_taxa_dropped = base::length(vec_taxa_full) -
        base::length(vec_taxa_retained),
      age_scale_mode = age_scale_mode,
      age_scale_value = age_scale_value
    )

  res <-
    base::list(
      data_train_input = data_train_input,
      data_test_input = data_test_input,
      data_test_observed = data_community_test_aligned,
      data_taxa_mapping = data_taxa_mapping,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

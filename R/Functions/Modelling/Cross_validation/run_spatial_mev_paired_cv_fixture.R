#' @title Run a Paired Spatial MEM Cross-Validation Fixture
#' @description
#' Runs exact and fast spatial MEM construction through identical fold
#' preparation, sjSDM fitting, and held-out prediction work.
#' @param data_community_matrix,data_abiotic_wide,data_coords_projected
#' Model inputs accepted by [prepare_sjsdm_cross_validation_fold()].
#' @param data_sample_ids
#' Sample metadata accepted by [prepare_sjsdm_cross_validation_fold()].
#' @param data_assignments
#' Table containing `repeat_id`, `fold_id`, and `row_index`. Each row index must
#' occur once in every repeat.
#' @param candidate
#' One regularization candidate accepted by
#' [fit_sjsdm_regularization_candidate()].
#' @param sel_abiotic_formula
#' Abiotic formula passed to [fit_sjsdm_regularization_candidate()].
#' @param config_model_fitting,config_data_processing
#' Shared model and data-processing configurations.
#' @param device
#' Device passed to [fit_sjsdm_regularization_candidate()].
#' @param prepare_function,fit_function,predict_function
#' Injectable production adapters used for focused orchestration tests.
#' @return
#' Named list containing paired benchmark rows, predictions, and fold
#' diagnostics.
#' @export
run_spatial_mev_paired_cv_fixture <- function(
    data_community_matrix = NULL,
    data_abiotic_wide = NULL,
    data_coords_projected = NULL,
    data_sample_ids = NULL,
    data_assignments = NULL,
    candidate = NULL,
    sel_abiotic_formula = NULL,
    config_model_fitting = NULL,
    config_data_processing = NULL,
    device = "cpu",
    prepare_function = prepare_sjsdm_cross_validation_fold,
    fit_function = fit_sjsdm_regularization_candidate,
    predict_function = predict_sjsdm_probability_matrix) {
  vec_assignment_columns <-
    base::c("repeat_id", "fold_id", "row_index")

  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::all(
      vec_assignment_columns %in% base::colnames(data_assignments)
    ),
    base::is.list(config_model_fitting),
    base::is.list(config_model_fitting[["spatial_mev"]]),
    base::is.list(config_data_processing),
    base::is.function(prepare_function),
    base::is.function(fit_function),
    base::is.function(predict_function),
    msg = "Paired spatial MEM fixture inputs must be complete."
  )

  data_duplicate_assignments <-
    data_assignments |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["row_index"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  assertthat::assert_that(
    base::nrow(data_assignments) > 0L,
    base::nrow(data_duplicate_assignments) == 0L,
    base::all(base::is.finite(data_assignments[["repeat_id"]])),
    base::all(base::is.finite(data_assignments[["fold_id"]])),
    base::all(base::is.finite(data_assignments[["row_index"]])),
    msg = "Each row index must have one fold assignment per repeat."
  )

  data_assignments_ordered <-
    data_assignments |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["row_index"]]
    )

  assignment_hash <-
    digest::digest(
      data_assignments_ordered[vec_assignment_columns],
      algo = "xxhash64"
    )

  list_predictions <- base::list()
  list_diagnostics <- base::list()
  result_index <- 0L

  for (
    spatial_mev_strategy in base::c("exact", "fast")
  ) {
    config_strategy <- config_model_fitting
    config_strategy[["spatial_mev"]][["strategy"]] <-
      spatial_mev_strategy

    for (
      repeat_id_value in
        base::sort(base::unique(data_assignments[["repeat_id"]]))
    ) {
      data_repeat_assignments <-
        data_assignments |>
        dplyr::filter(
          .data[["repeat_id"]] == .env[["repeat_id_value"]]
        )

      for (
        fold_id_value in
          base::sort(base::unique(data_repeat_assignments[["fold_id"]]))
      ) {
        result_index <- result_index + 1L

        vec_test_indices <-
          data_repeat_assignments |>
          dplyr::filter(
            .data[["fold_id"]] == .env[["fold_id_value"]]
          ) |>
          dplyr::pull("row_index") |>
          base::as.integer()

        vec_train_indices <-
          data_repeat_assignments |>
          dplyr::filter(
            .data[["fold_id"]] != .env[["fold_id_value"]]
          ) |>
          dplyr::pull("row_index") |>
          base::as.integer()

        preparation_start <-
          base::proc.time()[["elapsed"]]

        list_fold <-
          prepare_function(
            data_community_matrix = data_community_matrix,
            data_abiotic_wide = data_abiotic_wide,
            data_coords_projected = data_coords_projected,
            data_sample_ids = data_sample_ids,
            train_indices = vec_train_indices,
            test_indices = vec_test_indices,
            config_model_fitting = config_strategy,
            config_data_processing = config_data_processing,
            repeat_id = repeat_id_value,
            fold_id = fold_id_value
          )

        preparation_seconds <-
          base::as.numeric(
            base::proc.time()[["elapsed"]] - preparation_start
          )

        fit_seed <-
          base::as.integer(
            config_strategy[["spatial_mev"]][["fast_seed"]] +
              repeat_id_value * 1000L +
              fold_id_value
          )

        fitting_start <-
          base::proc.time()[["elapsed"]]

        object <-
          fit_function(
            data_train_input = list_fold[["data_train_input"]],
            candidate = candidate,
            sel_abiotic_formula = sel_abiotic_formula,
            config_model_fitting = config_strategy,
            seed = fit_seed,
            device = device
          )

        fitting_seconds <-
          base::as.numeric(
            base::proc.time()[["elapsed"]] - fitting_start
          )

        prediction_start <-
          base::proc.time()[["elapsed"]]

        data_predicted <-
          predict_function(
            object = object,
            data_test_input = list_fold[["data_test_input"]]
          )

        prediction_seconds <-
          base::as.numeric(
            base::proc.time()[["elapsed"]] - prediction_start
          )

        data_observed <-
          list_fold[["data_test_observed"]]

        assertthat::assert_that(
          base::is.matrix(data_observed),
          base::is.matrix(data_predicted),
          base::identical(
            base::dim(data_observed),
            base::dim(data_predicted)
          ),
          msg = "Paired fixture predictions must align to observations."
        )

        data_train_observed <-
          list_fold[["data_train_input"]][["data_community_to_fit"]]
        vec_null_probability <-
          base::colMeans(data_train_observed)
        vec_taxa <- base::colnames(data_observed)
        n_test <- base::nrow(data_observed)

        list_predictions[[result_index]] <-
          tibble::tibble(
            spatial_mev_strategy = spatial_mev_strategy,
            repeat_id = base::as.integer(repeat_id_value),
            fold_id = base::as.integer(fold_id_value),
            row_index = base::rep(vec_test_indices, times = base::ncol(
              data_observed
            )),
            taxon = base::rep(vec_taxa, each = n_test),
            observed = base::as.numeric(data_observed),
            predicted_probability = base::as.numeric(data_predicted),
            null_probability = base::rep(
              vec_null_probability,
              each = n_test
            ),
            prediction_status = "ok"
          )

        data_spatial_provenance <-
          list_fold[["data_spatial_provenance"]]

        flag_has_provenance <-
          base::is.data.frame(data_spatial_provenance) &&
          base::nrow(data_spatial_provenance) == 1L

        mev_seconds <-
          if (
            flag_has_provenance &&
              "elapsed_seconds" %in%
                base::colnames(data_spatial_provenance)
          ) {
            data_spatial_provenance[["elapsed_seconds"]][[1L]]
          } else {
            NA_real_
          }

        engine_method <-
          if (
            flag_has_provenance &&
              "engine_method" %in%
                base::colnames(data_spatial_provenance)
          ) {
            data_spatial_provenance[["engine_method"]][[1L]]
          } else {
            NA_character_
          }

        basis_bytes <-
          if (
            flag_has_provenance &&
              "basis_bytes" %in%
                base::colnames(data_spatial_provenance)
          ) {
            data_spatial_provenance[["basis_bytes"]][[1L]]
          } else {
            NA_real_
          }

        estimated_dense_matrix_bytes <-
          if (
            flag_has_provenance &&
              "estimated_dense_matrix_bytes" %in%
                base::colnames(data_spatial_provenance)
          ) {
            data_spatial_provenance[["estimated_dense_matrix_bytes"]][[1L]]
          } else {
            NA_real_
          }

        list_diagnostics[[result_index]] <-
          tibble::tibble(
            spatial_mev_strategy = spatial_mev_strategy,
            repeat_id = base::as.integer(repeat_id_value),
            fold_id = base::as.integer(fold_id_value),
            fit_status = "ok",
            n_train = base::length(vec_train_indices),
            n_test = base::length(vec_test_indices),
            preparation_seconds = preparation_seconds,
            mev_seconds = mev_seconds,
            fitting_seconds = fitting_seconds,
            prediction_seconds = prediction_seconds,
            engine_method = engine_method,
            basis_bytes = basis_bytes,
            estimated_dense_matrix_bytes =
              estimated_dense_matrix_bytes
          )
      }
    }
  }

  data_predictions <-
    purrr::list_rbind(list_predictions)
  data_fold_diagnostics <-
    purrr::list_rbind(list_diagnostics)

  artifact_schema_hash <-
    data_predictions |>
    dplyr::select(-"spatial_mev_strategy") |>
    purrr::map_chr(~ base::class(.x)[[1L]]) |>
    digest::digest(algo = "xxhash64")

  data_benchmark_runs <-
    base::c("exact", "fast") |>
    purrr::map(
      ~ {
        data_strategy_predictions <-
          data_predictions |>
          dplyr::filter(
            .data[["spatial_mev_strategy"]] == .x
          ) |>
          dplyr::select(-"spatial_mev_strategy")

        summarise_spatial_mev_benchmark_predictions(
          data_predictions = data_strategy_predictions,
          spatial_mev_strategy = .x,
          technical_cv_status = "pass",
          assignment_hash = assignment_hash,
          artifact_schema_hash = artifact_schema_hash
        )
      }
    ) |>
    purrr::list_rbind()

  res <-
    base::list(
      data_benchmark_runs = data_benchmark_runs,
      data_predictions = data_predictions,
      data_fold_diagnostics = data_fold_diagnostics
    )

  return(res)
}

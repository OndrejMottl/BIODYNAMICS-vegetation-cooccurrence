#' @title Read Spatial Model Results
#' @description
#' Reads successful spatial model ANOVA and evaluation targets from
#' indexed targets stores and returns one summary row per
#' store-resolution-component combination.
#' @param store_index
#' Data frame returned by [build_spatial_model_store_index()].
#' @param resolution_ids
#' Character vector of model resolution identifiers.
#' @param read_target_fn
#' Function used to read one target. Defaults to
#' [targets::tar_read_raw()].
#' @param meta_fn
#' Function used to read target metadata. Defaults to
#' [targets::tar_meta()].
#' @param require_non_empty
#' Logical. If `TRUE`, error when no rows are read.
#' @return
#' A tibble with ANOVA component percentages, explicitly labelled fitted AUC,
#' and cross-validated predictive Tjur R2, AUC, and log loss.
#' @export
read_spatial_model_results <- function(
    store_index,
    resolution_ids,
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta,
    require_non_empty = FALSE) {
  assertthat::assert_that(
    base::is.data.frame(store_index),
    msg = "`store_index` must be a data frame."
  )

  vec_required_cols <-
    base::c(
      "data_source",
      "scale",
      "scale_id",
      "pipeline_name",
      "store_path",
      "store_exists"
    )

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(store_index)),
    msg = stringr::str_glue(
      "`store_index` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.character(resolution_ids) &&
      base::length(resolution_ids) > 0L,
    msg = "`resolution_ids` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  assertthat::assert_that(
    assertthat::is.flag(require_non_empty),
    msg = "`require_non_empty` must be a single logical value."
  )

  data_empty_result <-
    tibble::tibble(
      data_source = base::character(),
      scale = base::character(),
      scale_id = base::character(),
      pipeline_name = base::character(),
      store_path = base::character(),
      resolution_id = base::character(),
      component = base::character(),
      R2_Nagelkerke_adjusted = base::numeric(),
      R2_Nagelkerke_percentage = base::numeric(),
      fitted_auc_mean = base::numeric(),
      fitted_auc_median = base::numeric(),
      fitted_auc_n = base::integer(),
      predictive_tjur_r2_mean = base::numeric(),
      predictive_auc_mean = base::numeric(),
      predictive_log_loss_mean = base::numeric(),
      cv_strategy = base::character(),
      effective_folds = base::integer(),
      cv_feasibility_status = base::character(),
      n_locations = base::integer(),
      n_samples = base::integer(),
      n_taxa = base::integer(),
      n_effective_mev = base::integer(),
      regularization_source = base::character(),
      source_tier = base::character(),
      candidate_id = base::character()
    )

  data_fitted_auc_default <-
    tibble::tibble(
      fitted_auc_mean = NA_real_,
      fitted_auc_median = NA_real_,
      fitted_auc_n = 0L
    )

  data_predictive_metric_template <-
    tibble::tibble(
      metric_id = base::c("tjur_r2", "auc", "log_loss"),
      metric_column = base::c(
        "predictive_tjur_r2_mean",
        "predictive_auc_mean",
        "predictive_log_loss_mean"
      )
    )

  data_provenance_defaults <-
    tibble::tibble(
      cv_strategy = NA_character_,
      effective_folds = NA_integer_,
      cv_feasibility_status = NA_character_,
      n_locations = NA_integer_,
      n_samples = NA_integer_,
      n_taxa = NA_integer_,
      n_effective_mev = NA_integer_,
      regularization_source = NA_character_,
      source_tier = NA_character_,
      candidate_id = NA_character_
    )

  data_existing_stores <-
    store_index |>
    dplyr::filter(.data[["store_exists"]]) |>
    dplyr::mutate(
      row_id = dplyr::row_number(),
      data_meta = .data[["store_path"]] |>
        purrr::map(
          .f = ~ {
            store_path <-
              .x

            purrr::possibly(
              .f = ~ meta_fn(
                fields = base::c("name", "error"),
                complete_only = FALSE,
                store = store_path
              ),
              otherwise = NULL
            )()
          }
        )
    )

  res <-
    data_existing_stores |>
    dplyr::group_split(.data[["row_id"]], .keep = FALSE) |>
    purrr::map(
      .f = ~ {
        store_row <-
          .x

        data_meta <-
          store_row[["data_meta"]][[1L]]

        store_path <-
          store_row[["store_path"]][[1L]]

        resolution_ids |>
          purrr::map(
            .f = ~ {
              resolution_id <-
                .x

              target_anova <-
                stringr::str_glue("model_anova_{resolution_id}") |>
                base::as.character()

              if (
                !check_target_succeeded(data_meta, target_anova)
              ) {
                return(data_empty_result)
              }

              model_anova <-
                purrr::possibly(
                  .f = ~ read_target_fn(
                    name = target_anova,
                    store = store_path
                  ),
                  otherwise = NULL
                )()

              if (
                base::is.null(model_anova)
              ) {
                return(data_empty_result)
              }

              data_anova <-
                extract_anova_fractions(
                  anova_object = model_anova,
                  clamp_negative = TRUE
                ) |>
                dplyr::mutate(age = 0)

              if (
                base::nrow(data_anova) == 0L
              ) {
                return(data_empty_result)
              }

              target_evaluation_fitted <-
                stringr::str_glue(
                  "model_evaluation_fitted_{resolution_id}"
                ) |>
                base::as.character()

              model_evaluation_fitted <-
                if (
                  check_target_succeeded(
                    data_meta,
                    target_evaluation_fitted
                  )
                ) {
                  read_model_evaluation_target(
                    store_path = store_path,
                    resolution_id = resolution_id,
                    evaluation_type = "fitted",
                    read_target_fn = read_target_fn
                  )
                } else {
                  NULL
                }

              data_fitted_auc <-
                if (
                  base::is.null(model_evaluation_fitted) ||
                    !("species" %in% base::names(
                      model_evaluation_fitted
                    ))
                ) {
                  data_fitted_auc_default
                } else {
                  data_species <-
                    model_evaluation_fitted |>
                    purrr::chuck("species")

                  if (
                    !base::is.data.frame(data_species) ||
                      !("AUC" %in% base::colnames(data_species))
                  ) {
                    data_fitted_auc_default
                  } else {
                    vec_auc_raw <-
                      data_species[["AUC"]] |>
                      base::as.numeric()

                    vec_auc_finite <-
                      vec_auc_raw[base::is.finite(vec_auc_raw)]

                    if (
                      base::length(vec_auc_finite) == 0L
                    ) {
                      data_fitted_auc_default
                    } else {
                      tibble::tibble(
                        fitted_auc_mean = base::mean(vec_auc_finite),
                        fitted_auc_median = stats::median(vec_auc_finite),
                        fitted_auc_n = base::length(vec_auc_finite)
                      )
                    }
                  }
                }

              target_evaluation_cross_validated <-
                stringr::str_glue(
                  "model_evaluation_cross_validated_{resolution_id}"
                ) |>
                base::as.character()

              model_evaluation_cross_validated <-
                if (
                  check_target_succeeded(
                    data_meta,
                    target_evaluation_cross_validated
                  )
                ) {
                  read_model_evaluation_target(
                    store_path = store_path,
                    resolution_id = resolution_id,
                    evaluation_type = "cross_validated",
                    read_target_fn = read_target_fn
                  )
                } else {
                  NULL
                }

              data_metric_summary <-
                if (
                  base::is.null(model_evaluation_cross_validated) ||
                    !("data_community_summary" %in% base::names(
                      model_evaluation_cross_validated
                    ))
                ) {
                  tibble::tibble(
                    metric_id = base::character(),
                    estimate = base::numeric()
                  )
                } else {
                  data_community_summary <-
                    model_evaluation_cross_validated |>
                    purrr::chuck("data_community_summary")

                  if (
                    !base::is.data.frame(data_community_summary) ||
                      !base::all(
                        base::c(
                          "metric_id",
                          "estimate",
                          "metric_status"
                        ) %in% base::colnames(data_community_summary)
                      )
                  ) {
                    tibble::tibble(
                      metric_id = base::character(),
                      estimate = base::numeric()
                    )
                  } else {
                    data_community_summary |>
                      dplyr::filter(
                        .data[["metric_status"]] == "ok",
                        base::is.finite(.data[["estimate"]])
                      ) |>
                      dplyr::group_by(.data[["metric_id"]]) |>
                      dplyr::summarise(
                        estimate = base::mean(.data[["estimate"]]),
                        .groups = "drop"
                      )
                  }
                }

              data_predictive_metrics <-
                data_predictive_metric_template |>
                dplyr::left_join(
                  data_metric_summary,
                  by = dplyr::join_by(metric_id),
                  multiple = "error",
                  unmatched = "drop"
                ) |>
                dplyr::select("metric_column", "estimate") |>
                tidyr::pivot_wider(
                  names_from = "metric_column",
                  values_from = "estimate"
                )

              target_provenance <-
                stringr::str_glue(
                  "data_sjsdm_model_provenance_{resolution_id}"
                ) |>
                base::as.character()

              data_provenance <-
                if (
                  check_target_succeeded(data_meta, target_provenance)
                ) {
                  purrr::possibly(
                    .f = ~ read_target_fn(
                      name = target_provenance,
                      store = store_path
                    ),
                    otherwise = NULL
                  )()
                } else {
                  NULL
                }

              data_provenance_first <-
                if (
                  base::is.data.frame(data_provenance) &&
                    base::nrow(data_provenance) > 0L
                ) {
                  data_provenance |>
                    dplyr::slice_head(n = 1L)
                } else {
                  tibble::tibble()
                }

              data_provenance_summary <-
                dplyr::bind_rows(
                  data_provenance_first,
                  data_provenance_defaults
                ) |>
                dplyr::slice_head(n = 1L)

              data_anova |>
                recalculate_anova_components() |>
                dplyr::mutate(
                  data_source = store_row[["data_source"]][[1L]],
                  scale = store_row[["scale"]][[1L]],
                  scale_id = store_row[["scale_id"]][[1L]],
                  pipeline_name = store_row[["pipeline_name"]][[1L]],
                  store_path = store_path,
                  resolution_id = resolution_id,
                  fitted_auc_mean =
                    data_fitted_auc[["fitted_auc_mean"]][[1L]],
                  fitted_auc_median =
                    data_fitted_auc[["fitted_auc_median"]][[1L]],
                  fitted_auc_n =
                    data_fitted_auc[["fitted_auc_n"]][[1L]],
                  predictive_tjur_r2_mean =
                    data_predictive_metrics[[
                      "predictive_tjur_r2_mean"
                    ]][[1L]],
                  predictive_auc_mean =
                    data_predictive_metrics[[
                      "predictive_auc_mean"
                    ]][[1L]],
                  predictive_log_loss_mean =
                    data_predictive_metrics[[
                      "predictive_log_loss_mean"
                    ]][[1L]],
                  cv_strategy =
                    data_provenance_summary[["cv_strategy"]][[1L]],
                  effective_folds =
                    data_provenance_summary[[
                      "effective_folds"
                    ]][[1L]],
                  cv_feasibility_status =
                    data_provenance_summary[[
                      "cv_feasibility_status"
                    ]][[1L]],
                  n_locations =
                    data_provenance_summary[["n_locations"]][[1L]],
                  n_samples =
                    data_provenance_summary[["n_samples"]][[1L]],
                  n_taxa = data_provenance_summary[["n_taxa"]][[1L]],
                  n_effective_mev =
                    data_provenance_summary[[
                      "n_effective_mev"
                    ]][[1L]],
                  regularization_source =
                    data_provenance_summary[[
                      "regularization_source"
                    ]][[1L]],
                  source_tier =
                    data_provenance_summary[["source_tier"]][[1L]],
                  candidate_id =
                    data_provenance_summary[["candidate_id"]][[1L]]
                ) |>
                dplyr::select(
                  "data_source",
                  "scale",
                  "scale_id",
                  "pipeline_name",
                  "store_path",
                  "resolution_id",
                  "component",
                  "R2_Nagelkerke_adjusted",
                  "R2_Nagelkerke_percentage",
                  "fitted_auc_mean",
                  "fitted_auc_median",
                  "fitted_auc_n",
                  "predictive_tjur_r2_mean",
                  "predictive_auc_mean",
                  "predictive_log_loss_mean",
                  "cv_strategy",
                  "effective_folds",
                  "cv_feasibility_status",
                  "n_locations",
                  "n_samples",
                  "n_taxa",
                  "n_effective_mev",
                  "regularization_source",
                  "source_tier",
                  "candidate_id"
                )
            }
          ) |>
          purrr::list_rbind()
      }
    ) |>
    purrr::list_rbind()

  data_result <-
    if (
      base::is.null(res)
    ) {
      data_empty_result
    } else {
      res
    }

  if (
    base::isTRUE(require_non_empty) &&
      base::nrow(data_result) == 0L
  ) {
    cli::cli_abort(
      "No successful spatial model results were found in existing stores."
    )
  }

  return(data_result)
}

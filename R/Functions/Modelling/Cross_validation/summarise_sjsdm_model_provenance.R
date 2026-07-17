#' @title Summarise sjSDM Model Provenance
#' @description
#' Combines cross-validation feasibility, selected regularization, and
#' selected-fold diagnostics into one model-level provenance row.
#' @param data_feasibility
#' One-row cross-validation feasibility table.
#' @param data_regularization
#' One-row selected regularization table returned by
#' [resolve_sjsdm_regularization_for_fit()].
#' @param data_fold_diagnostics
#' Selected-candidate fold diagnostics. An empty data frame is allowed when
#' held-out evaluation is unavailable.
#' @param fit_device
#' Scalar fitting-device identifier. Must be `"cpu"` or `"gpu"`.
#' @return
#' One-row tibble containing model context, feasibility, data counts, fold-fit
#' counts, effective MEV minimum/maximum/status and retained-taxon counts, and
#' regularization source. It also records the fitting device and versioned
#' fold-local evaluation contract. The legacy scalar `n_effective_mev` is
#' retained when the count is constant across folds and is missing when counts
#' vary.
#' @examples
#' \dontrun{
#' summarise_sjsdm_model_provenance(
#'   data_feasibility = data_cross_validation_feasibility,
#'   data_regularization = model_regularization_for_fit,
#'   data_fold_diagnostics = data_sjsdm_out_of_fold_diagnostics,
#'   fit_device = "gpu"
#' )
#' }
#' @export
summarise_sjsdm_model_provenance <- function(
    data_feasibility = NULL,
    data_regularization = NULL,
    data_fold_diagnostics = NULL,
    fit_device = NULL) {
  vec_feasibility_columns <-
    base::c(
      "n_locations",
      "n_samples",
      "n_taxa",
      "n_mem_locations",
      "cv_strategy",
      "effective_folds",
      "cv_feasibility_status"
    )

  vec_regularization_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash",
      "candidate_id",
      "regularization_source",
      "source_tier",
      "selection_status"
    )

  assertthat::assert_that(
    base::is.data.frame(data_feasibility),
    base::nrow(data_feasibility) == 1L,
    base::all(
      vec_feasibility_columns %in% base::colnames(data_feasibility)
    ),
    msg = "data_feasibility must contain one complete provenance row."
  )

  assertthat::assert_that(
    base::is.data.frame(data_regularization),
    base::nrow(data_regularization) == 1L,
    base::all(
      vec_regularization_columns %in%
        base::colnames(data_regularization)
    ),
    msg = "data_regularization must contain one selected result."
  )

  assertthat::assert_that(
    base::is.data.frame(data_fold_diagnostics),
    msg = "data_fold_diagnostics must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(fit_device),
    base::length(fit_device) == 1L,
    !base::is.na(fit_device),
    fit_device %in% base::c("cpu", "gpu"),
    msg = "fit_device must be either 'cpu' or 'gpu'."
  )

  flag_has_fold_diagnostics <-
    base::nrow(data_fold_diagnostics) > 0L

  if (
    flag_has_fold_diagnostics
  ) {
    vec_diagnostic_columns <-
      base::c(
        "repeat_id",
        "fold_id",
        "n_taxa_retained",
        "n_effective_mev",
        "fit_status"
      )

    assertthat::assert_that(
      base::all(
        vec_diagnostic_columns %in%
          base::colnames(data_fold_diagnostics)
      ),
      msg = "data_fold_diagnostics is missing provenance columns."
    )
  }

  vec_effective_mev <-
    if (
      flag_has_fold_diagnostics
    ) {
      data_fold_diagnostics[["n_effective_mev"]] |>
        purrr::discard(base::is.na)
    } else {
      base::integer()
    }

  flag_valid_effective_mev <-
    base::is.numeric(vec_effective_mev) &&
    base::all(base::is.finite(vec_effective_mev)) &&
    base::all(vec_effective_mev >= 0L) &&
    base::all(vec_effective_mev <= .Machine[["integer.max"]]) &&
    base::all(
      vec_effective_mev == base::as.integer(vec_effective_mev)
    )

  assertthat::assert_that(
    flag_valid_effective_mev,
    msg = "Effective MEV counts must be non-negative integers."
  )

  n_effective_mev_distinct <-
    dplyr::n_distinct(vec_effective_mev)

  effective_mev_status <-
    dplyr::case_when(
      n_effective_mev_distinct == 0L ~ "unavailable",
      n_effective_mev_distinct == 1L ~ "constant_across_folds",
      .default = "varies_by_fold"
    )

  vec_taxa_retained <-
    if (
      flag_has_fold_diagnostics
    ) {
      data_fold_diagnostics[["n_taxa_retained"]] |>
        purrr::discard(base::is.na)
    } else {
      base::integer()
    }

  data_fold_summary <-
    tibble::tibble(
      n_repeats = if (
        flag_has_fold_diagnostics
      ) {
        dplyr::n_distinct(data_fold_diagnostics[["repeat_id"]])
      } else {
        0L
      },
      n_fold_fits = base::nrow(data_fold_diagnostics),
      n_successful_fold_fits = if (
        flag_has_fold_diagnostics
      ) {
        base::sum(data_fold_diagnostics[["fit_status"]] == "ok")
      } else {
        0L
      },
      n_taxa_retained_min = if (
        base::length(vec_taxa_retained) > 0L
      ) {
        base::min(vec_taxa_retained)
      } else {
        NA_integer_
      },
      n_effective_mev = if (
        n_effective_mev_distinct == 1L
      ) {
        vec_effective_mev[[1L]]
      } else {
        NA_integer_
      },
      n_effective_mev_min = if (
        n_effective_mev_distinct > 0L
      ) {
        base::min(vec_effective_mev)
      } else {
        NA_integer_
      },
      n_effective_mev_max = if (
        n_effective_mev_distinct > 0L
      ) {
        base::max(vec_effective_mev)
      } else {
        NA_integer_
      },
      effective_mev_status = effective_mev_status
    )

  data_evaluation_provenance <-
    tibble::tibble(
      fit_device = fit_device,
      evaluation_prediction_source = "out_of_fold",
      evaluation_estimand = "repeat_fold_taxon",
      evaluation_aggregation_methods =
        "fold_macro;observation_weighted",
      evaluation_schema_version = "sjsdm_fold_local_cv_v1"
    )

  res <-
    dplyr::bind_cols(
      data_regularization |>
        dplyr::select(dplyr::all_of(vec_regularization_columns)),
      data_feasibility |>
        dplyr::select(dplyr::all_of(vec_feasibility_columns)),
      data_fold_summary,
      data_evaluation_provenance
    )

  return(res)
}

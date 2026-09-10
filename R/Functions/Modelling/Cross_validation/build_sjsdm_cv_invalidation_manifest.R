#' Build a surgical sjSDM CV invalidation manifest
#'
#' @param data_continental_audit Completed continental retention audit.
#' @param regional_store_root Optional paleo regional target-store root.
#' @param regional_units Regional units whose partial CV state must be reset.
#' @param regional_tier_store Optional paleo regional tier-tuning store.
#'
#' @return A tibble with one row per target selected for invalidation.
#'
#' @export
build_sjsdm_cv_invalidation_manifest <- function(
    data_continental_audit,
    regional_store_root = NULL,
    regional_units = base::c("eu_r001", "eu_r002"),
    regional_tier_store = NULL) {
  required_columns <-
    base::c(
      "analysis_id",
      "continent_id",
      "resolution_id",
      "store_path",
      "retention_status",
      "retention_reason"
    )

  assertthat::assert_that(
    base::all(required_columns %in% base::names(data_continental_audit)),
    msg = "The continental audit does not match the required schema."
  )
  assertthat::assert_that(
    base::all(
      data_continental_audit[["retention_status"]] %in%
        base::c(
          "retain_legacy_selection_and_model",
          "invalidate_cv_and_model_descendants"
        )
    ),
    msg = "The continental audit contains an unresolved retention status."
  )

  unit_target_stems <-
    base::c(
      "list_sjsdm_tuning_work_item_result",
      "data_sjsdm_unit_regularization_selection",
      "data_sjsdm_regularization_selection_for_fit",
      "list_sjsdm_regularization_selection_artifact",
      "mod_jsdm",
      "mod_jsdm_with_standard_errors",
      "mod_jsdm_selected",
      "list_sjsdm_selected_fold_artifacts",
      "data_sjsdm_cv_model_provenance",
      "list_sjsdm_cv_evaluation_artifact",
      "list_jsdm_evaluation_fitted",
      "list_jsdm_variance_partition"
    )

  data_continental <-
    data_continental_audit |>
    dplyr::filter(
      .data[["retention_status"]] ==
        "invalidate_cv_and_model_descendants"
    ) |>
    tidyr::crossing(target_stem = unit_target_stems) |>
    dplyr::transmute(
      scope = "continental_audit",
      analysis_id = .data[["analysis_id"]],
      tier_id = "continental",
      unit_id = .data[["continent_id"]],
      resolution_id = .data[["resolution_id"]],
      store_path = .data[["store_path"]],
      target_name = stringr::str_c(
        .data[["target_stem"]],
        "_",
        .data[["resolution_id"]]
      ),
      reason = .data[["retention_reason"]]
    )

  data_regional <-
    tibble::tibble(unit_id = base::as.character(regional_units)) |>
    tidyr::crossing(
      resolution_id = base::c(
        "genus",
        "family",
        "functional_type"
      ),
      target_stem = unit_target_stems
    ) |>
    dplyr::transmute(
      scope = "partial_regional_reset",
      analysis_id = "paleo_spatial",
      tier_id = "regional",
      unit_id = .data[["unit_id"]],
      resolution_id = .data[["resolution_id"]],
      store_path = if (
        base::is.null(regional_store_root)
      ) {
        NA_character_
      } else {
        base::file.path(
          regional_store_root,
          .data[["unit_id"]],
          "pipeline_paleo_spatial_resolution"
        )
      },
      target_name = stringr::str_c(
        .data[["target_stem"]],
        "_",
        .data[["resolution_id"]]
      ),
      reason = "partial_pre_contract_cv_state"
    )

  tier_target_names <-
    base::c(
      "data_sjsdm_tier_tuning_summaries",
      "list_sjsdm_tier_survivor_artifacts_round_1",
      "data_sjsdm_tier_survivor_decisions_round_1",
      "list_sjsdm_tier_survivor_artifacts_round_2",
      "data_sjsdm_tier_survivor_decisions_round_2",
      "list_sjsdm_tier_survivor_artifacts_round_3",
      "data_sjsdm_tier_survivor_decisions_round_3",
      "list_sjsdm_tier_tuning_artifacts",
      "list_sjsdm_tier_tuning_artifact"
    )
  data_tier <-
    tibble::tibble(
      scope = "partial_regional_tier_reset",
      analysis_id = "paleo_spatial",
      tier_id = "regional",
      unit_id = "tier",
      resolution_id = NA_character_,
      store_path = if (
        base::is.null(regional_tier_store)
      ) {
        NA_character_
      } else {
        base::as.character(regional_tier_store)
      },
      target_name = tier_target_names,
      reason = "dependent_on_partial_pre_contract_cv_state"
    )

  dplyr::bind_rows(data_continental, data_regional, data_tier) |>
    dplyr::arrange(
      .data[["scope"]],
      .data[["analysis_id"]],
      .data[["unit_id"]],
      .data[["resolution_id"]],
      .data[["target_name"]]
    )
}

#' @title Resolve sjSDM Regularization for Final Fit
#' @description
#' Resolves unit-CV, tier-pooled, or no-model regularization from feasibility
#' status and compatible selection artifacts.
#' @param data_feasibility
#' One-row feasibility table containing cv_feasibility_status.
#' @param data_model_context
#' One-row table containing tier, taxonomic resolution, response family,
#' predictor structure, and candidate-table hash.
#' @param data_unit_selection
#' Optional one-row unit-CV candidate selection.
#' @param data_tier_artifact
#' Optional one-row tier artifact returned by
#' [build_sjsdm_tier_tuning_artifact()].
#' @return
#' One-row tibble containing model context, feasibility status, selected
#' candidate parameters, regularization source, source tier, and selection
#' status. Full-model-infeasible inputs return explicit missing parameters.
#' @examples
#' \dontrun{
#' resolve_sjsdm_regularization_for_fit(
#'   data_feasibility = data_feasibility,
#'   data_model_context = data_model_context,
#'   data_unit_selection = data_unit_selection
#' )
#' }
#' @export
resolve_sjsdm_regularization_for_fit <- function(
    data_feasibility = NULL,
    data_model_context = NULL,
    data_unit_selection = NULL,
    data_tier_artifact = NULL) {
  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  vec_parameter_columns <-
    base::c(
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  vec_candidate_columns <-
    base::c("candidate_id", vec_parameter_columns)

  assertthat::assert_that(
    base::is.data.frame(data_feasibility),
    base::nrow(data_feasibility) == 1L,
    "cv_feasibility_status" %in%
      base::colnames(data_feasibility),
    msg = "data_feasibility must contain one feasibility row."
  )

  assertthat::assert_that(
    base::is.data.frame(data_model_context),
    base::nrow(data_model_context) == 1L,
    base::all(
      vec_context_columns %in% base::colnames(data_model_context)
    ),
    msg = "data_model_context must contain one complete context row."
  )

  cv_feasibility_status <-
    data_feasibility[["cv_feasibility_status"]][[1L]]

  vec_supported_statuses <-
    base::c(
      "grouped_kfold_feasible",
      "leave_one_location_out_required",
      "tier_pooled_regularization_required",
      "full_model_infeasible"
    )

  assertthat::assert_that(
    base::is.character(cv_feasibility_status),
    cv_feasibility_status %in% vec_supported_statuses,
    msg = "The cross-validation feasibility status is not supported."
  )

  data_context <-
    data_model_context |>
    dplyr::select(dplyr::all_of(vec_context_columns))

  if (
    cv_feasibility_status == "full_model_infeasible"
  ) {
    res_no_model <-
      data_context |>
      dplyr::mutate(
        cv_feasibility_status = cv_feasibility_status,
        candidate_id = NA_character_,
        alpha_cov = NA_real_,
        alpha_coef = NA_real_,
        alpha_spatial = NA_real_,
        lambda_cov = NA_real_,
        lambda_coef = NA_real_,
        lambda_spatial = NA_real_,
        regularization_source = "none",
        source_tier = NA_character_,
        selection_status = "full_model_infeasible"
      )

    return(res_no_model)
  }

  flag_unit_cv <-
    cv_feasibility_status %in%
    base::c(
      "grouped_kfold_feasible",
      "leave_one_location_out_required"
    )

  if (
    flag_unit_cv
  ) {
    assertthat::assert_that(
      base::is.data.frame(data_unit_selection),
      base::nrow(data_unit_selection) == 1L,
      base::all(
        vec_candidate_columns %in%
          base::colnames(data_unit_selection)
      ),
      msg = "Unit-CV feasibility requires one selected candidate."
    )

    assertthat::assert_that(
      base::all(
        purrr::map_lgl(
          data_unit_selection[vec_parameter_columns],
          base::is.numeric
        )
      ),
      base::all(
        base::is.finite(
          base::as.matrix(
            data_unit_selection[vec_parameter_columns]
          )
        )
      ),
      msg = "Unit-CV candidate parameters must be finite numbers."
    )

    res_unit <-
      dplyr::bind_cols(
        data_context,
        data_unit_selection |>
          dplyr::select(dplyr::all_of(vec_candidate_columns))
      ) |>
      dplyr::mutate(
        cv_feasibility_status = cv_feasibility_status,
        regularization_source = "unit_cv",
        source_tier = NA_character_,
        selection_status = "selected"
      )

    return(res_unit)
  }

  assertthat::assert_that(
    base::is.data.frame(data_tier_artifact),
    base::nrow(data_tier_artifact) == 1L,
    base::all(
      base::c(
        vec_context_columns,
        vec_candidate_columns,
        "regularization_source",
        "source_tier"
      ) %in% base::colnames(data_tier_artifact)
    ),
    msg = "Tier-pooled feasibility requires one complete tier artifact."
  )

  flag_context_matches <-
    vec_context_columns |>
    purrr::map_lgl(
      .f = ~ base::identical(
        base::as.character(data_tier_artifact[[.x]]),
        base::as.character(data_context[[.x]])
      )
    ) |>
    base::all()

  if (
    !flag_context_matches ||
      data_tier_artifact[["regularization_source"]][[1L]] !=
        "tier_pooled" ||
      data_tier_artifact[["source_tier"]][[1L]] !=
        data_context[["tier_id"]][[1L]]
  ) {
    cli::cli_abort(
      "The tier tuning artifact does not match the model context."
    )
  }

  res_tier <-
    data_tier_artifact |>
    dplyr::select(
      dplyr::all_of(vec_context_columns),
      dplyr::all_of(vec_candidate_columns),
      "regularization_source",
      "source_tier"
    ) |>
    dplyr::mutate(
      cv_feasibility_status = cv_feasibility_status,
      selection_status = "selected"
    )

  return(res_tier)
}

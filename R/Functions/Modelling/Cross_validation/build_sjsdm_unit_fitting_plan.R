#' @title Build an sjSDM Unit Fitting Plan
#' @description
#' Validates preparation evidence for one analysis tier and classifies each
#' requested unit as eligible for fitting or expected infeasible.
#' @param data_preparation_inventory
#' Data frame containing preparation evidence by analysis, tier, unit, and
#' resolution.
#' @param analysis_id Character scalar identifying the analysis.
#' @param tier_id Character scalar identifying the spatial tier.
#' @param scale_ids Unique character vector of requested unit identifiers.
#' @param resolution_ids Unique character vector of required resolutions.
#' @return
#' Tibble with one row per requested unit and columns `scale_id`,
#' `fitting_status`, and `preparation_reason_code`.
#' @export
build_sjsdm_unit_fitting_plan <- function(
    data_preparation_inventory = NULL,
    analysis_id = NULL,
    tier_id = NULL,
    scale_ids = NULL,
    resolution_ids = NULL) {
  vec_required_columns <-
    base::c(
      "analysis_id",
      "tier_id",
      "scale_id",
      "resolution_id",
      "preparation_status",
      "preparation_reason_code"
    )

  assertthat::assert_that(
    base::is.data.frame(data_preparation_inventory),
    base::all(
      vec_required_columns %in%
        base::names(data_preparation_inventory)
    ),
    msg = paste(
      "data_preparation_inventory must contain the required",
      "preparation-evidence columns."
    )
  )
  assertthat::assert_that(
    base::is.character(analysis_id),
    base::length(analysis_id) == 1L,
    !base::is.na(analysis_id),
    base::nzchar(analysis_id),
    msg = "analysis_id must be one non-empty string."
  )
  assertthat::assert_that(
    base::is.character(tier_id),
    base::length(tier_id) == 1L,
    !base::is.na(tier_id),
    base::nzchar(tier_id),
    msg = "tier_id must be one non-empty string."
  )
  assertthat::assert_that(
    base::is.character(scale_ids),
    base::length(scale_ids) > 0L,
    base::all(!base::is.na(scale_ids)),
    base::all(base::nzchar(scale_ids)),
    !base::any(base::duplicated(scale_ids)),
    msg = "scale_ids must contain unique non-empty strings."
  )
  assertthat::assert_that(
    base::is.character(resolution_ids),
    base::length(resolution_ids) > 0L,
    base::all(!base::is.na(resolution_ids)),
    base::all(base::nzchar(resolution_ids)),
    !base::any(base::duplicated(resolution_ids)),
    msg = "resolution_ids must contain unique non-empty strings."
  )

  data_selected_inventory <-
    data_preparation_inventory |>
    dplyr::filter(
      .data[["analysis_id"]] == .env[["analysis_id"]],
      .data[["tier_id"]] == .env[["tier_id"]],
      .data[["scale_id"]] %in% .env[["scale_ids"]],
      .data[["resolution_id"]] %in% .env[["resolution_ids"]]
    ) |>
    dplyr::select(
      dplyr::all_of(
        base::c(
          "scale_id",
          "resolution_id",
          "preparation_status",
          "preparation_reason_code"
        )
      )
    )

  if (
    base::any(
      base::duplicated(
        data_selected_inventory[
          base::c("scale_id", "resolution_id")
        ]
      )
    )
  ) {
    cli::cli_abort(
      base::c(
        "Preparation evidence contains duplicate unit-resolution rows.",
        "i" = "Regenerate the stage 02 calibration inventory."
      )
    )
  }

  data_expected_keys <-
    tidyr::expand_grid(
      scale_id = scale_ids,
      resolution_id = resolution_ids
    )
  data_preparation_evidence <-
    data_expected_keys |>
    dplyr::left_join(
      data_selected_inventory,
      by = dplyr::join_by(scale_id, resolution_id)
    )
  flag_complete_evidence <-
    base::all(
      data_preparation_evidence[["preparation_status"]] %in%
        base::c("prepared", "expected_infeasible")
    )

  if (
    !flag_complete_evidence
  ) {
    cli::cli_abort(
      base::c(
        "Preparation evidence is missing or unresolved.",
        "i" = base::paste(
          "Analysis",
          analysis_id,
          "and tier",
          tier_id,
          "require one classified row for every requested unit and",
          "resolution."
        ),
        "i" = "Rerun stages 01 and 02 before model fitting."
      )
    )
  }

  data_unit_plan <-
    data_preparation_evidence |>
    dplyr::group_by(.data[["scale_id"]]) |>
    dplyr::summarise(
      fitting_status = dplyr::if_else(
        base::all(
          .data[["preparation_status"]] == "expected_infeasible"
        ),
        "expected_infeasible",
        "eligible"
      ),
      preparation_reason_code = dplyr::first(
        .data[["preparation_reason_code"]][
          !base::is.na(.data[["preparation_reason_code"]])
        ],
        default = NA_character_
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      preparation_reason_code = dplyr::if_else(
        .data[["fitting_status"]] == "expected_infeasible",
        .data[["preparation_reason_code"]],
        NA_character_
      )
    )

  tibble::tibble(scale_id = scale_ids) |>
    dplyr::left_join(
      data_unit_plan,
      by = dplyr::join_by(scale_id)
    )
}

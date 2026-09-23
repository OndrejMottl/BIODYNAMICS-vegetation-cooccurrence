#' @title Classify an sjSDM Unit Pipeline Error
#' @description
#' Distinguishes registered data-feasibility outcomes from unexpected pipeline
#' failures using target-level error metadata.
#' @param data_target_errors
#' Data frame containing at least `name` and `error` columns for errors recorded
#' during one unit execution.
#' @return
#' A list with `status`, `reason_code`, `observed_count`, `required_count`,
#' `root_target`, and `root_error`.
#' @details
#' Expected roots must match both a registered target-name pattern and a stable
#' message pattern. Downstream dependency, missing-object, and empty-pattern
#' errors are allowed only as cascades. Known temporal validation cascades are
#' accepted only when the same time slice has a registered expected root. Any
#' other root remains unexpected.
#' @export
classify_sjsdm_unit_pipeline_error <- function(
    data_target_errors = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_target_errors),
    base::all(
      base::c("name", "error") %in% base::colnames(data_target_errors)
    ),
    msg = "data_target_errors must contain name and error columns."
  )

  data_errors <-
    data_target_errors |>
    dplyr::filter(
      !base::is.na(.data[["error"]]),
      base::nzchar(.data[["error"]])
    )

  data_expected_rules <-
    tibble::tribble(
      ~reason_code, ~target_pattern, ~error_pattern,
      "insufficient_cores",
      "^flag_available_core_count_validated(?:_|$)",
      "^Not enough cores in this spatial window[.]",
      "insufficient_samples",
      "^data_sample_ids_checked(?:_|$)",
      "^Too few samples in this time slice to proceed",
      "no_taxa_after_minimum_proportion",
      "^data_community_rare_filtered(?:_|$)",
      "^No taxa found in data[.].*minimum_proportion",
      "no_taxa_after_minimum_core_count",
      "^data_community_filtered_cores(?:_|$)",
      "^No taxa remain after filtering[.].*minimum_core_count",
      "no_taxa_after_minimum_sample_count",
      "^data_community_filtered_samples(?:_|$)",
      "^No taxa remain after filtering[.].*minimum_sample_count",
      "insufficient_taxa",
      "^list_sjsdm_prepared_tuning_folds(?:_|$)",
      "^Too few taxa remain after filtering to run the model[.]",
      "empty_community",
      "^vec_community_taxa(?:_|$)",
      "^No community taxa found in this spatial window[.]",
      "empty_community",
      paste0(
        "^(?:list_abiotic_collinearity|",
        "flag_available_core_count_validated)(?:_|$)"
      ),
      paste0(
        "^(?:Error in tar_make[(][)]: )?cannot branch over empty target ",
        "[(]vec_community_taxa_checked[)]"
      ),
      "no_abiotic_variation",
      "^list_abiotic_collinearity(?:_|$)",
      paste0(
        "^.*No columns with non-zero variance remain after removing",
        "\\s+constant\\s+columns[.]"
      ),
      "insufficient_abiotic_observations",
      "^list_abiotic_collinearity(?:_|$)",
      stringr::str_c(
        "^.*Too few abiotic observations to evaluate predictor ",
        "collinearity[.]"
      ),
      "no_spatial_records",
      "^data_vegvault_extracted(?:_|$)",
      "^VegVault extraction returned zero rows[.]",
      "no_spatial_records",
      "^data_vegvault_extracted(?:_|$)",
      paste0(
        "^Failed to extract VegVault data for this spatial unit[.].*",
        "empty/opaque error message[.]"
      ),
      "no_viable_functional_type_groups",
      "^n_functional_type_groups_selected_(?:continental|continent)(?:_|$)",
      "^No viable k .*non-constant FT groups"
    )
  vec_expected_rule_index <-
    base::seq_len(base::nrow(data_errors)) |>
    purrr::map_int(
      .f = function(index_error) {
        vec_matches <-
          stringr::str_detect(
            data_errors[["name"]][[index_error]],
            data_expected_rules[["target_pattern"]]
          ) &
          stringr::str_detect(
            data_errors[["error"]][[index_error]],
            stringr::regex(
              data_expected_rules[["error_pattern"]],
              dotall = TRUE
            )
          )
        if (
          base::any(vec_matches)
        ) {
          return(base::which(vec_matches)[[1L]])
        }
        return(NA_integer_)
      }
    )
  flag_expected_root <-
    !base::is.na(vec_expected_rule_index)
  data_temporal_cascade_rules <-
    tibble::tribble(
      ~target_pattern, ~error_pattern,
      "^data_abiotic_wide_timeslice_[0-9]+$",
      "^data_sample_ids must be a data frame$",
      "^data_community_model_matrix_timeslice_[0-9]+$",
      "^data_sample_ids must be a data frame$",
      "^data_cross_validation_locations_timeslice_[0-9]+$",
      "^`data_sample_ids` must be a data frame[.]$",
      "^data_community_prepared_timeslice_[0-9]+$",
      "^mat_community must be a matrix$",
      "^data_cross_validation_fold_resolution_timeslice_[0-9]+$",
      "^`n_locations` must be a single positive integer[.]$",
      "^data_cross_validation_grid_candidates_timeslice_[0-9]+$",
      paste0(
        "^`data_fold_resolution` must contain one row and a ",
        "`cv_strategy` column[.]$"
      ),
      "^data_cross_validation_grid_calibration_timeslice_[0-9]+$",
      "^`data_fold_resolution` must contain exactly one row[.]$",
      paste0(
        "^data_cross_validation_(?:assignments_initial|",
        "partition_diagnostics_initial|assignments|",
        "partition_diagnostics)_timeslice_[0-9]+$"
      ),
      "^`data_locations` must be a non-empty data frame[.]$",
      "^data_cross_validation_feasibility_timeslice_[0-9]+$",
      "^`data_partition_diagnostics` must be a data frame[.]$",
      "^list_sjsdm_prepared_tuning_folds_timeslice_[0-9]+$",
      "^argument is of length zero$"
    )
  vec_time_slice <-
    stringr::str_extract(
      data_errors[["name"]],
      "timeslice_[0-9]+$"
    )
  vec_expected_time_slice <-
    vec_time_slice[flag_expected_root] |>
    stats::na.omit() |>
    base::unique()
  flag_temporal_validation_cascade <-
    base::seq_len(base::nrow(data_errors)) |>
    purrr::map_lgl(
      .f = function(index_error) {
        time_slice <- vec_time_slice[[index_error]]
        if (
          base::is.na(time_slice) ||
            !time_slice %in% vec_expected_time_slice
        ) {
          return(FALSE)
        }
        vec_matches <-
          stringr::str_detect(
            data_errors[["name"]][[index_error]],
            data_temporal_cascade_rules[["target_pattern"]]
          ) &
          stringr::str_detect(
            data_errors[["error"]][[index_error]],
            data_temporal_cascade_rules[["error_pattern"]]
          )
        return(base::any(vec_matches))
      }
    )
  flag_dependency_cascade <-
    stringr::str_starts(
      data_errors[["error"]],
      "could not load dependency "
    ) |
    stringr::str_detect(
      data_errors[["error"]],
      "^object ['\"].*['\"] not found$"
    ) |
    stringr::str_detect(
      data_errors[["error"]],
      "^cannot branch over empty target"
    ) |
    flag_temporal_validation_cascade
  flag_expected <-
    base::any(flag_expected_root) &&
    base::all(flag_expected_root | flag_dependency_cascade)

  root_row <-
    if (
      flag_expected
    ) {
      base::which(flag_expected_root)[[1L]]
    } else if (
      base::any(!flag_expected_root & !flag_dependency_cascade)
    ) {
      base::which(
        !flag_expected_root & !flag_dependency_cascade
      )[[1L]]
    } else if (
      base::nrow(data_errors) > 0L
    ) {
      1L
    } else {
      NA_integer_
    }

  reason_code <-
    if (
      !flag_expected ||
      base::is.na(root_row) ||
        base::is.na(vec_expected_rule_index[[root_row]])
    ) {
      NA_character_
    } else {
      data_expected_rules[["reason_code"]][[
        vec_expected_rule_index[[root_row]]
      ]]
    }
  root_error <-
    if (
      base::is.na(root_row)
    ) {
      NA_character_
    } else {
      data_errors[["error"]][[root_row]]
    }
  mat_counts <-
    stringr::str_match(
      root_error,
      stringr::regex(
        "Found\\s+([0-9]+).*?(?:at least|need)\\s+([0-9]+)",
        dotall = TRUE
      )
    )
  observed_count <-
    base::suppressWarnings(base::as.integer(mat_counts[, 2L]))
  required_count <-
    base::suppressWarnings(base::as.integer(mat_counts[, 3L]))
  if (
    base::is.na(observed_count) &&
      reason_code %in%
        base::c(
          "no_taxa_after_minimum_proportion",
          "no_taxa_after_minimum_core_count",
          "no_taxa_after_minimum_sample_count",
          "empty_community",
          "no_abiotic_variation",
          "insufficient_abiotic_observations",
          "no_spatial_records"
        )
  ) {
    observed_count <- 0L
  }

  return(
    base::list(
      status = if (
        flag_expected
      ) {
        "expected_infeasible"
      } else {
        "unexpected_error"
      },
      reason_code = reason_code,
      observed_count = observed_count,
      required_count = required_count,
      root_target = if (
        base::is.na(root_row)
      ) {
        NA_character_
      } else {
        data_errors[["name"]][[root_row]]
      },
      root_error = root_error
    )
  )
}

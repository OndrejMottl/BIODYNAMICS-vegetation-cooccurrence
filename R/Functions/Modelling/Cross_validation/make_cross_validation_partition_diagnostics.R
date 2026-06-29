#' @title Make Cross-Validation Partition Diagnostics
#' @description
#' Calculates full-model and fold-training counts from location assignments and
#' aligned binary community responses for feasibility assessment.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param data_assignments
#' Assignment table returned by a cross-validation assignment helper.
#' @param data_community_matrix
#' Numeric binary matrix with one row per original sample row and one column per
#' taxon. Row positions must match location `row_indices`.
#' @param cv_strategy
#' Character scalar identifying the candidate strategy. Either
#' `"spatially_stratified_group_kfold"` or `"leave_one_location_out"`.
#' @param min_taxon_locations
#' Positive integer minimum number of training locations with a taxon presence.
#' @param min_taxon_samples
#' Positive integer minimum number of training samples with a taxon presence.
#' @param include_full_model
#' Logical scalar. If `TRUE`, prepend the full-model diagnostic row. Defaults
#' to `TRUE`.
#' @return
#' Tibble matching [assess_cross_validation_feasibility()] input, with one
#' optional full-model row and one row per repeat and fold.
#' @details
#' Taxon viability is learned independently within each training partition. A
#' retained binary taxon must meet both occurrence thresholds and contain at
#' least one absence. MEM location counts equal the number of training
#' locations; additional mode-specific MEM checks can raise the threshold in
#' the feasibility assessor.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = c("a", "b"),
#'     n_samples = c(1L, 1L),
#'     row_indices = list(1L, 2L)
#'   )
#' data_assignments <-
#'   make_leave_one_location_out_assignments(data_locations)
#' make_cross_validation_partition_diagnostics(
#'   data_locations = data_locations,
#'   data_assignments = data_assignments,
#'   data_community_matrix = matrix(c(0, 1), ncol = 1L),
#'   cv_strategy = "leave_one_location_out"
#' )
#' @export
make_cross_validation_partition_diagnostics <- function(
    data_locations = NULL,
    data_assignments = NULL,
    data_community_matrix = NULL,
    cv_strategy = NULL,
    min_taxon_locations = 1L,
    min_taxon_samples = 1L,
    include_full_model = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::nrow(data_assignments) > 0L,
    msg = "`data_assignments` must be a non-empty data frame."
  )

  vec_required_location_columns <-
    base::c("location_id", "n_samples", "row_indices")

  vec_required_assignment_columns <-
    base::c("repeat_id", "fold_id", "location_id")

  assertthat::assert_that(
    base::all(
      vec_required_location_columns %in% base::colnames(data_locations)
    ),
    msg = "`data_locations` is missing required columns."
  )

  assertthat::assert_that(
    base::all(
      vec_required_assignment_columns %in%
        base::colnames(data_assignments)
    ),
    msg = "`data_assignments` is missing required columns."
  )

  assertthat::assert_that(
    base::is.matrix(data_community_matrix),
    base::is.numeric(data_community_matrix),
    msg = "`data_community_matrix` must be a numeric matrix."
  )

  assertthat::assert_that(
    base::all(base::is.finite(data_community_matrix)),
    base::all(data_community_matrix %in% base::c(0, 1)),
    msg = "`data_community_matrix` must contain finite binary values."
  )

  vec_taxon_names <-
    base::colnames(data_community_matrix)

  assertthat::assert_that(
    !base::is.null(vec_taxon_names),
    base::length(vec_taxon_names) > 0L,
    !base::any(base::duplicated(vec_taxon_names)),
    msg = "`data_community_matrix` must have unique taxon column names."
  )

  vec_supported_strategies <-
    base::c(
      "spatially_stratified_group_kfold",
      "leave_one_location_out"
    )

  assertthat::assert_that(
    base::is.character(cv_strategy),
    base::length(cv_strategy) == 1L,
    cv_strategy %in% vec_supported_strategies,
    msg = "`cv_strategy` is not supported."
  )

  vec_taxon_thresholds <-
    base::c(min_taxon_locations, min_taxon_samples)

  assertthat::assert_that(
    base::is.numeric(vec_taxon_thresholds),
    base::length(vec_taxon_thresholds) == 2L,
    base::all(base::is.finite(vec_taxon_thresholds)),
    base::all(vec_taxon_thresholds >= 1L),
    base::all(
      vec_taxon_thresholds == base::as.integer(vec_taxon_thresholds)
    ),
    msg = "Taxon occurrence thresholds must be positive integers."
  )

  assertthat::assert_that(
    base::is.logical(include_full_model),
    base::length(include_full_model) == 1L,
    !base::is.na(include_full_model),
    msg = "`include_full_model` must be `TRUE` or `FALSE`."
  )

  min_taxon_locations_integer <-
    base::as.integer(min_taxon_locations)

  min_taxon_samples_integer <-
    base::as.integer(min_taxon_samples)

  vec_location_ids <-
    data_locations |>
    dplyr::pull("location_id") |>
    base::as.character()

  assertthat::assert_that(
    !base::any(base::is.na(vec_location_ids)),
    base::all(base::nzchar(vec_location_ids)),
    !base::any(base::duplicated(vec_location_ids)),
    msg = "Location identifiers must be unique non-missing strings."
  )

  data_sample_locations <-
    data_locations |>
    dplyr::select("location_id", "row_indices") |>
    tidyr::unnest_longer(
      col = "row_indices",
      values_to = "row_index"
    ) |>
    dplyr::mutate(
      row_index = base::as.integer(.data[["row_index"]])
    ) |>
    dplyr::arrange(.data[["row_index"]])

  vec_observed_row_indices <-
    data_sample_locations |>
    dplyr::pull("row_index")

  vec_expected_row_indices <-
    base::seq_len(base::nrow(data_community_matrix))

  if (
    !base::identical(
      vec_observed_row_indices,
      vec_expected_row_indices
    )
  ) {
    cli::cli_abort(
      stringr::str_c(
        "Location row positions must cover every community-matrix row",
        " ",
        "exactly once."
      )
    )
  }

  data_assignment_counts <-
    data_assignments |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["location_id"]],
      name = "assignment_count"
    )

  assertthat::assert_that(
    base::all(
      data_assignment_counts[["assignment_count"]] == 1L
    ),
    msg = "Each location must occur exactly once in every repeat."
  )

  data_repeat_coverage <-
    data_assignments |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      n_locations = dplyr::n_distinct(.data[["location_id"]]),
      all_locations_known = base::all(
        .data[["location_id"]] %in% vec_location_ids
      ),
      .groups = "drop"
    )

  assertthat::assert_that(
    base::all(
      data_repeat_coverage[["n_locations"]] ==
        base::length(vec_location_ids)
    ),
    base::all(data_repeat_coverage[["all_locations_known"]]),
    msg = "Every repeat must cover all known locations exactly once."
  )

  data_candidate_partitions <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::mutate(
      effective_folds = dplyr::n_distinct(.data[["fold_id"]])
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      cv_strategy = cv_strategy,
      train_location_ids = purrr::map2(
        .data[["repeat_id"]],
        .data[["fold_id"]],
        .f = ~ {
          repeat_value <- .x
          fold_value <- .y

          data_assignments |>
            dplyr::filter(
              .data[["repeat_id"]] == repeat_value,
              .data[["fold_id"]] != fold_value
            ) |>
            dplyr::pull("location_id")
        }
      )
    )

  data_full_partition <-
    tibble::tibble(
      cv_strategy = "full_model",
      repeat_id = 0L,
      effective_folds = NA_integer_,
      fold_id = 0L,
      train_location_ids = base::list(vec_location_ids)
    )

  data_partition_specs <-
    if (
      include_full_model
    ) {
      dplyr::bind_rows(
        data_full_partition,
        data_candidate_partitions
      )
    } else {
      data_candidate_partitions
    }

  data_partition_specs_with_counts <-
    data_partition_specs |>
    dplyr::mutate(
      train_row_indices = purrr::map(
        .data[["train_location_ids"]],
        .f = ~ {
          train_locations <- .x

          data_sample_locations |>
            dplyr::filter(
              .data[["location_id"]] %in% train_locations
            ) |>
            dplyr::pull("row_index")
        }
      ),
      n_train_locations = purrr::map_int(
        .data[["train_location_ids"]],
        base::length
      ),
      n_train_samples = purrr::map_int(
        .data[["train_row_indices"]],
        base::length
      ),
      n_train_mem_locations = .data[["n_train_locations"]]
    )

  data_partition_specs_with_taxa <-
    data_partition_specs_with_counts |>
    dplyr::mutate(
      n_train_taxa = purrr::map2_int(
        .data[["train_row_indices"]],
        .data[["train_location_ids"]],
        .f = ~ {
          vec_train_rows <- .x
          vec_train_locations <- .y

          data_community_train <-
            data_community_matrix[
              vec_train_rows,
              ,
              drop = FALSE
            ]

          vec_train_sample_locations <-
            data_sample_locations |>
            dplyr::filter(
              .data[["row_index"]] %in% vec_train_rows,
              .data[["location_id"]] %in% vec_train_locations
            ) |>
            dplyr::arrange(.data[["row_index"]]) |>
            dplyr::pull("location_id")

          vec_taxon_names |>
            purrr::map_lgl(
              .f = ~ {
                taxon_name <- .x

                vec_response <-
                  data_community_train[, taxon_name]

                n_presence_samples <-
                  base::sum(vec_response == 1)

                n_presence_locations <-
                  vec_train_sample_locations[vec_response == 1] |>
                  base::unique() |>
                  base::length()

                n_presence_samples >= min_taxon_samples_integer &&
                  n_presence_locations >= min_taxon_locations_integer &&
                  n_presence_samples < base::length(vec_response)
              }
            ) |>
            base::sum()
        }
      )
    )

  res <-
    data_partition_specs_with_taxa |>
    dplyr::select(
      "cv_strategy",
      "repeat_id",
      "effective_folds",
      "fold_id",
      "n_train_locations",
      "n_train_samples",
      "n_train_taxa",
      "n_train_mem_locations"
    )

  return(res)
}

#' @title Build Community Interpolation Index
#' @description
#' Builds small per-dataset row-range metadata for paleo interpolation.
#' @param data_community
#' A data frame containing a `dataset_name` column. Rows for each dataset
#' must be contiguous.
#' @param data_age_uncertainty
#' A data frame containing a `dataset_name` column. Rows for each dataset
#' must be contiguous. Datasets without uncertainty rows are supported.
#' @return
#' A list of branch metadata objects. Each object contains `dataset_name`,
#' `flag_empty`, and inclusive row ranges for both shared input tables.
#' @details
#' Dynamic `{targets}` branches receive constant-size row ranges instead of
#' nested data frames. This avoids scanning the complete shared inputs and
#' allocating a full-table logical mask in every worker branch.
#' @examples
#' data_community <-
#'   tibble::tibble(
#'     dataset_name = base::c("core_b", "core_a")
#'   )
#' data_age_uncertainty <-
#'   tibble::tibble(
#'     dataset_name = "core_a"
#'   )
#'
#' build_community_interpolation_index(
#'   data_community = data_community,
#'   data_age_uncertainty = data_age_uncertainty
#' )
#' @seealso [interpolate_community_dataset_from_shared_inputs()]
#' @export
build_community_interpolation_index <- function(
    data_community = NULL,
    data_age_uncertainty = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )
  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_community),
    msg = "data_community must contain a `dataset_name` column"
  )
  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty),
    msg = "data_age_uncertainty must be a data frame"
  )
  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_age_uncertainty),
    msg = stringr::str_c(
      "data_age_uncertainty must contain a `dataset_name`",
      "column",
      sep = " "
    )
  )

  if (
    base::nrow(data_community) == 0L
  ) {
    return(
      base::list(
        base::list(
          dataset_name = NA_character_,
          flag_empty = TRUE,
          index_community_row_start = NA_integer_,
          index_community_row_end = NA_integer_,
          index_age_uncertainty_row_start = NA_integer_,
          index_age_uncertainty_row_end = NA_integer_
        )
      )
    )
  }

  vec_community_names <-
    data_community |>
    dplyr::pull("dataset_name")
  vec_uncertainty_names <-
    data_age_uncertainty |>
    dplyr::pull("dataset_name")

  assertthat::assert_that(
    !base::anyNA(vec_community_names),
    msg = "data_community dataset_name values must not be missing"
  )
  assertthat::assert_that(
    !base::anyNA(vec_uncertainty_names),
    msg = "data_age_uncertainty dataset_name values must not be missing"
  )

  data_community_runs <-
    tibble::tibble(
      dataset_name = base::rle(vec_community_names)[["values"]],
      row_count = base::rle(vec_community_names)[["lengths"]]
    ) |>
    dplyr::mutate(
      index_row_end = base::cumsum(.data[["row_count"]]),
      index_row_start = .data[["index_row_end"]] -
        .data[["row_count"]] + 1L
    )

  assertthat::assert_that(
    !base::anyDuplicated(data_community_runs[["dataset_name"]]),
    msg = "Rows for each dataset in data_community must be contiguous"
  )

  if (
    base::length(vec_uncertainty_names) == 0L
  ) {
    data_uncertainty_runs <-
      tibble::tibble(
        dataset_name = base::character(),
        index_row_start = base::integer(),
        index_row_end = base::integer()
      )
  } else {
    data_uncertainty_runs <-
      tibble::tibble(
        dataset_name = base::rle(vec_uncertainty_names)[["values"]],
        row_count = base::rle(vec_uncertainty_names)[["lengths"]]
      ) |>
      dplyr::mutate(
        index_row_end = base::cumsum(.data[["row_count"]]),
        index_row_start = .data[["index_row_end"]] -
          .data[["row_count"]] + 1L
      )

    assertthat::assert_that(
      !base::anyDuplicated(data_uncertainty_runs[["dataset_name"]]),
      msg = base::paste(
        "Rows for each dataset in data_age_uncertainty must be",
        "contiguous"
      )
    )
  }

  data_interpolation_index <-
    data_community_runs |>
    dplyr::select(
      "dataset_name",
      index_community_row_start = "index_row_start",
      index_community_row_end = "index_row_end"
    ) |>
    dplyr::left_join(
      data_uncertainty_runs |>
        dplyr::select(
          "dataset_name",
          index_age_uncertainty_row_start = "index_row_start",
          index_age_uncertainty_row_end = "index_row_end"
        ),
      by = "dataset_name"
    ) |>
    dplyr::arrange(.data[["dataset_name"]])

  res_interpolation_index <-
    data_interpolation_index |>
    purrr::pmap(
      .f = function(
          dataset_name,
          index_community_row_start,
          index_community_row_end,
          index_age_uncertainty_row_start,
          index_age_uncertainty_row_end) {
        return(
          base::list(
            dataset_name = dataset_name,
            flag_empty = FALSE,
            index_community_row_start =
              base::as.integer(index_community_row_start),
            index_community_row_end =
              base::as.integer(index_community_row_end),
            index_age_uncertainty_row_start =
              base::as.integer(index_age_uncertainty_row_start),
            index_age_uncertainty_row_end =
              base::as.integer(index_age_uncertainty_row_end)
          )
        )
      }
    )

  return(res_interpolation_index)
}

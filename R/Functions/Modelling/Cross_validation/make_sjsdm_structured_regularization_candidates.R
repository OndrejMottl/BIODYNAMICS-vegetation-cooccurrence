#' @title Make Structured sjSDM Regularization Candidates
#' @description
#' Builds a deterministic first-pass coordinate search around one reference
#' regularization candidate without creating a Cartesian product.
#' @param alpha_cov,alpha_coef,alpha_spatial
#' Fixed finite elastic-net mixing values between zero and one.
#' @param lambda_cov_reference,lambda_coef_reference
#' Reference covariance and abiotic-coefficient lambda values.
#' @param lambda_spatial_reference
#' Reference spatial-coefficient lambda value.
#' @param lambda_values
#' Unique finite non-negative values searched separately along each lambda
#' axis. The vector must contain every reference value, with each reference
#' strictly inside the search range.
#' @return
#' Named list containing `data_candidates`, which follows the production
#' tuning-candidate schema, and `data_search_design`, which records the varied
#' axis, axis value, reference status, and lower/upper boundary flags.
#' @details
#' The reference candidate appears once. Every other candidate changes exactly
#' one lambda while holding the remaining lambdas at their reference values.
#' With six shared lambda values and one shared reference, this produces 16
#' candidates instead of a 216-row Cartesian product. Input order does not
#' affect candidate identifiers.
#' @examples
#' make_sjsdm_structured_regularization_candidates(
#'   lambda_values = c(0, 0.01, 0.03, 0.1, 0.3, 1)
#' )
#' @export
make_sjsdm_structured_regularization_candidates <- function(
    alpha_cov = 0.5,
    alpha_coef = 0.5,
    alpha_spatial = 0.5,
    lambda_cov_reference = 0.1,
    lambda_coef_reference = 0.1,
    lambda_spatial_reference = 0.1,
    lambda_values = base::c(0, 0.01, 0.03, 0.1, 0.3, 1)) {
  list_alpha_values <-
    base::list(
      alpha_cov = alpha_cov,
      alpha_coef = alpha_coef,
      alpha_spatial = alpha_spatial
    )

  purrr::iwalk(
    .x = list_alpha_values,
    .f = ~ {
      flag_valid_alpha <-
        base::is.numeric(.x) &&
        base::length(.x) == 1L &&
        base::is.finite(.x) &&
        .x >= 0 &&
        .x <= 1

      assertthat::assert_that(
        flag_valid_alpha,
        msg = stringr::str_glue(
          "`{.y}` must be one finite value between zero and one."
        )
      )
    }
  )

  list_reference_values <-
    base::list(
      lambda_cov = lambda_cov_reference,
      lambda_coef = lambda_coef_reference,
      lambda_spatial = lambda_spatial_reference
    )

  flag_valid_references <-
    purrr::every(
      list_reference_values,
      ~ base::is.numeric(.x) &&
        base::length(.x) == 1L &&
        base::is.finite(.x) &&
        .x >= 0
    )

  assertthat::assert_that(
    flag_valid_references,
    msg = "Reference lambdas must be finite non-negative scalars."
  )

  flag_valid_lambda_values <-
    base::is.numeric(lambda_values) &&
    base::length(lambda_values) >= 3L &&
    base::all(base::is.finite(lambda_values)) &&
    base::all(lambda_values >= 0) &&
    !base::any(base::duplicated(lambda_values))

  assertthat::assert_that(
    flag_valid_lambda_values,
    msg = stringr::str_c(
      "lambda_values must contain at least three unique finite",
      " non-negative values."
    )
  )

  vec_lambda_values <-
    base::sort(base::as.numeric(lambda_values))

  vec_reference_values <-
    list_reference_values |>
    base::unlist(use.names = TRUE) |>
    base::as.numeric()

  assertthat::assert_that(
    base::all(vec_reference_values %in% vec_lambda_values),
    msg = "lambda_values must contain every reference lambda."
  )

  assertthat::assert_that(
    base::all(vec_reference_values > base::min(vec_lambda_values)),
    base::all(vec_reference_values < base::max(vec_lambda_values)),
    msg = "Every reference lambda must lie strictly inside the search range."
  )

  data_reference <-
    tibble::tibble(
      search_axis = "reference",
      axis_value = NA_real_,
      alpha_cov = alpha_cov,
      alpha_coef = alpha_coef,
      alpha_spatial = alpha_spatial,
      lambda_cov = lambda_cov_reference,
      lambda_coef = lambda_coef_reference,
      lambda_spatial = lambda_spatial_reference
    )

  list_axis_candidates <-
    purrr::imap(
      .x = list_reference_values,
      .f = ~ {
        vec_axis_values <-
          vec_lambda_values[vec_lambda_values != .x]

        vec_lambda_cov <-
          if (
            .y == "lambda_cov"
          ) {
            vec_axis_values
          } else {
            base::rep(lambda_cov_reference, base::length(vec_axis_values))
          }

        vec_lambda_coef <-
          if (
            .y == "lambda_coef"
          ) {
            vec_axis_values
          } else {
            base::rep(lambda_coef_reference, base::length(vec_axis_values))
          }

        vec_lambda_spatial <-
          if (
            .y == "lambda_spatial"
          ) {
            vec_axis_values
          } else {
            base::rep(
              lambda_spatial_reference,
              base::length(vec_axis_values)
            )
          }

        tibble::tibble(
          search_axis = .y,
          axis_value = vec_axis_values,
          alpha_cov = alpha_cov,
          alpha_coef = alpha_coef,
          alpha_spatial = alpha_spatial,
          lambda_cov = vec_lambda_cov,
          lambda_coef = vec_lambda_coef,
          lambda_spatial = vec_lambda_spatial
        )
      }
    )

  data_candidate_design <-
    base::c(base::list(data_reference), list_axis_candidates) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      candidate_id = stringr::str_c(
        "candidate_",
        base::sprintf("%03d", base::seq_len(dplyr::n()))
      ),
      .before = 1L
    )

  data_candidates <-
    data_candidate_design |>
    dplyr::select(
      "candidate_id",
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial"
    )

  data_search_design <-
    data_candidate_design |>
    dplyr::mutate(
      is_reference = .data[["search_axis"]] == "reference",
      is_lower_search_boundary =
        !.data[["is_reference"]] &
        .data[["axis_value"]] == base::min(vec_lambda_values),
      is_upper_search_boundary =
        !.data[["is_reference"]] &
        .data[["axis_value"]] == base::max(vec_lambda_values)
    ) |>
    dplyr::select(
      "candidate_id",
      "search_axis",
      "axis_value",
      "is_reference",
      "is_lower_search_boundary",
      "is_upper_search_boundary"
    )

  res <-
    base::list(
      data_candidates = data_candidates,
      data_search_design = data_search_design
    )

  return(res)
}

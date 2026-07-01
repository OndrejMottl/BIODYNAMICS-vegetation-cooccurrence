#' @title Make sjSDM Regularization Candidates
#' @description
#' Builds a deterministic Cartesian product of configured sjSDM alpha and
#' lambda values for project-owned cross-validation tuning.
#' @param alpha_cov,alpha_coef,alpha_spatial
#' Non-empty numeric vectors of unique finite alpha values between zero and
#' one, inclusive.
#' @param lambda_cov,lambda_coef,lambda_spatial
#' Non-empty numeric vectors of unique finite non-negative lambda values.
#' @return
#' Tibble with one row per unique candidate. Columns are `candidate_id`, the
#' three alpha values, and the three lambda values. Rows are sorted by the six
#' parameter values and IDs use deterministic zero-padded sequence numbers.
#' @details
#' Input order does not affect the returned table. The same configured value
#' sets therefore produce the same candidate IDs in every fold and repeat.
#' @examples
#' make_sjsdm_regularization_candidates(
#'   alpha_cov = c(0, 0.5),
#'   lambda_cov = c(0, 0.1)
#' )
#' @export
make_sjsdm_regularization_candidates <- function(
    alpha_cov = 0.5,
    alpha_coef = 0.5,
    alpha_spatial = 0.5,
    lambda_cov = 0,
    lambda_coef = 0,
    lambda_spatial = 0) {
  list_alpha_values <-
    base::list(
      alpha_cov = alpha_cov,
      alpha_coef = alpha_coef,
      alpha_spatial = alpha_spatial
    )

  purrr::iwalk(
    .x = list_alpha_values,
    .f = ~ {
      flag_valid <-
        base::is.numeric(.x) &&
        base::length(.x) > 0L &&
        base::all(base::is.finite(.x)) &&
        base::all(.x >= 0) &&
        base::all(.x <= 1) &&
        !base::any(base::duplicated(.x))

      assertthat::assert_that(
        flag_valid,
        msg = stringr::str_glue(
          "`{.y}` must contain unique finite values between 0 and 1."
        )
      )
    }
  )

  list_lambda_values <-
    base::list(
      lambda_cov = lambda_cov,
      lambda_coef = lambda_coef,
      lambda_spatial = lambda_spatial
    )

  purrr::iwalk(
    .x = list_lambda_values,
    .f = ~ {
      flag_valid <-
        base::is.numeric(.x) &&
        base::length(.x) > 0L &&
        base::all(base::is.finite(.x)) &&
        base::all(.x >= 0) &&
        !base::any(base::duplicated(.x))

      assertthat::assert_that(
        flag_valid,
        msg = stringr::str_glue(
          "`{.y}` must contain unique finite non-negative values."
        )
      )
    }
  )

  res <-
    tidyr::expand_grid(
      alpha_cov = base::sort(base::as.numeric(alpha_cov)),
      alpha_coef = base::sort(base::as.numeric(alpha_coef)),
      alpha_spatial = base::sort(base::as.numeric(alpha_spatial)),
      lambda_cov = base::sort(base::as.numeric(lambda_cov)),
      lambda_coef = base::sort(base::as.numeric(lambda_coef)),
      lambda_spatial = base::sort(base::as.numeric(lambda_spatial))
    ) |>
    dplyr::arrange(
      .data[["alpha_cov"]],
      .data[["alpha_coef"]],
      .data[["alpha_spatial"]],
      .data[["lambda_cov"]],
      .data[["lambda_coef"]],
      .data[["lambda_spatial"]]
    ) |>
    dplyr::mutate(
      candidate_id = stringr::str_c(
        "candidate_",
        base::sprintf("%03d", base::seq_len(dplyr::n()))
      ),
      .before = 1L
    )

  return(res)
}

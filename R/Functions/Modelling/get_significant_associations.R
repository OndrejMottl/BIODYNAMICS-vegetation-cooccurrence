#' @title Get Significant Species Associations
#' @description
#' Identifies significant species associations based on support and mean
#' values.
#' @param data_source
#' A list containing association matrices from a fitted Hmsc model.
#' Generally, this is the output of the function get_species_association().
#' @param alpha
#' Significance level for support threshold (default: 0.05).
#' @return
#' A vector of significant association values.
#' @seealso [get_species_association()]
#' @export
get_significant_associations <- function(data_source, alpha = 0.05) {
  assertthat::assert_that(
    is.list(data_source),
    msg = "The data source must be a list."
  )

  support_threshold <- 1 - alpha

  assertthat::assert_that(
    is.numeric(support_threshold) && support_threshold > 0 && support_threshold < 1,
    msg = "The support threshold must be a numeric value between 0 and 1."
  )

  data_work <-
    purrr::pluck(data_source, 1)

  assertthat::assert_that(
    is.list(data_work) && length(data_work) == 2,
    msg = "The data work must be a list with two elements.F"
  )

  data_support <-
    purrr::chuck(data_work, "support")

  data_mean <-
    purrr::pluck(data_work, "mean")

  vec_data_support <-
    data_support[lower.tri(data_support, diag = FALSE)]

  vec_data_mean <-
    data_mean[lower.tri(data_mean, diag = FALSE)]

  assertthat::assert_that(
    is.numeric(vec_data_support) && is.numeric(vec_data_mean),
    msg = "The support and mean values must be numeric vectors."
  )

  n_values <- length(vec_data_support)

  vec_significant <- (
    (
      vec_data_support > support_threshold
    ) +
      (
        vec_data_support < (1 - support_threshold)
      ) > 0
  ) *
    vec_data_mean

  n_significant <- sum(vec_significant, na.rm = TRUE)

  res <-
    list(
      n_associations = n_values,
      n_significant = n_significant,
      proportion_significant = n_significant / n_values
    )

  return(res)
}

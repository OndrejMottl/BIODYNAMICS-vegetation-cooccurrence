#' @title Get Significant Species Associations
#' @description
#' Identifies significant species associations based on support and mean
#' values for each error level.
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

  assertthat::assert_that(
    is.list(data_source) && length(data_source) > 0,
    msg = "The data source is list and not empty."
  )

  assertthat::assert_that(
    purrr::map_lgl(
      .x = data_source,
      .f = ~ is.list(.x) && all(c("mean", "support") %in% names(.x))
    ) %>%
      all(),
    msg = "The data source must contain lists with 'mean' and 'support' matrices."
  )

  result <-
    data_source %>%
    purrr::map(
      .f = ~ {
        vec_data_support <-
          purrr::pluck(.x, "support") %>%
          {
            .[lower.tri(., diag = FALSE)]
          }

        assertthat::assert_that(
          is.numeric(vec_data_support),
          msg = "The support values must be numeric vectors."
        )

        n_values <- length(vec_data_support)

        vec_significant <- (
          (vec_data_support > support_threshold) +
            ((vec_data_support < (1 - support_threshold)) > 0)
        )

        n_significant <- sum(vec_significant, na.rm = TRUE)

        res <-
          list(
            n_associations = n_values,
            n_significant = n_significant,
            proportion_significant = n_significant / n_values
          )
      }
    )

  return(result)
}

#' @title Select Better Model Based on Fit
#' @description
#' Compares two models and selects the one with better fit based on Tjur's R2.
#' @param list_models
#' A list of two fitted model objects.
#' @return
#' The model object with better fit.
#' @export
get_better_model_based_on_fit <- function(list_models) {
  assertthat::assert_that(
    is.list(list_models),
    msg = "list_models must be a list of models"
  )

  assertthat::assert_that(
    length(list_models) == 2,
    msg = "list_models must be a list of two models"
  )

  assertthat::assert_that(
    !is.null(list_models[[1]]),
    msg = "The first model in list_models must not be NULL"
  )

  assertthat::assert_that(
    !is.null(list_models[[2]]),
    msg = "The second model in list_models must not be NULL"
  )

  mod_null <-
    list_models %>%
    purrr::chuck(1)

  mod_full <-
    list_models %>%
    purrr::chuck(2)

  # by default select the null model
  res <- mod_null

  null_r2 <-
    mod_null %>%
    purrr::chuck("eval", "TjurR2")

  full_r2 <-
    mod_full %>%
    purrr::chuck("eval", "TjurR2")

  n_r2 <- length(null_r2)

  n_better_r2 <-
    sum(
      null_r2 < full_r2,
      na.rm = TRUE
    )

  if (
    n_r2 / n_better_r2 >= 0.5
  ) {
    res <-
      mod_full
  }

  return(res)
}

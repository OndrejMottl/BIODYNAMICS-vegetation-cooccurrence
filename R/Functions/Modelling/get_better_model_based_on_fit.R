get_better_model_based_on_fit <- function(list_models) {
  assertthat::assert_that(
    is.list(list_models),
    msg = "list_models must be a list of models"
  )

  assertthat::assert_that(
    length(list_models) == 2,
    msg = "list_models must be a list of two models"
  )

  res <-
    list_models %>%
    purrr::chuck(1)

  null_r2 <-
    list_models %>%
    purrr::chuck(1, "TjurR2")

  full_r2 <-
    list_models %>%
    purrr::chuck(2, "TjurR2")

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
      list_models %>%
      purrr::chuck(2)
  }

  return(res)
}

get_species_association <- function(data_sourse) {
  assertthat::assert_that(
    is.list(data_sourse),
    msg = "data_sourse must be a list"
  )

  mod <-
    data_sourse %>%
    purrr::chuck("mod")

  assertthat::assert_that(
    assertthat::are_equal(
      class(mod),
      "Hmsc",
      msg = "data_sourse must be of class Hmsc"
    )
  )

  res <-
    Hmsc::computeAssociations(mod)

  return(res)
}

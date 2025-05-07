get_species_association <- function(data_sourse) {
  assertthat::assert_that(
    assertthat::are_equal(
      class(data_sourse),
      "Hmsc",
      msg = "data_sourse must be of class Hmsc"
    )
  )

  Hmsc::computeAssociations(data_sourse) %>%
    return()
}

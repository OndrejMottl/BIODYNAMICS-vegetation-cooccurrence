#' @title Compute Species Associations
#' @description
#' Computes species associations from a fitted Hmsc model object.
#' @param data_sourse
#' A list containing a fitted Hmsc model under the 'mod' element.
#' Generally, this is the output of the function get_better_model_based_on_fit()
#' @return
#' A matrix of species associations.
#' @seealso [get_better_model_based_on_fit()]
#' @export
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

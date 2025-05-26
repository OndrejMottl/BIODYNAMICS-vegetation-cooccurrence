#' @title Compute Species Associations
#' @description
#' Computes species associations from a fitted Hmsc model object.
#' @param data_source
#' A list containing a fitted Hmsc model under the 'mod' element.
#' Generally, this is the output of the function add_model_evaluation() or
#' # get_better_model_based_on_fit()
#' @return
#' A matrix of species associations.
#' @seealso [add_model_evaluation(), get_better_model_based_on_fit()]
#' @export
get_species_association <- function(data_source) {
  assertthat::assert_that(
    is.list(data_source),
    msg = "data_source must be a list"
  )

  mod <-
    data_source %>%
    purrr::chuck("mod")

  assertthat::assert_that(
    assertthat::are_equal(
      class(mod),
      "Hmsc",
      msg = "data_source must be of class Hmsc"
    )
  )

  res <-
    Hmsc::computeAssociations(mod) %>%
    purrr::set_names(
      nm = mod %>%
        purrr::chuck("ranLevelsUsed")
    )

  return(res)
}

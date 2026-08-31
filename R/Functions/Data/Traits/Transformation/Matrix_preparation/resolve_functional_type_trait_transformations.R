#' @title Resolve Functional-Type Trait Transformations
#' @description
#' Resolves one supported functional-type sensitivity variant to its explicit
#' named trait-transformation contract.
#' @param trait_variant_id Character scalar identifying the sensitivity
#' variant. Supported values are "all_six", "without_lma",
#' "without_nitrogen", "without_lma_nitrogen", and "without_ssd".
#' @return A named character vector of trait transformations.
#' @details
#' The primary analysis uses all six traits. Sensitivity variants remove
#' provisional-unit traits individually or together, or remove stem specific
#' density to test sensitivity to its source uncertainty.
#' @examples
#' resolve_functional_type_trait_transformations("all_six")
#' resolve_functional_type_trait_transformations("without_lma")
#' @export
resolve_functional_type_trait_transformations <- function(
    trait_variant_id = "all_six") {
  assertthat::assert_that(
    base::is.character(trait_variant_id),
    base::length(trait_variant_id) == 1L,
    !base::is.na(trait_variant_id),
    base::nzchar(trait_variant_id),
    msg = "trait_variant_id must be one non-empty character value."
  )

  list_excluded_domains <-
    base::list(
      all_six = base::character(),
      without_lma = "Leaf mass per area",
      without_nitrogen =
        "Leaf nitrogen content per unit mass",
      without_lma_nitrogen =
        base::c(
          "Leaf mass per area",
          "Leaf nitrogen content per unit mass"
        ),
      without_ssd = "Stem specific density"
    )

  if (
    !trait_variant_id %in% base::names(list_excluded_domains)
  ) {
    cli::cli_abort("Unknown functional-type trait variant.")
  }

  vec_transformations_all <-
    stats::setNames(
      object = base::c(
        "log10",
        "log10",
        "log10",
        "identity",
        "log10",
        "identity"
      ),
      nm = base::c(
        "Diaspore mass",
        "Leaf Area",
        "Leaf mass per area",
        "Leaf nitrogen content per unit mass",
        "Plant heigh",
        "Stem specific density"
      )
    )
  vec_excluded_domains <-
    purrr::chuck(list_excluded_domains, trait_variant_id)
  vec_transformations_selected <-
    vec_transformations_all[
      !base::names(vec_transformations_all) %in%
        vec_excluded_domains
    ]

  return(vec_transformations_selected)
}

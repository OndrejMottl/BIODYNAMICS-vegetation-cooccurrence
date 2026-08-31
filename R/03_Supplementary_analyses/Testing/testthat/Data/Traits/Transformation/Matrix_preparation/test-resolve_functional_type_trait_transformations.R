testthat::test_that(
  "functional-type trait variants resolve to explicit contracts",
  {
    vec_all_six <-
      resolve_functional_type_trait_transformations("all_six")
    vec_without_lma <-
      resolve_functional_type_trait_transformations("without_lma")
    vec_without_nitrogen <-
      resolve_functional_type_trait_transformations("without_nitrogen")
    vec_without_both <-
      resolve_functional_type_trait_transformations(
        "without_lma_nitrogen"
      )
    vec_without_ssd <-
      resolve_functional_type_trait_transformations("without_ssd")

    testthat::expect_length(vec_all_six, 6L)
    testthat::expect_false("Leaf mass per area" %in%
      base::names(vec_without_lma))
    testthat::expect_false(
      "Leaf nitrogen content per unit mass" %in%
        base::names(vec_without_nitrogen)
    )
    testthat::expect_length(vec_without_both, 4L)
    testthat::expect_false("Stem specific density" %in%
      base::names(vec_without_ssd))
  }
)

testthat::test_that(
  "functional-type trait variants fail closed on unknown identifiers",
  {
    testthat::expect_error(
      resolve_functional_type_trait_transformations("invented"),
      regexp = "Unknown functional-type trait variant"
    )
  }
)

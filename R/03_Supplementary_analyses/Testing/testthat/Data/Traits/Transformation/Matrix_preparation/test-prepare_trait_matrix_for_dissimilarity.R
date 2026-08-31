testthat::test_that(
  "trait matrix preparation applies the explicit domain contract",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        `Diaspore mass` = base::c(1, 100),
        `Stem specific density` = base::c(0.25, 0.5),
        `Leaf mass per area` = base::c(NA_real_, 0.01)
      )
    vec_transformations <-
      base::c(
        `Diaspore mass` = "log10",
        `Stem specific density` = "identity",
        `Leaf mass per area` = "log10"
      )

    data_prepared <-
      prepare_trait_matrix_for_dissimilarity(
        data_trait_table = data_traits,
        vec_trait_transformations = vec_transformations
      )

    testthat::expect_identical(
      data_prepared[["taxon_name"]],
      data_traits[["taxon_name"]]
    )
    testthat::expect_equal(
      data_prepared[["Diaspore mass"]],
      base::c(0, 2)
    )
    testthat::expect_equal(
      data_prepared[["Stem specific density"]],
      base::c(0.25, 0.5)
    )
    testthat::expect_equal(
      data_prepared[["Leaf mass per area"]],
      base::c(NA_real_, -2)
    )
    testthat::expect_identical(
      base::names(data_prepared),
      base::names(data_traits)
    )
  }
)

testthat::test_that(
  "trait matrix preparation fails closed on malformed contracts",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "A",
        `Plant heigh` = 10,
        `Leaf Area` = 2
      )

    testthat::expect_error(
      prepare_trait_matrix_for_dissimilarity(
        data_trait_table = data_traits,
        vec_trait_transformations =
          stats::setNames("log10", "Imaginary trait")
      ),
      regexp = "available traits"
    )
    testthat::expect_error(
      prepare_trait_matrix_for_dissimilarity(
        data_trait_table = data_traits,
        vec_trait_transformations = base::c(
          `Plant heigh` = "square_root",
          `Leaf Area` = "log10"
        )
      ),
      regexp = "identity.*log10"
    )
  }
)

testthat::test_that(
  "trait matrix preparation rejects nonpositive log values",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        `Plant heigh` = base::c(0, 10)
      )

    testthat::expect_error(
      prepare_trait_matrix_for_dissimilarity(
        data_trait_table = data_traits,
        vec_trait_transformations =
          base::c(`Plant heigh` = "log10")
      ),
      regexp = "strictly positive"
    )
  }
)

testthat::test_that(
  "trait matrix preparation selects only contracted sensitivity traits",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        `Leaf Area` = base::c(1, 100),
        `Leaf mass per area` = base::c(2, 20)
      )

    data_prepared <-
      prepare_trait_matrix_for_dissimilarity(
        data_trait_table = data_traits,
        vec_trait_transformations =
          base::c(`Leaf Area` = "log10")
      )

    testthat::expect_identical(
      base::names(data_prepared),
      base::c("taxon_name", "Leaf Area")
    )
  }
)

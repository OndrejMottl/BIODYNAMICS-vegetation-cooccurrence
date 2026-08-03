testthat::test_that(
  "extract_community_taxa() returns unique taxa in first-seen order",
  {
    data_community <-
      tibble::tibble(
        taxon = base::c("Pinus", "Betula", "Pinus", "Quercus")
      )

    vec_community_taxa <-
      extract_community_taxa(data_community = data_community)

    testthat::expect_type(
      vec_community_taxa,
      "character"
    )
    testthat::expect_identical(
      vec_community_taxa,
      base::c("Pinus", "Betula", "Quercus")
    )
  }
)

testthat::test_that(
  "extract_community_taxa() validates its input contract",
  {
    testthat::expect_error(
      extract_community_taxa(data_community = NULL),
      "must be a data frame"
    )
    testthat::expect_error(
      extract_community_taxa(
        data_community = tibble::tibble(other = "Pinus")
      ),
      "must contain a `taxon` column"
    )
  }
)

testthat::test_that(
  "extract_community_taxa() rejects empty communities",
  {
    data_community <-
      tibble::tibble(taxon = base::character())

    testthat::expect_error(
      extract_community_taxa(data_community = data_community),
      "No community taxa found"
    )
  }
)

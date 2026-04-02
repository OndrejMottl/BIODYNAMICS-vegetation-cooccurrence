testthat::test_that(
  "extract_traits_from_vegvault() errors for non-character path",
  {
    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = 123,
        sel_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = TRUE,
        sel_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = base::list("a.sqlite"),
        sel_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "extract_traits_from_vegvault() errors for path length > 1",
  {
    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = base::c("a.sqlite", "b.sqlite"),
        sel_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "extract_traits_from_vegvault() errors for invalid domains",
  {
    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = "somefile.sqlite",
        sel_trait_domain_names = 123
      )
    )

    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = "somefile.sqlite",
        sel_trait_domain_names = NULL
      )
    )

    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = "somefile.sqlite",
        sel_trait_domain_names = base::character(0)
      )
    )

    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = "somefile.sqlite",
        sel_trait_domain_names = TRUE
      )
    )
  }
)

testthat::test_that(
  "extract_traits_from_vegvault() errors for missing database",
  {
    testthat::expect_error(
      extract_traits_from_vegvault(
        path_to_vegvault = "nonexistent_path.sqlite",
        sel_trait_domain_names = "SLA"
      )
    )
  }
)

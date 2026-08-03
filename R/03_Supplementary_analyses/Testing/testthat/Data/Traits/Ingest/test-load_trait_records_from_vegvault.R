testthat::test_that(
  "load_trait_records_from_vegvault() errors for non-character path",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = 123,
        vec_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = TRUE,
        vec_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = base::list("a.sqlite"),
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for path length > 1",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = base::c("a.sqlite", "b.sqlite"),
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for invalid domains",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = 123
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = NULL
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = base::character(0)
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = TRUE
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for missing database",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "nonexistent_path.sqlite",
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

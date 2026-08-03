testthat::test_that(
  "summarise_trait_coverage() validates community_taxa",
  {
    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = 123,
        data_trait_table = data_trait
      )
    )

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = base::character(0),
        data_trait_table = data_trait
      )
    )

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = NULL,
        data_trait_table = data_trait
      )
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() validates data_trait_table",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = "not a data frame"
      )
    )

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = NULL
      )
    )

    testthat::expect_error(
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = tibble::tibble(
          genus_name = base::c("Genus_A")
        )
      )
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() returns list with correct names",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_true(base::is.list(res))

    expected_names <-
      base::c(
        "n_community_taxa",
        "n_covered_taxa",
        "coverage_percent",
        "missing_taxa",
        "extra_taxa"
      )

    testthat::expect_named(
      res,
      expected_names,
      ignore.order = TRUE
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() result elements have correct types",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_true(
      base::is.numeric(
        purrr::chuck(res, "n_community_taxa")
      )
    )

    testthat::expect_true(
      base::is.numeric(purrr::chuck(res, "n_covered_taxa"))
    )

    testthat::expect_true(
      base::is.numeric(purrr::chuck(res, "coverage_percent"))
    )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(res, "missing_taxa")
      )
    )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(res, "extra_taxa")
      )
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() computes correct coverage values",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B", "Genus_C", "Genus_D")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B", "Genus_E")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_community_taxa"),
      4L
    )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered_taxa"),
      2L
    )

    testthat::expect_equal(
      purrr::chuck(res, "coverage_percent"),
      50.0
    )

    vec_missing <-
      base::sort(purrr::chuck(res, "missing_taxa"))

    testthat::expect_equal(
      vec_missing,
      base::c("Genus_C", "Genus_D")
    )

    testthat::expect_equal(
      purrr::chuck(res, "extra_taxa"),
      "Genus_E"
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() handles 100% coverage correctly",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered_taxa"),
      purrr::chuck(res, "n_community_taxa")
    )

    testthat::expect_equal(
      purrr::chuck(res, "coverage_percent"),
      100.0
    )

    testthat::expect_length(
      purrr::chuck(res, "missing_taxa"),
      0L
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() handles 0% coverage correctly",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_C", "Genus_D")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered_taxa"),
      0L
    )

    testthat::expect_equal(
      purrr::chuck(res, "coverage_percent"),
      0.0
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() rounds coverage_percent to 1 decimal",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B", "Genus_C")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    res <-
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    pct <-
      purrr::chuck(res, "coverage_percent")

    testthat::expect_equal(
      base::round(pct, 1),
      pct
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() emits a message to the console",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    testthat::expect_message(
      summarise_trait_coverage(
        community_taxa = vec_taxa,
        data_trait_table = data_trait
      )
    )
  }
)

testthat::test_that(
  "summarise_trait_coverage() can suppress console messages",
  {
    data_trait_table <-
      tibble::tibble(taxon_name = "Taxon A")

    testthat::expect_silent(
      summarise_trait_coverage(
        community_taxa = "Taxon A",
        data_trait_table = data_trait_table,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "check_trait_coverage() validates vec_community_taxa",
  {
    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = 123,
        data_trait_table = data_trait
      )
    )

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = base::character(0),
        data_trait_table = data_trait
      )
    )

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = NULL,
        data_trait_table = data_trait
      )
    )
  }
)

testthat::test_that(
  "check_trait_coverage() validates data_trait_table",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = "not a data frame"
      )
    )

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = NULL
      )
    )

    testthat::expect_error(
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = tibble::tibble(
          genus_name = base::c("Genus_A")
        )
      )
    )
  }
)

testthat::test_that(
  "check_trait_coverage() returns list with correct names",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_true(base::is.list(res))

    expected_names <-
      base::c(
        "n_community_taxa",
        "n_covered",
        "pct_covered",
        "vec_missing_taxa",
        "vec_extra_taxa"
      )

    testthat::expect_named(
      res,
      expected_names,
      ignore.order = TRUE
    )
  }
)

testthat::test_that(
  "check_trait_coverage() result elements have correct types",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_true(
      base::is.numeric(
        purrr::chuck(res, "n_community_taxa")
      )
    )

    testthat::expect_true(
      base::is.numeric(purrr::chuck(res, "n_covered"))
    )

    testthat::expect_true(
      base::is.numeric(purrr::chuck(res, "pct_covered"))
    )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(res, "vec_missing_taxa")
      )
    )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(res, "vec_extra_taxa")
      )
    )
  }
)

testthat::test_that(
  "check_trait_coverage() computes correct coverage values",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B", "Genus_C", "Genus_D")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B", "Genus_E")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_community_taxa"),
      4L
    )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered"),
      2L
    )

    testthat::expect_equal(
      purrr::chuck(res, "pct_covered"),
      50.0
    )

    vec_missing <-
      base::sort(purrr::chuck(res, "vec_missing_taxa"))

    testthat::expect_equal(
      vec_missing,
      base::c("Genus_C", "Genus_D")
    )

    testthat::expect_equal(
      purrr::chuck(res, "vec_extra_taxa"),
      "Genus_E"
    )
  }
)

testthat::test_that(
  "check_trait_coverage() handles 100% coverage correctly",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered"),
      purrr::chuck(res, "n_community_taxa")
    )

    testthat::expect_equal(
      purrr::chuck(res, "pct_covered"),
      100.0
    )

    testthat::expect_length(
      purrr::chuck(res, "vec_missing_taxa"),
      0L
    )
  }
)

testthat::test_that(
  "check_trait_coverage() handles 0% coverage correctly",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_C", "Genus_D")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    testthat::expect_equal(
      purrr::chuck(res, "n_covered"),
      0L
    )

    testthat::expect_equal(
      purrr::chuck(res, "pct_covered"),
      0.0
    )
  }
)

testthat::test_that(
  "check_trait_coverage() rounds pct_covered to 1 decimal",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B", "Genus_C")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B")
      )

    res <-
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )

    pct <-
      purrr::chuck(res, "pct_covered")

    testthat::expect_equal(
      base::round(pct, 1),
      pct
    )
  }
)

testthat::test_that(
  "check_trait_coverage() emits a message to the console",
  {
    vec_taxa <-
      base::c("Genus_A", "Genus_B")

    data_trait <-
      tibble::tibble(
        taxon_name = base::c("Genus_A")
      )

    testthat::expect_message(
      check_trait_coverage(
        vec_community_taxa = vec_taxa,
        data_trait_table = data_trait
      )
    )
  }
)

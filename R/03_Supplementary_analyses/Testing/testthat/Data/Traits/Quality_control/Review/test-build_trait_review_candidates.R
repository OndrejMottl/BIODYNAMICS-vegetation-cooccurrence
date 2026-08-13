testthat::test_that(
  "review candidates combine automated and source keys",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c(base::rep("A", 10L), "B"),
        trait_domain_name = base::rep("Height", 11L),
        trait_name = base::rep("whole plant height", 11L),
        dataset_id = base::rep(1L, 11L),
        trait_value = base::c(base::rep(1, 9L), 100, 2)
      )

    data_source_candidates <-
      tibble::tibble(
        taxon_name = "Missing taxon",
        trait_domain_name = "Height",
        source_reference = "review_submission_csv:1"
      )

    data_candidates <-
      build_trait_review_candidates(
        data_trait_records = data_trait_records,
        data_source_candidates = data_source_candidates,
        review_stage = "raw",
        minimum_taxon_records = 5L
      )

    testthat::expect_named(
      data_candidates,
      base::c(
        "candidate_id",
        "review_stage",
        "taxon_name",
        "trait_domain_name",
        "n_records",
        "n_trait_names",
        "n_datasets",
        "n_domain_outliers",
        "n_taxon_outliers",
        "source_references",
        "candidate_reasons"
      )
    )
    testthat::expect_true(
      "Missing taxon" %in% dplyr::pull(data_candidates, taxon_name)
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          dplyr::pull(data_candidates, candidate_id),
          "^[0-9a-f]{64}$"
        )
      )
    )
  }
)

testthat::test_that(
  "review candidate identifiers are stable",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::rep("A", 5L),
        trait_domain_name = base::rep("Height", 5L),
        trait_value = base::c(1, 1, 1, 1, 100)
      )

    data_first <-
      build_trait_review_candidates(
        data_trait_records = data_trait_records,
        review_stage = "raw",
        minimum_taxon_records = 3L
      )

    data_second <-
      build_trait_review_candidates(
        data_trait_records = data_trait_records,
        review_stage = "raw",
        minimum_taxon_records = 3L
      )

    testthat::expect_identical(
      dplyr::pull(data_first, candidate_id),
      dplyr::pull(data_second, candidate_id)
    )
  }
)

testthat::test_that(
  "domain-only outliers stay outside the mandatory review queue",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c(base::rep("Common", 10L), "Extreme"),
        trait_domain_name = base::rep("Height", 11L),
        trait_value = base::c(base::rep(1, 10L), 100)
      )

    data_candidates <-
      build_trait_review_candidates(
        data_trait_records = data_trait_records,
        review_stage = "raw",
        minimum_taxon_records = 5L
      )

    testthat::expect_false(
      "Extreme" %in% dplyr::pull(data_candidates, taxon_name)
    )
  }
)

testthat::test_that(
  "domain flags remain diagnostic for source review candidates",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c(base::rep("Common", 10L), "Extreme"),
        trait_domain_name = base::rep("Height", 11L),
        trait_value = base::c(base::rep(1, 10L), 100)
      )
    data_source_candidates <-
      tibble::tibble(
        taxon_name = "Extreme",
        trait_domain_name = "Height",
        source_reference = "review_submission_csv:1"
      )

    data_candidates <-
      build_trait_review_candidates(
        data_trait_records = data_trait_records,
        data_source_candidates = data_source_candidates,
        review_stage = "raw",
        minimum_taxon_records = 5L
      )

    data_extreme <-
      data_candidates |>
      dplyr::filter(.data[["taxon_name"]] == "Extreme")

    testthat::expect_equal(
      dplyr::pull(data_extreme, n_domain_outliers),
      1L
    )
    testthat::expect_equal(
      dplyr::pull(data_extreme, candidate_reasons),
      "domain_outlier;source_review"
    )
  }
)

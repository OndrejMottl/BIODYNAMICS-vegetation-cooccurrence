testthat::test_that(
  "load_trait_domain_units() returns the canonical typed columns",
  {
    path_units <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      base::c(
        stringr::str_c(
          "vegvault_version,vegvault_build_reference,trait_domain_name,",
          "trait_unit,evidence_status,included_in_primary,rationale,",
          "evidence_reference,review_status,reviewer,reviewed_at"
        ),
        stringr::str_c(
          "2.0.0,hash_accepted,Plant heigh,m,source_standardised,TRUE,",
          "Standardised at the source.,TraitsDomain,approved,Reviewer,",
          "2026-11-27"
        ),
        stringr::str_c(
          "2.0.0,hash_accepted,Leaf mass per area,mg/mm2,source_derived,",
          "TRUE,Derived from SLA.,TraitDerivation,proposed,,"
        )
      ),
      path_units
    )

    res <-
      load_trait_domain_units(
        path_trait_domain_units = path_units
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_named(
      res,
      base::c(
        "vegvault_version",
        "vegvault_build_reference",
        "trait_domain_name",
        "trait_unit",
        "evidence_status",
        "included_in_primary",
        "rationale",
        "evidence_reference",
        "review_status",
        "reviewer",
        "reviewed_at"
      )
    )
    testthat::expect_type(
      dplyr::pull(res, included_in_primary),
      "logical"
    )
    testthat::expect_type(dplyr::pull(res, reviewed_at), "character")
    testthat::expect_equal(
      dplyr::pull(res, trait_unit),
      base::c("m", "mg/mm2")
    )
    testthat::expect_equal(
      dplyr::pull(res, reviewer),
      base::c("Reviewer", NA_character_)
    )
  }
)

testthat::test_that(
  "load_trait_domain_units() reads a header-only file as zero rows",
  {
    path_units <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      stringr::str_c(
        "vegvault_version,vegvault_build_reference,trait_domain_name,",
        "trait_unit,evidence_status,included_in_primary,rationale,",
        "evidence_reference,review_status,reviewer,reviewed_at"
      ),
      path_units
    )

    res <-
      load_trait_domain_units(
        path_trait_domain_units = path_units
      )

    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_type(
      dplyr::pull(res, included_in_primary),
      "logical"
    )
  }
)

testthat::test_that(
  "load_trait_domain_units() keeps edge whitespace for the validator",
  {
    path_units <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      base::c(
        stringr::str_c(
          "vegvault_version,vegvault_build_reference,trait_domain_name,",
          "trait_unit,evidence_status,included_in_primary,rationale,",
          "evidence_reference,review_status,reviewer,reviewed_at"
        ),
        stringr::str_c(
          "2.0.0,hash_accepted,Plant heigh,m ,source_standardised,TRUE,",
          "Standardised.,TraitsDomain,approved,Reviewer,2026-11-27"
        )
      ),
      path_units
    )

    res <-
      load_trait_domain_units(
        path_trait_domain_units = path_units
      )

    testthat::expect_equal(dplyr::pull(res, trait_unit), "m ")
  }
)

testthat::test_that(
  "load_trait_domain_units() stops on a non-canonical header",
  {
    path_units <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      stringr::str_c(
        "vegvault_build_reference,vegvault_version,trait_domain_name,",
        "trait_unit,evidence_status,included_in_primary,rationale,",
        "evidence_reference,review_status,reviewer,reviewed_at"
      ),
      path_units
    )

    testthat::expect_error(
      load_trait_domain_units(
        path_trait_domain_units = path_units
      ),
      regexp = "canonical columns"
    )
  }
)

testthat::test_that(
  "load_trait_domain_units() stops on cells it cannot parse",
  {
    path_units <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      base::c(
        stringr::str_c(
          "vegvault_version,vegvault_build_reference,trait_domain_name,",
          "trait_unit,evidence_status,included_in_primary,rationale,",
          "evidence_reference,review_status,reviewer,reviewed_at"
        ),
        stringr::str_c(
          "2.0.0,hash_accepted,Plant heigh,m,source_standardised,maybe,",
          "Standardised.,TraitsDomain,approved,Reviewer,2026-11-27"
        )
      ),
      path_units
    )

    testthat::expect_error(
      load_trait_domain_units(
        path_trait_domain_units = path_units
      ),
      regexp = "parsing problems"
    )
  }
)

testthat::test_that(
  "load_trait_domain_units() requires one existing file",
  {
    path_missing <-
      base::file.path(withr::local_tempdir(), "missing.csv")

    purrr::walk(
      .x = base::list(
        path_missing,
        base::c(path_missing, path_missing),
        1L,
        NA_character_
      ),
      .f = ~ testthat::expect_error(
        load_trait_domain_units(
          path_trait_domain_units = .x
        ),
        regexp = "'path_trait_domain_units' must"
      )
    )
  }
)

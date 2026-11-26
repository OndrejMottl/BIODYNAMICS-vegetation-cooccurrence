# -- Helpers ---------------------------------------------------------------

write_unit_vault <- function(
    path_vault,
    data_domains,
    manifest_sha256 = "hash_accepted") {
  connection_vault <-
    DBI::dbConnect(RSQLite::SQLite(), path_vault)
  DBI::dbWriteTable(
    connection_vault,
    "version_control",
    tibble::tibble(
      id = 5L,
      version = "2.0.0",
      git_commit = "f19d588",
      manifest_sha256 = manifest_sha256
    )
  )
  DBI::dbWriteTable(
    connection_vault,
    "TraitsDomain",
    data_domains
  )
  DBI::dbDisconnect(connection_vault)
  return(path_vault)
}

make_unit_domains <- function() {
  tibble::tibble(
    trait_domain_id = base::c(3L, 5L),
    trait_domain_name = base::c("Leaf mass per area", "Plant heigh"),
    trait_unit = base::c("mg/mm2", "m")
  )
}

make_unit_release <- function() {
  tibble::tibble(
    vegvault_version = "2.0.0",
    git_commit = "f19d588",
    manifest_sha256 = "hash_accepted"
  )
}

make_unit_table <- function() {
  tibble::tibble(
    vegvault_version = "2.0.0",
    vegvault_build_reference = "hash_accepted",
    trait_domain_name = base::c("Leaf mass per area", "Plant heigh"),
    trait_unit = base::c("mg/mm2", "m"),
    evidence_status = base::c("source_derived", "source_standardised"),
    included_in_primary = TRUE,
    rationale = "Checked against the release.",
    evidence_reference = "TraitsDomain",
    review_status = "approved",
    reviewer = "Reviewer",
    reviewed_at = "2026-11-27"
  )
}

make_unit_records <- function() {
  tibble::tibble(
    trait_domain_name = base::c(
      "Leaf mass per area",
      "Plant heigh",
      "Plant heigh"
    ),
    trait_unit = base::c("mg/mm2", "m", "m"),
    conversion_rule_key = base::c("bien_sla", "bien_height", NA),
    derivation_rule_key = base::c("sla_to_lma", NA, "height_rule"),
    trait_value = base::c(0.1, 2, 3)
  )
}

# -- Valid input -----------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() returns an approved matching table",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )
    data_units <-
      make_unit_table()

    res <-
      validate_trait_domain_units(
        data_trait_domain_units = data_units,
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      )

    testthat::expect_identical(res, data_units)
  }
)

# -- Review state ----------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() requires every row to be approved",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(
            review_status = base::c("approved", "proposed")
          ),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "must be approved"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(reviewer = base::c("Reviewer", NA)),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "reviewer and a review date"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(reviewed_at = "27 Nov 2026"),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "reviewer and a review date"
    )
  }
)

testthat::test_that(
  "validate_trait_domain_units() rejects incomplete or padded text",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(rationale = base::c("Checked.", "")),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "cannot be blank"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(trait_unit = base::c("mg/mm2", "m ")),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "edge whitespace"
    )
  }
)

testthat::test_that(
  "validate_trait_domain_units() checks status and primary inclusion",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(
            evidence_status = base::c(
              "source_derived",
              "provisional_units"
            )
          ),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "evidence status"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(included_in_primary = base::c(TRUE, NA)),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "included_in_primary"
    )
  }
)

# -- Release ---------------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() binds the table to release and build",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(vegvault_version = "1.0.0"),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "VegVault release"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::mutate(vegvault_build_reference = "hash_rebuilt"),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "build"
    )
  }
)

testthat::test_that(
  "validate_trait_domain_units() stops when the file holds another build",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains(),
        manifest_sha256 = "hash_rebuilt"
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "validate_trait_domain_units() requires the release record",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault
      ),
      regexp = "data_vegvault_release"
    )
  }
)

# -- TraitsDomain ----------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() matches the domains of TraitsDomain",
  {
    path_vault_extra <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains() |>
          dplyr::bind_rows(
            tibble::tibble(
              trait_domain_id = 1L,
              trait_domain_name = "Diaspore mass",
              trait_unit = "mg"
            )
          )
      )
    path_vault_unit <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains() |>
          dplyr::mutate(trait_unit = base::c("g/m2", "m"))
      )
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault_extra,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "domains of TraitsDomain"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault_unit,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "units of TraitsDomain"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = dplyr::bind_rows(
          make_unit_table(),
          make_unit_table()[2L, ]
        ),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "appear once"
    )
  }
)

# -- Records ---------------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() requires each record to have its unit",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    purrr::walk(
      .x = base::list(
        base::c("mg/mm2", "cm", "m"),
        base::c("mg/mm2", NA, "m")
      ),
      .f = ~ testthat::expect_error(
        validate_trait_domain_units(
          data_trait_domain_units = make_unit_table(),
          data_trait_records = make_unit_records() |>
            dplyr::mutate(trait_unit = .x),
          path_vegvault = path_vault,
          data_vegvault_release = make_unit_release()
        ),
        regexp = "unit of its domain"
      )
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records() |>
          dplyr::mutate(
            trait_domain_name = base::c(
              "Leaf mass per area",
              "Plant heigh",
              "Leaf Area"
            )
          ),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "unit of its domain"
    )
  }
)

testthat::test_that(
  "validate_trait_domain_units() requires a unit rule on every record",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records() |>
          dplyr::mutate(
            conversion_rule_key = base::c("bien_sla", NA, NA),
            derivation_rule_key = base::c(NA, NA, "height_rule")
          ),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "conversion or derivation rule"
    )
  }
)

# -- Arguments -------------------------------------------------------------

testthat::test_that(
  "validate_trait_domain_units() rejects inputs without required columns",
  {
    path_vault <-
      write_unit_vault(
        path_vault = withr::local_tempfile(fileext = ".sqlite"),
        data_domains = make_unit_domains()
      )

    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table() |>
          dplyr::select(-"vegvault_build_reference"),
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "missing required columns"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = make_unit_table(),
        data_trait_records = make_unit_records() |>
          dplyr::select(-"derivation_rule_key"),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "missing required columns"
    )
    testthat::expect_error(
      validate_trait_domain_units(
        data_trait_domain_units = "units",
        data_trait_records = make_unit_records(),
        path_vegvault = path_vault,
        data_vegvault_release = make_unit_release()
      ),
      regexp = "must be data frames"
    )
  }
)

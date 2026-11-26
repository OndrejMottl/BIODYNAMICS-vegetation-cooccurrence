# -- Helpers ---------------------------------------------------------------

make_release_domains <- function() {
  tibble::tibble(
    trait_domain_name = base::c(
      "Diaspore mass",
      "Leaf Area",
      "Leaf mass per area",
      "Leaf nitrogen content per unit mass",
      "Plant heigh",
      "Stem specific density"
    ),
    trait_unit = base::c("mg", "mm2", "mg/mm2", "mg/g", "m", "g/cm3")
  )
}

make_release_units <- function(vegvault_version = "2.0.0") {
  make_release_domains() |>
    dplyr::mutate(
      vegvault_version = vegvault_version,
      vegvault_build_reference = "hash_accepted",
      .before = 1L
    ) |>
    dplyr::mutate(
      evidence_status = dplyr::if_else(
        .data[["trait_domain_name"]] == "Leaf mass per area",
        "source_derived",
        "source_standardised"
      ),
      included_in_primary = TRUE,
      rationale = "Checked against the release.",
      evidence_reference = "trait_domain_unit_evidence.csv",
      review_status = "approved",
      reviewer = "Reviewer",
      reviewed_at = "2026-11-27"
    )
}

make_release_records <- function() {
  make_release_domains() |>
    dplyr::mutate(
      trait_value = base::seq_along(.data[["trait_domain_name"]])
    )
}

# -- Release contract ------------------------------------------------------

testthat::test_that(
  "trait analysis release freezes six domains with reviewed units",
  {
    data_records <-
      make_release_records()
    data_units <-
      make_release_units()

    list_release <-
      build_trait_analysis_release(
        data_trait_records = data_records,
        data_trait_domain_units = data_units,
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      )

    testthat::expect_named(
      list_release,
      base::c("data_trait_records", "data_trait_domain_status")
    )
    testthat::expect_identical(
      purrr::chuck(list_release, "data_trait_records"),
      data_records
    )
    data_status <-
      purrr::chuck(list_release, "data_trait_domain_status")
    testthat::expect_equal(base::nrow(data_status), 6L)
    testthat::expect_named(
      data_status,
      base::c(
        "release_id",
        "release_date",
        base::names(data_units)
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_status, release_id) |> base::unique(),
      "vegvault_2_0_0_reviewed_2026_12_01"
    )
    testthat::expect_equal(
      data_status |>
        dplyr::filter(.data[["evidence_status"]] == "source_derived") |>
        dplyr::pull("trait_domain_name"),
      "Leaf mass per area"
    )
    testthat::expect_equal(
      dplyr::pull(data_status, trait_unit),
      dplyr::pull(data_units, trait_unit)
    )
  }
)

testthat::test_that(
  "trait analysis release is not locked to one VegVault release",
  {
    list_release <-
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units(
          vegvault_version = "2.1.0"
        ),
        vegvault_version = "2.1.0",
        release_id = "vegvault_2_1_0_reviewed_2027_03_01",
        release_date = "2027-03-01"
      )

    testthat::expect_equal(
      purrr::chuck(list_release, "data_trait_domain_status") |>
        dplyr::pull("vegvault_version") |>
        base::unique(),
      "2.1.0"
    )
  }
)

testthat::test_that(
  "trait analysis release binds units and id to the release",
  {
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units(
          vegvault_version = "1.0.0"
        ),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "unit table"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units(),
        vegvault_version = "2.0.0",
        release_id = "vegvault_1_0_0_interim_2026_08_31",
        release_date = "2026-12-01"
      ),
      regexp = "release_id"
    )
  }
)

testthat::test_that(
  "trait analysis release requires exactly the six supported domains",
  {
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records() |>
          dplyr::filter(.data[["trait_domain_name"]] != "Leaf Area"),
        data_trait_domain_units = make_release_units(),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "exactly six"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units() |>
          dplyr::filter(.data[["trait_domain_name"]] != "Leaf Area"),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "exactly six"
    )
  }
)

testthat::test_that(
  "trait analysis release requires the unit of each record's domain",
  {
    purrr::walk(
      .x = base::list(
        base::c("mg", "cm2", "mg/mm2", "mg/g", "m", "g/cm3"),
        base::c("mg", "mm2", NA, "mg/g", "m", "g/cm3")
      ),
      .f = ~ testthat::expect_error(
        build_trait_analysis_release(
          data_trait_records = make_release_records() |>
            dplyr::mutate(trait_unit = .x),
          data_trait_domain_units = make_release_units(),
          vegvault_version = "2.0.0",
          release_id = "vegvault_2_0_0_reviewed_2026_12_01",
          release_date = "2026-12-01"
        ),
        regexp = "unit of its domain"
      )
    )
  }
)

# -- Arguments -------------------------------------------------------------

testthat::test_that(
  "trait analysis release validates its arguments",
  {
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units(),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "01/12/2026"
      ),
      regexp = "YYYY-MM-DD"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records() |>
          dplyr::select(-"trait_unit"),
        data_trait_domain_units = make_release_units(),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "Trait records must contain"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units() |>
          dplyr::select(-"evidence_status"),
        vegvault_version = "2.0.0",
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "unit table must contain"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = make_release_records(),
        data_trait_domain_units = make_release_units(),
        vegvault_version = NA_character_,
        release_id = "vegvault_2_0_0_reviewed_2026_12_01",
        release_date = "2026-12-01"
      ),
      regexp = "non-empty character scalars"
    )
  }
)

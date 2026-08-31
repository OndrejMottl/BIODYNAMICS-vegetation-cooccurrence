testthat::test_that(
  "trait analysis release freezes six domains with explicit status",
  {
    vec_domains <-
      base::c(
        "Diaspore mass",
        "Leaf Area",
        "Leaf mass per area",
        "Leaf nitrogen content per unit mass",
        "Plant heigh",
        "Stem specific density"
      )
    data_records <-
      tibble::tibble(
        trait_domain_name = vec_domains,
        trait_value = base::seq_along(vec_domains)
      )

    list_release <-
      build_trait_analysis_release(
        data_trait_records = data_records,
        vegvault_version = "1.0.0",
        release_id = "vegvault_1_0_0_interim_2026_08_31",
        release_date = "2026-08-31"
      )

    testthat::expect_identical(
      purrr::chuck(list_release, "data_trait_records"),
      data_records
    )
    data_status <-
      purrr::chuck(list_release, "data_trait_domain_status")
    testthat::expect_equal(base::nrow(data_status), 6L)
    testthat::expect_setequal(
      data_status |>
        dplyr::filter(.data[["evidence_status"]] == "provisional_units") |>
        dplyr::pull("trait_domain_name"),
      base::c(
        "Leaf mass per area",
        "Leaf nitrogen content per unit mass"
      )
    )
  }
)

testthat::test_that(
  "trait analysis release rejects version drift and missing domains",
  {
    data_records <-
      tibble::tibble(
        trait_domain_name = "Diaspore mass",
        trait_value = 1
      )

    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = data_records,
        vegvault_version = "2.0.0",
        release_id = "vegvault_1_0_0_interim_2026_08_31",
        release_date = "2026-08-31"
      ),
      regexp = "VegVault 1.0.0"
    )
    testthat::expect_error(
      build_trait_analysis_release(
        data_trait_records = data_records,
        vegvault_version = "1.0.0",
        release_id = "vegvault_1_0_0_interim_2026_08_31",
        release_date = "2026-08-31"
      ),
      regexp = "exactly six"
    )
  }
)

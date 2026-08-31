testthat::test_that(
  "source anomaly diagnosis finds corroborated power-of-ten errors",
  {
    data_records <-
      tibble::tibble(
        taxon_name = base::c("Picea", "Picea", "Picea", "Abies"),
        data_source_id = base::c(660L, 660L, 133L, 133L),
        trait_domain_name = "Stem specific density",
        trait_value = base::c(0.0003, 0.0004, 0.35, 0.45)
      )

    list_diagnosis <-
      diagnose_trait_source_anomalies(data_records)
    data_anomalies <- list_diagnosis[["data_source_anomalies"]]
    data_picea_source <-
      data_anomalies |>
      dplyr::filter(.data[["data_source_id"]] == 660L)

    testthat::expect_equal(base::nrow(data_picea_source), 1L)
    testthat::expect_equal(
      data_picea_source[["suggested_scale_factor"]],
      1000
    )
    testthat::expect_true(
      data_picea_source[["flag_cross_source_corroborated"]]
    )
    testthat::expect_match(
      data_picea_source[["diagnostic_reason"]],
      "cross_source_power_of_ten"
    )
  }
)

testthat::test_that(
  "source anomaly diagnosis rejects nonpositive values",
  {
    data_records <-
      tibble::tibble(
        taxon_name = "A",
        data_source_id = 1L,
        trait_domain_name = "Leaf Area",
        trait_value = 0
      )

    testthat::expect_error(
      diagnose_trait_source_anomalies(data_records),
      regexp = "positive finite"
    )
  }
)

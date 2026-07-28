testthat::test_that(
  "build_community_record_signatures() validates source data",
  {
    testthat::expect_error(
      build_community_record_signatures(data_community = NULL),
      regexp = "data_source"
    )
  }
)


testthat::test_that(
  "build_community_record_signatures() sorts taxa within records",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b"),
      sample_name = c("s1", "s1", "s1"),
      age = c(0, 0, 0),
      taxon = c("Betula", "Abies", "Pinus"),
      pollen_count = c(2, 1, 3)
    )

    res_community_record_signatures <- build_community_record_signatures(
      data_community = data_community
    )

    testthat::expect_equal(
      base::nrow(res_community_record_signatures),
      2L
    )
    testthat::expect_equal(
      dplyr::pull(
        res_community_record_signatures,
        community_signature
      )[[1]],
      "Abies=1|Betula=2"
    )
  }
)

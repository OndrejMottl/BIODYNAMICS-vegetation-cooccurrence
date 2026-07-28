testthat::test_that(
  "make_community_record_signatures() validates source data",
  {
    testthat::expect_error(
      make_community_record_signatures(data_source = NULL),
      regexp = "data_source"
    )
  }
)


testthat::test_that(
  "make_community_record_signatures() sorts taxa within records",
  {
    data_source <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b"),
      sample_name = c("s1", "s1", "s1"),
      age = c(0, 0, 0),
      taxon = c("Betula", "Abies", "Pinus"),
      pollen_count = c(2, 1, 3)
    )

    res <- make_community_record_signatures(
      data_source = data_source
    )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, community_signature)[[1]],
      "Abies=1|Betula=2"
    )
  }
)

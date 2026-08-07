testthat::test_that(
  "collapse_spatial_variance_observation_id() combines identifier values",
  {
    testthat::expect_identical(
      collapse_spatial_variance_observation_id(
        "paleo",
        "local",
        "eu_r01",
        "genus"
      ),
      "paleo__local__eu_r01__genus"
    )
  }
)

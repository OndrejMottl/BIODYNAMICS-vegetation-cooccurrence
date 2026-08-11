testthat::test_that(
  "build_sjsdm_tuning_round_plan() preserves three staged rounds",
  {
    res <- build_sjsdm_tuning_round_plan("staged", 3L)
    testthat::expect_identical(res[["round_id"]], 1:3)
    testthat::expect_identical(
      res[["tier_target_name"]],
      base::c(
        "data_sjsdm_tier_survivor_decisions_round_1",
        "data_sjsdm_tier_survivor_decisions_round_2",
        "data_sjsdm_tier_regularization_artifacts"
      )
    )
  }
)

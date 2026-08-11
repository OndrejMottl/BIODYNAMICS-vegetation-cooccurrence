testthat::test_that(
  "build_sjsdm_staged_benchmark_policy() returns frozen gates",
  {
    list_policy <-
      build_sjsdm_staged_benchmark_policy()

    testthat::expect_named(
      list_policy,
      base::c(
        "policy_version",
        "minimum_median_wall_reduction",
        "minimum_each_wall_reduction",
        "minimum_fit_reduction",
        "maximum_store_growth",
        "maximum_memory_growth",
        "maximum_log_loss_regression",
        "maximum_auc_regression",
        "maximum_tjur_r2_regression",
        "maximum_coverage_regression"
      )
    )
    testthat::expect_identical(
      purrr::chuck(list_policy, "policy_version"),
      "issue138_staged_benchmark_v2"
    )
    testthat::expect_equal(
      purrr::chuck(
        list_policy,
        "minimum_median_wall_reduction"
      ),
      0.15
    )
    testthat::expect_equal(
      purrr::chuck(
        list_policy,
        "minimum_each_wall_reduction"
      ),
      0.10
    )
  }
)

testthat::test_that(
  "validate_config_allowed_values() accepts supported unique values",
  {
    testthat::expect_invisible(
      validate_config_allowed_values(
        vec_values = base::c("main", "smoke"),
        argument_name = "vec_allowed_roles",
        vec_supported_values = base::c("main", "smoke", "reference")
      )
    )
  }
)

testthat::test_that(
  "validate_config_allowed_values() rejects invalid selections",
  {
    testthat::expect_error(
      validate_config_allowed_values(
        vec_values = base::c("main", "main"),
        argument_name = "vec_allowed_roles",
        vec_supported_values = base::c("main", "smoke")
      ),
      "unique values"
    )

    testthat::expect_error(
      validate_config_allowed_values(
        vec_values = "archived",
        argument_name = "vec_allowed_statuses",
        vec_supported_values = "active"
      ),
      "vec_allowed_statuses"
    )
  }
)

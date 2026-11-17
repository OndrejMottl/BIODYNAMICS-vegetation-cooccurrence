testthat::test_that(
  "build_configuration_reference_diff() returns no rows for equal profiles",
  {
    list_profiles <-
      base::list(
        p1 = base::list(a = 1, b = base::list(c = "x"))
      )

    res <-
      build_configuration_reference_diff(
        list_profiles_current = list_profiles,
        list_profiles_reference = list_profiles
      )

    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_equal(base::names(res), base::c("profile_id", "key_path"))
  }
)

testthat::test_that(
  "build_configuration_reference_diff() reports changed and added leaves",
  {
    res <-
      build_configuration_reference_diff(
        list_profiles_current = base::list(
          p1 = base::list(
            a = 1,
            b = base::list(c = "y", d = TRUE),
            e = base::c(0, 17500)
          ),
          p2 = base::list(a = 2)
        ),
        list_profiles_reference = base::list(
          p1 = base::list(a = 1, b = base::list(c = "x")),
          p2 = base::list(a = 2)
        )
      )

    testthat::expect_setequal(
      stringr::str_c(res[["profile_id"]], ":", res[["key_path"]]),
      base::c("p1:b.c", "p1:b.d", "p1:e")
    )
  }
)

testthat::test_that(
  "build_configuration_reference_diff() reports reordered keys separately",
  {
    res <-
      build_configuration_reference_diff(
        list_profiles_current = base::list(
          p1 = base::list(m = base::list(b = 2, a = 1))
        ),
        list_profiles_reference = base::list(
          p1 = base::list(m = base::list(a = 1, b = 2))
        )
      )

    testthat::expect_equal(res[["key_path"]], "m[order]")
  }
)

testthat::test_that(
  "build_configuration_reference_diff() validates its inputs",
  {
    testthat::expect_error(
      build_configuration_reference_diff(
        list_profiles_current = base::list(p1 = base::list()),
        list_profiles_reference = base::list(p2 = base::list())
      ),
      "same profile identifiers"
    )
  }
)

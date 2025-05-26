testthat::test_that(
  desc = "return correct class",
  code = {
    mod_example <-
      list(
        mod = Hmsc::TD$m
      )

    example_assoc <-
      get_species_association(
        data_source = mod_example
      )

    result <-
      get_significant_associations(
        data_source = example_assoc,
        alpha = 0.05
      )

    testthat::expect_type(
      result,
      "list"
    )
  }
)

testthat::test_that(
  desc = "return correct data structure",
  code = {
    mod_example <-
      list(
        mod = Hmsc::TD$m
      )

    example_assoc <-
      get_species_association(
        data_source = mod_example
      )

    result <-
      get_significant_associations(
        data_source = example_assoc,
        alpha = 0.05
      )

    testthat::expect_length(
      result,
      length(Hmsc::TD$m$ranLevelsUsed)
    )

    testthat::expect_true(
      purrr::map(result, ~ names(.x) == c(
        "n_associations", "n_significant", "proportion_significant"
      )) %>%
        purrr::map_lgl(~ all(.x)) %>%
        all()
    )

    testthat::expect_true(
      purrr::map(result, ~ is.numeric(.x$n_associations)) %>%
        unlist() %>%
        all()
    )

    testthat::expect_true(
      purrr::map(result, ~ is.numeric(.x$n_significant)) %>%
        unlist() %>%
        all()
    )

    testthat::expect_true(
      purrr::map(result, ~ is.numeric(.x$proportion_significant)) %>%
        unlist() %>%
        all()
    )
  }
)

testthat::test_that(
  desc = "return correct values",
  code = {
    mod_example <-
      list(
        mod = Hmsc::TD$m
      )

    example_assoc <-
      get_species_association(
        data_source = mod_example
      )

    result <-
      get_significant_associations(
        data_source = example_assoc,
        alpha = 0.45
      )

    testthat::expect_true(
      result %>%
        purrr::map("n_associations") %>%
        purrr::map_lgl(~ . == 6) %>%
        all()
    )

    testthat::expect_true(
      result %>%
        purrr::map_dbl("n_significant") %>%
        {
          . == c(1, 3)
        } %>%
        all()
    )
  }
)

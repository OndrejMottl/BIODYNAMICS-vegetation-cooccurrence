testthat::test_that(
  desc = "return correct class",
  code = {
    mod_example <-
      list(
        mod = Hmsc::TD$m
      )

    result <-
      get_species_association(
        data_source = mod_example
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

    result <-
      get_species_association(
        data_source = mod_example
      )

    vec_random_levels <-
      mod_example$mod %>%
      purrr::chuck("ranLevelsUsed")

    testthat::expect_length(
      result,
      length(vec_random_levels)
    )

    testthat::expect_named(
      result,
      vec_random_levels
    )

    testthat::expect_true(
      result %>%
        purrr::map_lgl(~ all(names(.x) == c("mean", "support"))) %>%
        all()
    )

    result %>%
      purrr::map("mean") %>%
      purrr::map_lgl(~ is.matrix(.x)) %>%
      all()


    testthat::expect_true(
      result %>%
        purrr::map("mean") %>%
        purrr::map_lgl(~ all(dim(.x) == c(4, 4))) %>%
        all()
    )

    testthat::expect_true(
      result %>%
        purrr::map("support") %>%
        purrr::map_lgl(~ is.matrix(.x)) %>%
        all()
    )

    testthat::expect_true(
      result %>%
        purrr::map("support") %>%
        purrr::map_lgl(~ all(dim(.x) == c(4, 4))) %>%
        all()
    )
  }
)

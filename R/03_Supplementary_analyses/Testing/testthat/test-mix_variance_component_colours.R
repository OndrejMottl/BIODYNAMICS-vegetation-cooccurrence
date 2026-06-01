testthat::test_that(
  "mix_variance_component_colours() returns deterministic HEX output",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c(
          "obs_1",
          "obs_1",
          "obs_1",
          "obs_2",
          "obs_2",
          "obs_2"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        component_share = base::c(40, 20, 40, 20, 40, 40)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_first <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours
      )

    res_second <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours
      )

    testthat::expect_equal(res_first, res_second)
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          string = dplyr::pull(res_first, tile_fill_colour),
          pattern = "^#[A-Fa-f0-9]{6}$"
        )
      )
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() errors on missing components",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1"),
        component = base::c("Abiotic", "Associations"),
        component_share = base::c(60, 40)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours
      ),
      regexp = "Required components"
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() errors on invalid shares",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1", "obs_1"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        component_share = base::c(60, -10, 50)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours
      ),
      regexp = "finite and non-negative"
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() errors on malformed compositions",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1", "obs_1"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        component_share = base::c(60, 20, 10)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours
      ),
      regexp = "Malformed compositions"
    )
  }
)

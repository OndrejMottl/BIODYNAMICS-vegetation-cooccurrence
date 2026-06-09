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

    res_first_hcl <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "HCL"
      )

    res_second_hcl <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "HCL"
      )

    res_first_perceptual <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "perc_avg"
      )

    res_second_perceptual <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "perc_avg"
      )

    testthat::expect_equal(res_first_hcl, res_second_hcl)
    testthat::expect_equal(res_first_perceptual, res_second_perceptual)
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          string = dplyr::pull(res_first_hcl, tile_fill_colour),
          pattern = "^#[A-Fa-f0-9]{6}$"
        )
      )
    )
    testthat::expect_true(
      base::all(
        stringr::str_detect(
          string = dplyr::pull(res_first_perceptual, tile_fill_colour),
          pattern = "^#[A-Fa-f0-9]{6}$"
        )
      )
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() supports perceptual averaging",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1", "obs_1"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        component_share = base::c(40, 20, 40)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_hcl <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "HCL"
      )

    res_perceptual <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "perc_avg"
      )

    testthat::expect_false(
      base::identical(
        dplyr::pull(res_hcl, tile_fill_colour),
        dplyr::pull(res_perceptual, tile_fill_colour)
      )
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() preserves pure component colours",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1", "obs_1"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        component_share = base::c(100, 0, 0)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_perceptual <-
      mix_variance_component_colours(
        data_component_shares = data_component_shares,
        vec_component_colours = vec_component_colours,
        method = "perc_avg"
      )

    testthat::expect_equal(
      dplyr::pull(res_perceptual, tile_fill_colour),
      "#D95F02"
    )
  }
)

testthat::test_that(
  "mix_variance_component_colours() validates method",
  {
    data_component_shares <-
      tibble::tibble(
        observation_id = base::c("obs_1", "obs_1", "obs_1"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        component_share = base::c(40, 20, 40)
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
        vec_component_colours = vec_component_colours,
        method = "RGB"
      ),
      regexp = "`method` must be one of"
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

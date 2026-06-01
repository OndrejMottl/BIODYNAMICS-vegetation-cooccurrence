testthat::test_that(
  "modern community preparation remains non-interpolated",
  {
    vec_modern_pipe_lines <-
      base::readLines(
        con = here::here(
          "R/Pipelines/_pipes/pipe_segment_community_prepare_modern.R"
        ),
        warn = FALSE
      )

    testthat::expect_false(
      base::any(
        stringr::str_detect(
          string = vec_modern_pipe_lines,
          pattern = "interpolate_"
        )
      )
    )
  }
)

testthat::test_that(
  "abiotic pipe segment uses deterministic guard only",
  {
    vec_abiotic_pipe_lines <-
      base::readLines(
        con = here::here(
          "R/Pipelines/_pipes/pipe_segment_abiotic_extract.R"
        ),
        warn = FALSE
      )

    testthat::expect_true(
      base::any(
        stringr::str_detect(
          string = vec_abiotic_pipe_lines,
          pattern = "check_abiotic_interpolation_contract"
        )
      )
    )

    testthat::expect_false(
      base::any(
        stringr::str_detect(
          string = vec_abiotic_pipe_lines,
          pattern = "interpolate_community_data_with_uncertainty"
        )
      )
    )
  }
)

testthat::test_that(
  "paleo community interpolation uses dynamic dataset branches",
  {
    vec_paleo_pipe_lines <-
      base::readLines(
        con = here::here(
          "R/Pipelines/_pipes/pipe_segment_community_prepare_paleo.R"
        ),
        warn = FALSE
      )

    testthat::expect_true(
      base::any(
        stringr::str_detect(
          string = vec_paleo_pipe_lines,
          pattern = "make_community_interpolation_jobs"
        )
      )
    )

    testthat::expect_true(
      base::any(
        stringr::str_detect(
          string = vec_paleo_pipe_lines,
          pattern = "pattern = map\\(list_community_interpolation_jobs\\)"
        )
      )
    )
  }
)

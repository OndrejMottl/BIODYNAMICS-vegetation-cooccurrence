testthat::test_that("direct and shared routes use the same CV-only policy", {
  for (
    suffix_pipe in base::c("", "_from_shared")
  ) {
    text_pipe <-
      readr::read_file(here::here(stringr::str_c(
        "R/Pipelines/_pipes/pipe_segment_model_cross_validation",
        suffix_pipe, ".R"
      )))
    testthat::expect_match(
      text_pipe, "resolve_cross_validation_fold_search(", fixed = TRUE
    )
    testthat::expect_match(
      text_pipe,
      "grouped_fold_ladder = vec_cross_validation_grouped_fold_ladder",
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipe,
      'name = "data_cross_validation_partition_diagnostics_search"',
      fixed = TRUE
    )
    testthat::expect_match(
      text_pipe,
      'list_cross_validation_fold_search, "data_assignments"',
      fixed = TRUE
    )
  }
})

testthat::test_that("fold ladder is excluded from model configuration", {
  text_shared <-
    readr::read_file(here::here(
      "R/Pipelines/_pipes/pipe_segment_config_model.R"
    ))
  text_resolution <-
    readr::read_file(here::here(
      "R/Pipelines/_pipes/pipe_segment_config_model_by_resolution.R"
    ))
  testthat::expect_match(
    text_shared,
    'base::c("fit_budget", "grouped_fold_ladder")', fixed = TRUE
  )
  testthat::expect_match(
    text_resolution, "grouped_fold_ladder = rlang::zap()", fixed = TRUE
  )
  text_shared_design <-
    readr::read_file(here::here(
      "R/Pipelines/_pipes/pipe_segment_model_cross_validation_shared.R"
    ))
  testthat::expect_match(
    text_shared_design,
    "purrr::list_modify(grouped_fold_ladder = rlang::zap())", fixed = TRUE
  )
})

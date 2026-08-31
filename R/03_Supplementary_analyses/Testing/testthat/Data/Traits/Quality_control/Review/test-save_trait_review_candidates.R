testthat::test_that(
  "candidate writer creates its directory and returns the CSV path",
  {
    path_directory <- base::tempfile()
    path_candidates <-
      base::file.path(path_directory, "candidates.csv")
    data_candidates <-
      tibble::tibble(candidate_id = "candidate")

    path_result <-
      save_trait_review_candidates(
        data_trait_review_candidates = data_candidates,
        path_trait_review_candidates = path_candidates
      )

    testthat::expect_identical(path_result, path_candidates)
    testthat::expect_true(base::file.exists(path_result))
    testthat::expect_identical(
      readr::read_csv(
        path_result,
        show_col_types = FALSE
      )[["candidate_id"]],
      data_candidates[["candidate_id"]]
    )
  }
)

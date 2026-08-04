testthat::test_that(
  ".summarise_model_provenance() retains the first provenance row",
  {
    data_result <-
      .summarise_model_provenance(
        data_provenance = tibble::tibble(
          cv_strategy = base::c("first", "second"),
          effective_folds = base::c(5L, 3L)
        )
      )

    testthat::expect_equal(dplyr::pull(data_result, cv_strategy), "first")
    testthat::expect_equal(dplyr::pull(data_result, effective_folds), 5L)
    testthat::expect_named(
      data_result,
      base::c(
        "cv_strategy",
        "effective_folds",
        "cv_feasibility_status",
        "n_locations",
        "n_samples",
        "n_taxa",
        "n_effective_mev",
        "regularization_source",
        "source_tier",
        "candidate_id"
      )
    )
  }
)

testthat::test_that(
  ".summarise_model_provenance() returns typed defaults when missing",
  {
    data_result <-
      .summarise_model_provenance(data_provenance = NULL)

    testthat::expect_equal(base::nrow(data_result), 1L)
    testthat::expect_true(base::all(base::is.na(data_result)))
  }
)

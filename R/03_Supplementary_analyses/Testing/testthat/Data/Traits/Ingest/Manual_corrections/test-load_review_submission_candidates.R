testthat::test_that(
  "submitted review keys are recovered without changing the source",
  {
    path_submission <-
      base::tempfile(fileext = ".csv")
    source_lines <-
      base::c(
        " Taxon A ,Height,exclude,x,above 10,TRUE,,",
        "Taxon B,Leaf Area,scale ,0.1,,TRUE,,"
      )
    readr::write_lines(source_lines, path_submission)
    source_hash_before <-
      digest::digest(
        file = path_submission,
        algo = "sha256",
        serialize = FALSE
      )

    data_candidates <-
      load_review_submission_candidates(path_submission)

    testthat::expect_named(
      data_candidates,
      base::c(
        "taxon_name",
        "trait_domain_name",
        "source_reference"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, taxon_name),
      base::c("Taxon A", "Taxon B")
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, source_reference),
      base::c("review_submission_csv:1", "review_submission_csv:2")
    )
    testthat::expect_identical(
      digest::digest(
        file = path_submission,
        algo = "sha256",
        serialize = FALSE
      ),
      source_hash_before
    )
  }
)

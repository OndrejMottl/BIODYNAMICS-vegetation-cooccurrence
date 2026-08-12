testthat::test_that(
  "evaluate_functional_type_classification_change() ignores label permutations",
  {
    data_reference <-
      tibble::tibble(
        taxon_name = base::c("a", "b", "c", "d"),
        functional_type = base::c(1L, 1L, 2L, 2L),
        silhouette_width = base::c(0.4, 0.5, 0.6, 0.7)
      )

    data_candidate <-
      tibble::tibble(
        taxon_name = base::c("d", "c", "b", "a"),
        functional_type = base::c(9L, 9L, 4L, 4L),
        silhouette_width = base::c(0.7, 0.6, 0.5, 0.4)
      )

    list_comparison <-
      evaluate_functional_type_classification_change(
        data_reference = data_reference,
        data_candidate = data_candidate
      )

    data_summary <-
      purrr::chuck(list_comparison, "data_summary")

    testthat::expect_equal(
      dplyr::pull(data_summary, raw_assignment_difference_count),
      4L
    )
    testthat::expect_equal(
      dplyr::pull(data_summary, partition_pair_difference_count),
      0
    )
    testthat::expect_true(
      dplyr::pull(data_summary, partition_identical)
    )
    testthat::expect_equal(
      dplyr::pull(data_summary, silhouette_difference_count),
      0L
    )
  }
)


testthat::test_that(
  "evaluate_functional_type_classification_change() detects partition changes",
  {
    data_reference <-
      tibble::tibble(
        taxon_name = base::c("a", "b", "c", "d"),
        functional_type = base::c(1L, 1L, 2L, 2L),
        silhouette_width = base::c(0.4, 0.5, 0.6, 0.7)
      )

    data_candidate <-
      tibble::tibble(
        taxon_name = base::c("a", "b", "c", "d", "e"),
        functional_type = base::c(1L, 2L, 2L, 2L, 3L),
        silhouette_width = base::c(0.4, 0.1, 0.6, 0.7, 0.8)
      )

    list_comparison <-
      evaluate_functional_type_classification_change(
        data_reference = data_reference,
        data_candidate = data_candidate
      )

    data_summary <-
      purrr::chuck(list_comparison, "data_summary")
    data_taxa <-
      purrr::chuck(list_comparison, "data_taxon_comparison")

    testthat::expect_equal(
      dplyr::pull(data_summary, added_taxon_count),
      1L
    )
    testthat::expect_equal(
      dplyr::pull(data_summary, partition_pair_difference_count),
      3
    )
    testthat::expect_false(
      dplyr::pull(data_summary, partition_identical)
    )
    testthat::expect_equal(
      data_taxa |>
        dplyr::filter(.data[["taxon_name"]] == "e") |>
        dplyr::pull("taxon_status"),
      "added"
    )
  }
)


testthat::test_that(
  "evaluate_functional_type_classification_change() fails on duplicate taxa",
  {
    data_duplicate <-
      tibble::tibble(
        taxon_name = base::c("a", "a"),
        functional_type = base::c(1L, 1L),
        silhouette_width = base::c(0.4, 0.5)
      )

    testthat::expect_error(
      evaluate_functional_type_classification_change(
        data_reference = data_duplicate,
        data_candidate = data_duplicate
      ),
      regexp = "unique"
    )
  }
)

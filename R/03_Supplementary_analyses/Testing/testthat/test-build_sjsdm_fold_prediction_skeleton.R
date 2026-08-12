testthat::test_that(
  "build_sjsdm_fold_prediction_skeleton() returns exact failure rows",
  {
    data_sample_ids <-
      tibble::tibble(
        sample_id = base::c("a__0", "b__0"),
        row_index = 1:2,
        location_id = base::c("a", "b"),
        dataset_name = base::c("a", "b"),
        age = 0
      )

    data_skeleton <-
      build_sjsdm_fold_prediction_skeleton(
        list_fold_context = base::list(
          repeat_id = 2L,
          fold_id = 3L,
          test_indices = 2L
        ),
        data_sample_ids = data_sample_ids,
        taxon_names = base::c("taxon_a", "taxon_b")
      )

    testthat::expect_equal(base::nrow(data_skeleton), 2L)
    testthat::expect_named(
      data_skeleton,
      base::c(
        "repeat_id",
        "fold_id",
        "row_index",
        "location_id",
        "dataset_name",
        "age",
        "taxon",
        "observed",
        "predicted_probability",
        "null_probability",
        "prediction_status"
      )
    )
    testthat::expect_identical(
      data_skeleton[["prediction_status"]],
      base::rep("preparation_error", 2L)
    )
    testthat::expect_true(
      base::all(base::is.na(data_skeleton[["observed"]]))
    )
  }
)

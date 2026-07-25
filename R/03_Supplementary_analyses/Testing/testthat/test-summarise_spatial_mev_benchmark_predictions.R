make_spatial_mev_benchmark_predictions <- function() {
  data_grid <-
    tidyr::crossing(
      repeat_id = 1:2,
      fold_id = 1:2,
      taxon = base::c("taxon_a", "taxon_b"),
      row_in_fold = 1:4
    )

  res <-
    data_grid |>
    dplyr::mutate(
      row_index =
        (.data[["fold_id"]] - 1L) * 4L +
        .data[["row_in_fold"]],
      observed =
        base::as.numeric(
          (.data[["row_in_fold"]] + (.data[["taxon"]] == "taxon_b")) %%
            2L
        ),
      predicted_probability = dplyr::if_else(
        .data[["observed"]] == 1,
        0.8,
        0.2
      ),
      null_probability = 0.5,
      prediction_status = "ok"
    ) |>
    dplyr::select(
      "repeat_id",
      "fold_id",
      "row_index",
      "taxon",
      "observed",
      "predicted_probability",
      "null_probability",
      "prediction_status"
    )

  return(res)
}

testthat::test_that(
  "summarise_spatial_mev_benchmark_predictions() uses shared metrics",
  {
    data_predictions <-
      make_spatial_mev_benchmark_predictions()

    res <-
      summarise_spatial_mev_benchmark_predictions(
        data_predictions = data_predictions,
        spatial_mev_strategy = "fast",
        technical_cv_status = "pass",
        assignment_hash = "assignments",
        artifact_schema_hash = "schema"
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      res[["spatial_mev_strategy"]],
      base::rep("fast", 2L)
    )
    testthat::expect_equal(
      res[["evaluable_taxon_coverage"]],
      base::rep(1, 2L)
    )
    testthat::expect_true(base::all(res[["mean_auc"]] == 1))
    testthat::expect_true(base::all(res[["mean_tjur_r2"]] > 0))
  }
)

testthat::test_that(
  "evaluate_sjsdm_fold_predictions() keeps folds separate",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::rep(1L, 4L),
        fold_id = base::c(1L, 1L, 2L, 2L),
        row_index = 1:4,
        taxon = base::rep("taxon_a", 4L),
        observed = base::c(0, 1, 0, 1),
        predicted_probability = base::c(0.2, 0.8, 0.7, 0.3),
        null_probability = base::c(0.5, 0.5, 0.25, 0.25),
        prediction_status = base::rep("ok", 4L)
      )

    res <-
      evaluate_sjsdm_fold_predictions(
        data_predictions = data_predictions
      )

    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "fold_id",
        "taxon",
        "prediction_source",
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )
    )
    testthat::expect_equal(base::nrow(res), 24L)

    data_model_tjur <-
      res |>
      dplyr::filter(
        .data[["prediction_source"]] == "model",
        .data[["metric_id"]] == "tjur_r2"
      ) |>
      dplyr::arrange(.data[["fold_id"]])

    testthat::expect_equal(
      data_model_tjur[["estimate"]],
      base::c(0.6, -0.4)
    )

    data_model_auc <-
      res |>
      dplyr::filter(
        .data[["prediction_source"]] == "model",
        .data[["metric_id"]] == "auc"
      ) |>
      dplyr::arrange(.data[["fold_id"]])

    testthat::expect_equal(
      data_model_auc[["estimate"]],
      base::c(1, 0)
    )

    data_null_discrimination <-
      res |>
      dplyr::filter(
        .data[["prediction_source"]] == "prevalence_null",
        .data[["metric_id"]] %in% base::c("tjur_r2", "auc")
      ) |>
      dplyr::arrange(.data[["fold_id"]], .data[["metric_id"]])

    testthat::expect_equal(
      data_null_discrimination[["estimate"]],
      base::c(0.5, 0, 0.5, 0)
    )
    testthat::expect_true(
      base::all(data_null_discrimination[["metric_status"]] == "ok")
    )

    data_model_brier <-
      res |>
      dplyr::filter(
        .data[["prediction_source"]] == "model",
        .data[["metric_id"]] == "brier_score"
      ) |>
      dplyr::arrange(.data[["fold_id"]])

    testthat::expect_equal(
      data_model_brier[["estimate"]],
      base::c(0.04, 0.49)
    )

    data_null_slope <-
      res |>
      dplyr::filter(
        .data[["prediction_source"]] == "prevalence_null",
        .data[["metric_id"]] == "calibration_slope"
      )

    testthat::expect_true(base::all(base::is.na(data_null_slope[["estimate"]])))
    testthat::expect_true(
      base::all(
        data_null_slope[["metric_status"]] ==
          "undefined_constant_predictions"
      )
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_fold_predictions() evaluates an available null",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 1L),
        row_index = base::c(1L, 2L),
        taxon = base::c("taxon_a", "taxon_a"),
        observed = base::c(0, 1),
        predicted_probability = base::c(NA_real_, NA_real_),
        null_probability = base::c(0.25, 0.25),
        prediction_status = base::c(
          "constant_in_training",
          "constant_in_training"
        )
      )

    res <-
      evaluate_sjsdm_fold_predictions(
        data_predictions = data_predictions
      )

    data_model <-
      res |>
      dplyr::filter(.data[["prediction_source"]] == "model")

    testthat::expect_true(base::all(base::is.na(data_model[["estimate"]])))
    testthat::expect_true(
      base::all(
        data_model[["metric_status"]] == "incomplete_predictions"
      )
    )

    data_null <-
      res |>
      dplyr::filter(.data[["prediction_source"]] == "prevalence_null")

    testthat::expect_true(
      base::all(
        data_null[["metric_status"]][
          data_null[["metric_id"]] != "calibration_slope"
        ] == "ok"
      )
    )
    testthat::expect_equal(
      data_null[["metric_status"]][
        data_null[["metric_id"]] == "calibration_slope"
      ],
      "undefined_constant_predictions"
    )
    testthat::expect_equal(
      data_null[["estimate"]][data_null[["metric_id"]] == "tjur_r2"],
      0
    )
    testthat::expect_equal(
      data_null[["estimate"]][data_null[["metric_id"]] == "auc"],
      0.5
    )
    testthat::expect_true(
      base::is.finite(
        data_null[["estimate"]][data_null[["metric_id"]] == "log_loss"]
      )
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_fold_predictions() preserves an empty schema",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        row_index = base::integer(),
        taxon = base::character(),
        observed = base::numeric(),
        predicted_probability = base::numeric(),
        null_probability = base::numeric(),
        prediction_status = base::character()
      )

    res <-
      evaluate_sjsdm_fold_predictions(
        data_predictions = data_predictions
      )

    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "fold_id",
        "taxon",
        "prediction_source",
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_fold_predictions() validates OOF inputs",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 1L),
        row_index = base::c(1L, 1L),
        taxon = base::c("taxon_a", "taxon_a"),
        observed = base::c(0, 0),
        predicted_probability = base::c(0.2, 0.2),
        null_probability = base::c(0.25, 0.25),
        prediction_status = base::c("ok", "ok")
      )

    testthat::expect_error(
      evaluate_sjsdm_fold_predictions(
        data_predictions = data_predictions
      ),
      "unique"
    )

    testthat::expect_error(
      evaluate_sjsdm_fold_predictions(
        data_predictions = dplyr::select(
          data_predictions,
          -"null_probability"
        )
      ),
      "required"
    )

    testthat::expect_error(
      evaluate_sjsdm_fold_predictions(
        data_predictions = dplyr::mutate(
          data_predictions,
          row_index = base::c(1L, 2L),
          null_probability = base::c(-0.1, 0.25)
        )
      ),
      "null probabilities"
    )

    testthat::expect_error(
      evaluate_sjsdm_fold_predictions(
        data_predictions = dplyr::mutate(
          data_predictions,
          row_index = base::c(1L, 2L),
          null_probability = base::c(0.1, 0.2)
        )
      ),
      "constant"
    )

    testthat::expect_error(
      evaluate_sjsdm_fold_predictions(
        data_predictions = dplyr::mutate(
          data_predictions,
          row_index = base::c(1L, 2L)
        ),
        epsilon = 1
      ),
      "epsilon"
    )
  }
)

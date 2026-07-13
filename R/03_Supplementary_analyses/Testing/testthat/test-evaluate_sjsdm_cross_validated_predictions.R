testthat::test_that(
  "evaluate_sjsdm_cross_validated_predictions() records unavailable CV",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        row_index = base::integer(),
        taxon = base::character(),
        observed = base::numeric(),
        predicted_probability = base::numeric(),
        prediction_status = base::character()
      )

    res <-
      evaluate_sjsdm_cross_validated_predictions(data_predictions)

    testthat::expect_equal(
      base::nrow(res[["data_taxon_metrics"]]),
      0L
    )
    testthat::expect_equal(
      res[["data_community_summary"]][["metric_status"]],
      base::rep("not_available_fold_infeasible", 3L)
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_cross_validated_predictions() pools folds by repeat",
  {
    data_predictions <-
      tidyr::crossing(
        repeat_id = 1:2,
        row_index = 1:4,
        taxon = base::c(
          "taxon_incomplete",
          "taxon_one_class",
          "taxon_variable"
        )
      ) |>
      dplyr::mutate(
        fold_id = dplyr::if_else(
          .data[["row_index"]] <= 2L,
          1L,
          2L
        ),
        observed = dplyr::case_when(
          .data[["taxon"]] == "taxon_variable" &
            .data[["row_index"]] <= 2L ~ 0,
          .data[["taxon"]] == "taxon_variable" ~ 1,
          .data[["taxon"]] == "taxon_one_class" ~ 1,
          .data[["row_index"]] %in% base::c(2L, 4L) ~ 1,
          .default = 0
        ),
        predicted_probability = dplyr::case_when(
          .data[["taxon"]] == "taxon_variable" &
            .data[["repeat_id"]] == 1L &
            .data[["row_index"]] == 1L ~ 0.8,
          .data[["taxon"]] == "taxon_variable" &
            .data[["repeat_id"]] == 1L &
            .data[["row_index"]] == 2L ~ 0.6,
          .data[["taxon"]] == "taxon_variable" &
            .data[["repeat_id"]] == 1L &
            .data[["row_index"]] == 3L ~ 0.3,
          .data[["taxon"]] == "taxon_variable" &
            .data[["repeat_id"]] == 1L ~ 0.1,
          .data[["taxon"]] == "taxon_variable" &
            .data[["row_index"]] == 1L ~ 0.1,
          .data[["taxon"]] == "taxon_variable" &
            .data[["row_index"]] == 2L ~ 0.2,
          .data[["taxon"]] == "taxon_variable" &
            .data[["row_index"]] == 3L ~ 0.8,
          .data[["taxon"]] == "taxon_variable" ~ 0.9,
          .data[["taxon"]] == "taxon_one_class" ~ 0.75,
          .default = NA_real_
        ),
        prediction_status = dplyr::if_else(
          .data[["taxon"]] == "taxon_incomplete",
          "constant_in_training",
          "ok"
        )
      )

    res <-
      evaluate_sjsdm_cross_validated_predictions(
        data_predictions = data_predictions
      )

    data_taxon_metrics <-
      res[["data_taxon_metrics"]]

    data_community_summary <-
      res[["data_community_summary"]]

    testthat::expect_named(
      data_taxon_metrics,
      base::c(
        "repeat_id",
        "taxon",
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )
    )
    testthat::expect_named(
      data_community_summary,
      base::c(
        "repeat_id",
        "metric_id",
        "summary_statistic",
        "estimate",
        "n_taxa_evaluable",
        "metric_status"
      )
    )
    testthat::expect_equal(base::nrow(data_taxon_metrics), 18L)
    testthat::expect_equal(base::nrow(data_community_summary), 6L)

    data_variable_repeat_one <-
      data_taxon_metrics |>
      dplyr::filter(
        .data[["repeat_id"]] == 1L,
        .data[["taxon"]] == "taxon_variable"
      )

    testthat::expect_equal(
      data_variable_repeat_one[["estimate"]][
        data_variable_repeat_one[["metric_id"]] == "tjur_r2"
      ],
      -0.5
    )
    testthat::expect_equal(
      data_variable_repeat_one[["estimate"]][
        data_variable_repeat_one[["metric_id"]] == "auc"
      ],
      0
    )
    testthat::expect_equal(
      data_variable_repeat_one[["n_observations"]],
      base::rep(4L, 3L)
    )

    data_variable_repeat_two <-
      data_taxon_metrics |>
      dplyr::filter(
        .data[["repeat_id"]] == 2L,
        .data[["taxon"]] == "taxon_variable"
      )

    testthat::expect_equal(
      data_variable_repeat_two[["estimate"]][
        data_variable_repeat_two[["metric_id"]] == "tjur_r2"
      ],
      0.7
    )
    testthat::expect_equal(
      data_variable_repeat_two[["estimate"]][
        data_variable_repeat_two[["metric_id"]] == "auc"
      ],
      1
    )

    data_one_class <-
      data_taxon_metrics |>
      dplyr::filter(.data[["taxon"]] == "taxon_one_class")

    testthat::expect_true(
      base::all(
        data_one_class[["metric_status"]][
          data_one_class[["metric_id"]] != "log_loss"
        ] == "undefined_no_absences"
      )
    )
    testthat::expect_true(
      base::all(
        data_one_class[["metric_status"]][
          data_one_class[["metric_id"]] == "log_loss"
        ] == "ok"
      )
    )

    data_incomplete <-
      data_taxon_metrics |>
      dplyr::filter(.data[["taxon"]] == "taxon_incomplete")

    testthat::expect_true(
      base::all(data_incomplete[["metric_status"]] ==
        "incomplete_predictions")
    )
    testthat::expect_true(
      base::all(base::is.na(data_incomplete[["estimate"]]))
    )

    data_tjur_repeat_one <-
      data_community_summary |>
      dplyr::filter(
        .data[["repeat_id"]] == 1L,
        .data[["metric_id"]] == "tjur_r2"
      )

    testthat::expect_equal(data_tjur_repeat_one[["estimate"]], -0.5)
    testthat::expect_equal(
      data_tjur_repeat_one[["n_taxa_evaluable"]],
      1L
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_cross_validated_predictions() validates OOF keys",
  {
    data_predictions <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 1L),
        row_index = base::c(1L, 1L),
        taxon = base::c("taxon_a", "taxon_a"),
        observed = base::c(0, 0),
        predicted_probability = base::c(0.2, 0.2),
        prediction_status = base::c("ok", "ok")
      )

    testthat::expect_error(
      evaluate_sjsdm_cross_validated_predictions(
        data_predictions = data_predictions
      ),
      "unique"
    )

    testthat::expect_error(
      evaluate_sjsdm_cross_validated_predictions(
        data_predictions = tibble::tibble()
      ),
      "non-empty"
    )
  }
)

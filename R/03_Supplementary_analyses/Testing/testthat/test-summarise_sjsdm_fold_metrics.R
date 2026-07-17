testthat::test_that(
  "summarise_sjsdm_fold_metrics() separates aggregation methods",
  {
    data_fold_metrics <-
      tidyr::expand_grid(
        repeat_id = 1L,
        fold_id = 1:3,
        taxon = "taxon_a",
        prediction_source = base::c("model", "prevalence_null"),
        metric_id = base::c("auc", "log_loss")
      ) |>
      dplyr::mutate(
        n_observations = base::rep(base::c(2L, 8L, 4L), each = 4L),
        n_presences = base::rep(base::c(1L, 2L, 2L), each = 4L),
        n_absences = .data[["n_observations"]] - .data[["n_presences"]],
        prevalence = .data[["n_presences"]] /
          .data[["n_observations"]],
        estimate = dplyr::case_when(
          .data[["metric_id"]] == "auc" &
            .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 1L ~ 0.8,
          .data[["metric_id"]] == "auc" &
            .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 2L ~ 0.4,
          .data[["metric_id"]] == "auc" &
            .data[["prediction_source"]] == "model" ~ NA_real_,
          .data[["metric_id"]] == "auc" ~ 0.5,
          .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 1L ~ 0.2,
          .data[["prediction_source"]] == "model" ~
            dplyr::if_else(.data[["fold_id"]] == 2L, 0.6, NA_real_),
          .data[["fold_id"]] == 1L ~ 0.4,
          .default = 0.5
        ),
        metric_status = dplyr::if_else(
          .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 3L,
          "incomplete_predictions",
          "ok"
        )
      )

    res <-
      summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_fold_metrics
      )

    testthat::expect_named(
      res,
      base::c("data_source_summaries", "data_paired_improvements")
    )

    data_source_summaries <-
      res |>
      purrr::chuck("data_source_summaries")

    testthat::expect_named(
      data_source_summaries,
      base::c(
        "repeat_id",
        "prediction_source",
        "metric_id",
        "aggregation_id",
        "estimate",
        "n_evaluable_fold_taxa",
        "n_total_fold_taxa",
        "fold_taxon_coverage",
        "n_folds_evaluable",
        "n_folds_total",
        "n_taxa_evaluable",
        "n_taxa_total",
        "n_observations_evaluable",
        "n_presences_evaluable",
        "n_absences_evaluable",
        "prevalence"
      )
    )
    testthat::expect_equal(base::nrow(data_source_summaries), 8L)

    data_model_auc <-
      data_source_summaries |>
      dplyr::filter(
        .data[["prediction_source"]] == "model",
        .data[["metric_id"]] == "auc"
      ) |>
      dplyr::arrange(.data[["aggregation_id"]])

    testthat::expect_equal(
      data_model_auc[["aggregation_id"]],
      base::c("fold_macro", "observation_weighted")
    )
    testthat::expect_equal(
      data_model_auc[["estimate"]],
      base::c(0.6, 0.48)
    )
    testthat::expect_equal(
      data_model_auc[["prevalence"]],
      base::c(0.375, 0.3)
    )
    testthat::expect_equal(
      data_model_auc[["n_evaluable_fold_taxa"]],
      base::c(2L, 2L)
    )
    testthat::expect_equal(
      data_model_auc[["n_total_fold_taxa"]],
      base::c(3L, 3L)
    )
    testthat::expect_equal(
      data_model_auc[["fold_taxon_coverage"]],
      base::c(2 / 3, 2 / 3)
    )
    testthat::expect_equal(
      data_model_auc[["n_observations_evaluable"]],
      base::c(10L, 10L)
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_fold_metrics() uses directional paired deltas",
  {
    data_fold_metrics <-
      tidyr::expand_grid(
        repeat_id = 1L,
        fold_id = 1:2,
        taxon = "taxon_a",
        prediction_source = base::c("model", "prevalence_null"),
        metric_id = base::c("auc", "log_loss")
      ) |>
      dplyr::mutate(
        n_observations = base::rep(base::c(2L, 8L), each = 4L),
        n_presences = base::rep(base::c(1L, 2L), each = 4L),
        n_absences = .data[["n_observations"]] - .data[["n_presences"]],
        prevalence = .data[["n_presences"]] /
          .data[["n_observations"]],
        estimate = dplyr::case_when(
          .data[["metric_id"]] == "auc" &
            .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 1L ~ 0.8,
          .data[["metric_id"]] == "auc" &
            .data[["prediction_source"]] == "model" ~ 0.4,
          .data[["metric_id"]] == "auc" ~ 0.5,
          .data[["prediction_source"]] == "model" &
            .data[["fold_id"]] == 1L ~ 0.2,
          .data[["prediction_source"]] == "model" ~ 0.6,
          .data[["fold_id"]] == 1L ~ 0.4,
          .default = 0.5
        ),
        metric_status = "ok"
      )

    res <-
      summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_fold_metrics
      )

    data_paired <-
      res |>
      purrr::chuck("data_paired_improvements") |>
      dplyr::arrange(.data[["metric_id"]], .data[["aggregation_id"]])

    testthat::expect_equal(base::nrow(data_paired), 4L)
    testthat::expect_equal(
      data_paired[["improvement_direction"]],
      base::c(
        "model_minus_null",
        "model_minus_null",
        "null_minus_model",
        "null_minus_model"
      )
    )
    testthat::expect_equal(
      data_paired[["estimate"]],
      base::c(0.1, -0.02, 0.05, -0.04)
    )
    testthat::expect_true(
      base::all(data_paired[["n_evaluable_fold_taxa"]] == 2L)
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_fold_metrics() validates metric keys",
  {
    data_fold_metrics <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 1L),
        taxon = base::c("taxon_a", "taxon_a"),
        prediction_source = base::c("model", "model"),
        metric_id = base::c("auc", "auc"),
        estimate = base::c(0.8, 0.8),
        metric_status = base::c("ok", "ok"),
        n_observations = base::c(2L, 2L),
        n_presences = base::c(1L, 1L),
        n_absences = base::c(1L, 1L),
        prevalence = base::c(0.5, 0.5)
      )

    testthat::expect_error(
      summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_fold_metrics
      ),
      "unique"
    )

    testthat::expect_error(
      summarise_sjsdm_fold_metrics(
        data_fold_metrics = dplyr::select(
          data_fold_metrics,
          -"metric_status"
        )
      ),
      "required"
    )

    data_paired_counts <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        fold_id = base::c(1L, 1L),
        taxon = base::c("taxon_a", "taxon_a"),
        prediction_source = base::c("model", "prevalence_null"),
        metric_id = base::c("auc", "auc"),
        estimate = base::c(0.8, 0.5),
        metric_status = base::c("ok", "ok"),
        n_observations = base::c(2L, 2L),
        n_presences = base::c(1L, 0L),
        n_absences = base::c(1L, 2L),
        prevalence = base::c(0.5, 0)
      )

    testthat::expect_error(
      summarise_sjsdm_fold_metrics(
        data_fold_metrics = data_paired_counts
      ),
      "identical class counts"
    )
  }
)

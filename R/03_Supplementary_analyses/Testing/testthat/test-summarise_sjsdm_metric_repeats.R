testthat::test_that(
  "summarise_sjsdm_metric_repeats() summarises repeat distributions",
  {
    data_source_summaries <-
      tibble::tibble(
        repeat_id = 1:3,
        prediction_source = base::rep("model", 3L),
        metric_id = base::rep("auc", 3L),
        aggregation_id = base::rep("fold_macro", 3L),
        estimate = base::c(1, 2, 3),
        fold_taxon_coverage = base::c(0.5, 0.75, 1)
      )

    data_paired_improvements <-
      tibble::tibble(
        repeat_id = 1:3,
        metric_id = base::rep("auc", 3L),
        improvement_direction = base::rep("model_minus_null", 3L),
        aggregation_id = base::rep("fold_macro", 3L),
        estimate = base::c(-1, 1, 2),
        fold_taxon_coverage = base::c(0.5, 0.75, 1)
      )

    res <-
      summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries = base::list(
          data_source_summaries = data_source_summaries,
          data_paired_improvements = data_paired_improvements
        )
      )

    testthat::expect_named(
      res,
      base::c(
        "data_source_repeat_distributions",
        "data_paired_repeat_distributions"
      )
    )

    data_source <-
      res |>
      purrr::chuck("data_source_repeat_distributions")

    testthat::expect_named(
      data_source,
      base::c(
        "prediction_source",
        "metric_id",
        "aggregation_id",
        "estimate_mean",
        "estimate_median",
        "estimate_standard_deviation",
        "lwr_95",
        "upr_95",
        "n_repeats_evaluable",
        "n_repeats_total",
        "fold_taxon_coverage_mean",
        "fold_taxon_coverage_min",
        "fold_taxon_coverage_max"
      )
    )
    testthat::expect_equal(base::nrow(data_source), 1L)
    testthat::expect_equal(data_source[["estimate_mean"]], 2)
    testthat::expect_equal(data_source[["estimate_median"]], 2)
    testthat::expect_equal(
      data_source[["estimate_standard_deviation"]],
      1
    )
    testthat::expect_equal(data_source[["lwr_95"]], 1.05)
    testthat::expect_equal(data_source[["upr_95"]], 2.95)
    testthat::expect_equal(data_source[["n_repeats_evaluable"]], 3L)
    testthat::expect_equal(data_source[["n_repeats_total"]], 3L)
    testthat::expect_equal(
      data_source[["fold_taxon_coverage_mean"]],
      0.75
    )
    testthat::expect_equal(
      data_source[["fold_taxon_coverage_min"]],
      0.5
    )
    testthat::expect_equal(
      data_source[["fold_taxon_coverage_max"]],
      1
    )

    data_paired <-
      res |>
      purrr::chuck("data_paired_repeat_distributions")

    testthat::expect_equal(
      data_paired[["proportion_repeats_positive"]],
      2 / 3
    )
    testthat::expect_equal(data_paired[["lwr_95"]], -0.9)
    testthat::expect_equal(data_paired[["upr_95"]], 1.95)
  }
)

testthat::test_that(
  "summarise_sjsdm_metric_repeats() handles unavailable estimates",
  {
    data_source_summaries <-
      tibble::tibble(
        repeat_id = 1:3,
        prediction_source = base::rep("model", 3L),
        metric_id = base::rep("calibration_slope", 3L),
        aggregation_id = base::rep("fold_macro", 3L),
        estimate = base::rep(NA_real_, 3L),
        fold_taxon_coverage = base::c(0, 0, 0)
      )

    data_paired_improvements <-
      tibble::tibble(
        repeat_id = base::integer(),
        metric_id = base::character(),
        improvement_direction = base::character(),
        aggregation_id = base::character(),
        estimate = base::numeric(),
        fold_taxon_coverage = base::numeric()
      )

    res <-
      summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries = base::list(
          data_source_summaries = data_source_summaries,
          data_paired_improvements = data_paired_improvements
        )
      )

    data_source <-
      res |>
      purrr::chuck("data_source_repeat_distributions")

    testthat::expect_true(base::is.na(data_source[["estimate_mean"]]))
    testthat::expect_true(base::is.na(data_source[["lwr_95"]]))
    testthat::expect_equal(data_source[["n_repeats_evaluable"]], 0L)
    testthat::expect_equal(data_source[["n_repeats_total"]], 3L)

    data_paired <-
      res |>
      purrr::chuck("data_paired_repeat_distributions")

    testthat::expect_equal(base::nrow(data_paired), 0L)
  }
)

testthat::test_that(
  "summarise_sjsdm_metric_repeats() validates summary keys",
  {
    data_source_summaries <-
      tibble::tibble(
        repeat_id = base::c(1L, 1L),
        prediction_source = base::c("model", "model"),
        metric_id = base::c("auc", "auc"),
        aggregation_id = base::c("fold_macro", "fold_macro"),
        estimate = base::c(0.6, 0.6),
        fold_taxon_coverage = base::c(0.8, 0.8)
      )

    data_paired_improvements <-
      tibble::tibble(
        repeat_id = base::integer(),
        metric_id = base::character(),
        improvement_direction = base::character(),
        aggregation_id = base::character(),
        estimate = base::numeric(),
        fold_taxon_coverage = base::numeric()
      )

    testthat::expect_error(
      summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries = base::list(
          data_source_summaries = data_source_summaries,
          data_paired_improvements = data_paired_improvements
        )
      ),
      "unique"
    )

    testthat::expect_error(
      summarise_sjsdm_metric_repeats(
        list_fold_metric_summaries = base::list(
          data_source_summaries = dplyr::select(
            data_source_summaries,
            -"estimate"
          ),
          data_paired_improvements = data_paired_improvements
        )
      ),
      "required"
    )
  }
)

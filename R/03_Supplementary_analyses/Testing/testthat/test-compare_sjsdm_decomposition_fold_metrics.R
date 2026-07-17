testthat::test_that(
  "compare_sjsdm_decomposition_fold_metrics() preserves raw paired effects",
  {
    data_metrics <-
      tidyr::expand_grid(
        variant = base::c(
          "full",
          "no_abiotic",
          "no_spatial",
          "no_associations"
        ),
        metric_id = base::c(
          "tjur_r2",
          "auc",
          "log_loss",
          "brier_score"
        )
      ) |>
      dplyr::mutate(
        repeat_id = 1L,
        fold_id = 1L,
        taxon = "taxon_a",
        estimate = base::c(
          0.2, 0.8, 0.3, 0.1,
          0.1, 0.7, 0.4, 0.15,
          0.25, 0.82, 0.28, 0.09,
          0.18, 0.79, 0.31, 0.11
        ),
        metric_status = "ok"
      )

    data_eligibility <-
      tibble::tibble(
        taxon = "taxon_a",
        eligible = TRUE
      )

    res <-
      compare_sjsdm_decomposition_fold_metrics(
        data_fold_metrics = data_metrics,
        data_taxon_eligibility = data_eligibility
      )

    testthat::expect_equal(base::nrow(res), 12L)
    testthat::expect_setequal(
      res[["component"]],
      base::c("Abiotic", "Spatial", "Associations")
    )
    testthat::expect_true(base::all(res[["pair_status"]] == "ok"))
    testthat::expect_true(base::all(res[["eligible"]]))

    data_no_abiotic <-
      res |>
      dplyr::filter(.data[["reduced_variant"]] == "no_abiotic") |>
      dplyr::arrange(
        base::match(
          .data[["metric_id"]],
          base::c("tjur_r2", "auc", "log_loss", "brier_score")
        )
      )

    testthat::expect_equal(
      data_no_abiotic[["delta_full_advantage"]],
      base::c(0.1, 0.1, 0.1, 0.05)
    )

    data_no_spatial <-
      res |>
      dplyr::filter(.data[["reduced_variant"]] == "no_spatial")

    testthat::expect_true(
      base::all(data_no_spatial[["delta_full_advantage"]] < 0)
    )
  }
)

testthat::test_that(
  "compare_sjsdm_decomposition_fold_metrics() exposes unavailable pairs",
  {
    data_metrics <-
      tibble::tibble(
        variant = base::c("full", "no_abiotic"),
        repeat_id = 1L,
        fold_id = 1L,
        taxon = "taxon_a",
        metric_id = "log_loss",
        estimate = base::c(0.3, NA_real_),
        metric_status = base::c("ok", "not_evaluable")
      )

    res <-
      compare_sjsdm_decomposition_fold_metrics(
        data_fold_metrics = data_metrics,
        data_taxon_eligibility = tibble::tibble(
          taxon = "taxon_a",
          eligible = FALSE
        )
      )

    testthat::expect_equal(res[["pair_status"]], "reduced_not_evaluable")
    testthat::expect_true(base::is.na(res[["delta_full_advantage"]]))
    testthat::expect_false(res[["eligible"]])
  }
)

testthat::test_that(
  "compare_sjsdm_decomposition_fold_metrics() rejects duplicate keys",
  {
    data_metrics <-
      tibble::tibble(
        variant = base::c("full", "full"),
        repeat_id = 1L,
        fold_id = 1L,
        taxon = "taxon_a",
        metric_id = "auc",
        estimate = 0.8,
        metric_status = "ok"
      )

    testthat::expect_error(
      compare_sjsdm_decomposition_fold_metrics(
        data_fold_metrics = data_metrics,
        data_taxon_eligibility = tibble::tibble(
          taxon = "taxon_a",
          eligible = TRUE
        )
      ),
      "unique"
    )
  }
)

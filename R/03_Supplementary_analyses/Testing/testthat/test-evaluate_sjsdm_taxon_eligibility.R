testthat::test_that(
  "evaluate_sjsdm_taxon_eligibility() applies declared fold rules",
  {
    data_metrics <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:5,
        taxon = base::c("eligible", "rare", "unstable")
      ) |>
      dplyr::mutate(
        prediction_source = "model",
        metric_id = "tjur_r2",
        estimate = dplyr::case_when(
          .data[["taxon"]] == "unstable" &
            .data[["fold_id"]] > 3L ~ NA_real_,
          TRUE ~ 0.1
        ),
        metric_status = dplyr::if_else(
          base::is.finite(.data[["estimate"]]),
          "ok",
          "single_class"
        ),
        n_observations = 10L,
        n_presences = dplyr::if_else(
          .data[["taxon"]] == "rare",
          0L,
          5L
        ),
        n_absences = .data[["n_observations"]] -
          .data[["n_presences"]],
        prevalence = .data[["n_presences"]] /
          .data[["n_observations"]]
      )

    res <-
      evaluate_sjsdm_taxon_eligibility(data_fold_metrics = data_metrics)

    testthat::expect_equal(
      dplyr::filter(res, .data[["taxon"]] == "eligible") |>
        dplyr::pull("eligibility_status"),
      "eligible"
    )
    testthat::expect_equal(
      dplyr::filter(res, .data[["taxon"]] == "rare") |>
        dplyr::pull("eligibility_status"),
      "prevalence_below_minimum"
    )
    testthat::expect_equal(
      dplyr::filter(res, .data[["taxon"]] == "unstable") |>
        dplyr::pull("eligibility_status"),
      "insufficient_evaluable_folds"
    )
    testthat::expect_equal(res[["n_folds_total"]], base::rep(10L, 3L))
    testthat::expect_equal(
      dplyr::filter(res, .data[["taxon"]] == "unstable") |>
        dplyr::pull("evaluable_fold_fraction"),
      0.6
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_taxon_eligibility() reports combined failures",
  {
    data_metrics <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1:2,
        taxon = "rare_unstable",
        prediction_source = "model",
        metric_id = "tjur_r2",
        estimate = base::c(NA_real_, 0.1),
        metric_status = base::c("single_class", "ok"),
        n_observations = 10L,
        n_presences = 0L,
        n_absences = 10L,
        prevalence = 0
      )

    res <-
      evaluate_sjsdm_taxon_eligibility(data_fold_metrics = data_metrics)

    testthat::expect_false(res[["eligible"]])
    testthat::expect_equal(
      res[["eligibility_status"]],
      "prevalence_below_minimum;insufficient_evaluable_folds"
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_taxon_eligibility() validates thresholds",
  {
    data_empty <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        taxon = base::character(),
        prediction_source = base::character(),
        metric_id = base::character(),
        estimate = base::numeric(),
        metric_status = base::character(),
        n_observations = base::integer(),
        n_presences = base::integer(),
        n_absences = base::integer(),
        prevalence = base::numeric()
      )

    testthat::expect_error(
      evaluate_sjsdm_taxon_eligibility(
        data_fold_metrics = data_empty,
        minimum_prevalence = 0.6,
        maximum_prevalence = 0.4
      ),
      "prevalence"
    )
  }
)

testthat::test_that(
  "evaluate_sjsdm_taxon_eligibility() excludes non-ok finite estimates",
  {
    data_metrics <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1:2,
        taxon = "taxon_a",
        prediction_source = "model",
        metric_id = "tjur_r2",
        estimate = base::c(0.1, 0.9),
        metric_status = base::c("ok", "fit_warning"),
        n_observations = 10L,
        n_presences = 5L,
        n_absences = 5L,
        prevalence = 0.5
      )

    res <-
      evaluate_sjsdm_taxon_eligibility(
        data_fold_metrics = data_metrics,
        minimum_evaluable_fraction = 0.5
      )

    testthat::expect_equal(res[["n_folds_evaluable"]], 1L)
    testthat::expect_equal(res[["mean_tjur_r2"]], 0.1)
  }
)

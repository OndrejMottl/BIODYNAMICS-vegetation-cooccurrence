testthat::test_that(
  "summarise_sjsdm_decomposition_effects() uses fold-macro repeat effects",
  {
    data_comparisons <-
      tidyr::expand_grid(
        repeat_id = 1:3,
        fold_id = 1:2,
        taxon = base::c("taxon_a", "taxon_b")
      ) |>
      dplyr::mutate(
        reduced_variant = "no_abiotic",
        component = "Abiotic",
        metric_id = "log_loss",
        eligible = .data[["taxon"]] == "taxon_a",
        pair_status = "ok",
        delta_full_advantage =
          0.1 * .data[["repeat_id"]] +
          0.1 * (.data[["fold_id"]] - 1L) +
          0.2 * (.data[["taxon"]] == "taxon_b")
      )

    res <-
      summarise_sjsdm_decomposition_effects(data_comparisons)

    testthat::expect_named(
      res,
      base::c("data_fold_effects", "data_repeat_effects", "data_summary")
    )

    data_repeat_all <-
      res[["data_repeat_effects"]] |>
      dplyr::filter(.data[["scope"]] == "all_taxa")

    data_repeat_eligible <-
      res[["data_repeat_effects"]] |>
      dplyr::filter(.data[["scope"]] == "eligible_taxa")

    testthat::expect_equal(
      data_repeat_all[["mean_delta_full_advantage"]],
      base::c(0.25, 0.35, 0.45)
    )
    testthat::expect_equal(
      data_repeat_eligible[["mean_delta_full_advantage"]],
      base::c(0.15, 0.25, 0.35)
    )
    testthat::expect_equal(
      res[["data_summary"]][["n_repeats"]],
      base::c(3L, 3L)
    )
    testthat::expect_true(
      base::all(
        base::c("lwr_95", "upr_95") %in%
          base::colnames(res[["data_summary"]])
      )
    )

    data_summary_all <-
      res[["data_summary"]] |>
      dplyr::filter(.data[["scope"]] == "all_taxa")

    testthat::expect_equal(
      data_summary_all[["mean_delta_full_advantage"]],
      0.35
    )
    testthat::expect_equal(data_summary_all[["lwr_95"]], 0.255)
    testthat::expect_equal(data_summary_all[["upr_95"]], 0.445)
    testthat::expect_equal(data_summary_all[["minimum_repeat_delta"]], 0.25)
    testthat::expect_equal(data_summary_all[["maximum_repeat_delta"]], 0.45)
  }
)

testthat::test_that(
  "summarise_sjsdm_decomposition_effects() excludes unavailable pairs",
  {
    data_comparisons <-
      tibble::tibble(
        repeat_id = 1L,
        fold_id = 1L,
        taxon = base::c("taxon_a", "taxon_b"),
        reduced_variant = "no_spatial",
        component = "Spatial",
        metric_id = "auc",
        eligible = TRUE,
        pair_status = base::c("ok", "reduced_not_evaluable"),
        delta_full_advantage = base::c(0.1, NA_real_)
      )

    res <-
      summarise_sjsdm_decomposition_effects(data_comparisons)

    testthat::expect_true(
      base::all(res[["data_fold_effects"]][["n_taxa"]] == 1L)
    )
    testthat::expect_equal(
      res[["data_repeat_effects"]][["mean_delta_full_advantage"]],
      base::c(0.1, 0.1)
    )
  }
)

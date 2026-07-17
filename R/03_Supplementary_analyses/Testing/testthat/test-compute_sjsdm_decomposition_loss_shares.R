testthat::test_that(
  "compute_sjsdm_decomposition_loss_shares() normalizes positive loss effects",
  {
    data_repeat_effects <-
      tidyr::expand_grid(
        scope = "eligible_taxa",
        repeat_id = 1:2,
        component = base::c("Abiotic", "Spatial", "Associations")
      ) |>
      dplyr::mutate(
        reduced_variant = base::c(
          "no_abiotic",
          "no_spatial",
          "no_associations"
        )[base::match(
          .data[["component"]],
          base::c("Abiotic", "Spatial", "Associations")
        )],
        metric_id = "log_loss",
        mean_delta_full_advantage = base::rep(
          base::c(0.6, -0.1, 0.4),
          times = 2L
        )
      )

    res <-
      compute_sjsdm_decomposition_loss_shares(data_repeat_effects)

    testthat::expect_named(
      res,
      base::c("data_repeat_shares", "data_share_summary")
    )
    testthat::expect_equal(
      res[["data_repeat_shares"]][["share_percent"]],
      base::rep(base::c(60, 0, 40), times = 2L)
    )
    testthat::expect_true(
      base::all(res[["data_repeat_shares"]][["defined"]])
    )
    testthat::expect_equal(
      res[["data_share_summary"]][["mean_share_percent"]],
      base::c(60, 40, 0)
    )
  }
)

testthat::test_that(
  "compute_sjsdm_decomposition_loss_shares() preserves undefined groups",
  {
    data_repeat_effects <-
      tibble::tibble(
        scope = "all_taxa",
        reduced_variant = "no_spatial",
        component = "Spatial",
        metric_id = "log_loss",
        repeat_id = 1L,
        mean_delta_full_advantage = -0.1
      )

    res <-
      compute_sjsdm_decomposition_loss_shares(data_repeat_effects)

    testthat::expect_false(res[["data_repeat_shares"]][["defined"]])
    testthat::expect_true(
      base::is.na(res[["data_repeat_shares"]][["share_percent"]])
    )
  }
)

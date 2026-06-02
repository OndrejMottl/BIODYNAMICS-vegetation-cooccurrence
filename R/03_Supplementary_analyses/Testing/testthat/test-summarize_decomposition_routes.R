testthat::test_that(
  "summarize_decomposition_routes() groups shares by route",
  {
    data_metrics <-
      tibble::tibble(
        route_id = base::rep(c("route_a", "route_b"), each = 4),
        repeat_id = 1L,
        fold_id = 1L,
        variant = base::rep(
          c("full", "no_abiotic", "no_spatial", "no_associations"),
          times = 2
        ),
        status = "ok",
        loss = c(1, 2, 1, 1, 1, 1, 3, 1)
      )

    res <-
      summarize_decomposition_routes(variant_metrics = data_metrics)

    data_fold_shares <-
      res |>
      purrr::chuck("data_fold_shares")

    data_route_a <-
      data_fold_shares |>
      dplyr::filter(
        .data$route_id == "route_a",
        .data$component == "Abiotic"
      )

    data_route_b <-
      data_fold_shares |>
      dplyr::filter(
        .data$route_id == "route_b",
        .data$component == "Spatial"
      )

    testthat::expect_equal(data_route_a[["share"]], 100)
    testthat::expect_equal(data_route_b[["share"]], 100)
  }
)

testthat::test_that(
  "summarize_decomposition_routes() excludes failed variants",
  {
    data_metrics <-
      tibble::tibble(
        route_id = "route_a",
        repeat_id = 1L,
        fold_id = 1L,
        variant = c("full", "no_abiotic", "no_spatial", "no_associations"),
        status = c("ok", "ok", "not_converged", "ok"),
        loss = c(1, 2, 3, 4)
      )

    res <-
      summarize_decomposition_routes(variant_metrics = data_metrics)

    data_fold_shares <-
      res |>
      purrr::chuck("data_fold_shares")

    testthat::expect_true(
      base::all(
        base::is.na(
          data_fold_shares |>
            dplyr::pull(.data$share)
        )
      )
    )
  }
)

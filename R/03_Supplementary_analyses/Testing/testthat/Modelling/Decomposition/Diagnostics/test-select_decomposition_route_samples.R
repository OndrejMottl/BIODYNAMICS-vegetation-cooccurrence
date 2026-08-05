testthat::test_that(
  "select_decomposition_route_samples() returns pooled samples",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("b", "a"),
          age = c(0, 100)
        ),
        data_community_matrix = base::matrix(
          data = c(1, 0, 0, 1),
          nrow = 2,
          dimnames = base::list(
            c("b__0", "a__100"),
            c("taxon_a", "taxon_b")
          )
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L)
      )

    route <-
      build_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "pooled_spatial_age")

    res <-
      select_decomposition_route_samples(
        route = route,
        inputs = inputs
      )

    testthat::expect_equal(
      res |>
        dplyr::pull(".row_name"),
      c("a__100", "b__0")
    )
  }
)

testthat::test_that(
  "select_decomposition_route_samples() selects best slice",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("a", "b", "a", "b", "c"),
          age = c(0, 0, 100, 100, 100)
        ),
        data_community_matrix = base::matrix(
          data = c(
            1, 1,
            1, 1,
            1, 0,
            0, 1,
            1, 1
          ),
          nrow = 5,
          byrow = TRUE,
          dimnames = base::list(
            c("a__0", "b__0", "a__100", "b__100", "c__100"),
            c("taxon_a", "taxon_b")
          )
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 2L)
      )

    route <-
      build_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "temporal_best_slice")

    res <-
      select_decomposition_route_samples(
        route = route,
        inputs = inputs
      )

    testthat::expect_equal(
      res |>
        dplyr::pull(age) |>
        base::unique(),
      100
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() filters train-constant taxa",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6)
        ),
        data_community_matrix = base::matrix(
          data = c(
            1, 0,
            1, 1,
            1, 0,
            1, 1,
            1, 0,
            0, 1
          ),
          nrow = 6,
          byrow = TRUE,
          dimnames = base::list(
            base::c(
              "a__0", "b__0", "c__0", "d__0", "e__0", "f__0"
            ),
            base::c("taxon_drop", "taxon_keep")
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6),
          bio = base::c(10, 12, 14, 16, 18, 20)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = base::c(100, 400, 700, 200, 600, 900),
          coord_y_km = base::c(100, 500, 900, 300, 700, 200)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      base::c("a", "b", "c", "d", "e", "f")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = base::c("a__0", "b__0", "c__0", "d__0", "e__0"),
        test_ids = "f__0"
      )

    data_train_input <-
      res |>
      purrr::chuck("data_train_input")

    data_test_observed <-
      res |>
      purrr::chuck("data_test_observed")

    testthat::expect_equal(
      base::colnames(data_train_input[["data_community_to_fit"]]),
      "taxon_keep"
    )
    testthat::expect_equal(
      base::colnames(data_test_observed),
      "taxon_keep"
    )
    testthat::expect_equal(
      res[["data_taxa_mapping"]][["status"]],
      base::c("constant_in_training", "retained")
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() applies train scaling",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6)
        ),
        data_community_matrix = base::matrix(
          data = base::c(0, 1, 0, 1, 0, 1),
          nrow = 6,
          dimnames = base::list(
            base::c(
              "a__0", "b__0", "c__0", "d__0", "e__0", "f__0"
            ),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6),
          bio = base::c(10, 12, 14, 16, 18, 20)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = base::c(100, 400, 700, 200, 600, 900),
          coord_y_km = base::c(100, 500, 900, 300, 700, 200)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      base::c("a", "b", "c", "d", "e", "f")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = base::c("a__0", "b__0", "c__0", "d__0", "e__0"),
        test_ids = "f__0"
      )

    data_test_input <-
      res |>
      purrr::chuck("data_test_input")

    testthat::expect_equal(
      data_test_input[["data_abiotic_to_fit"]][["bio"]],
      (20 - base::mean(base::c(10, 12, 14, 16, 18))) /
        stats::sd(base::c(10, 12, 14, 16, 18))
    )
    testthat::expect_true(
      base::all(
        base::is.finite(
          data_test_input[["data_spatial_to_fit"]][["mev_1"]]
        )
      )
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() computes spatial MEM if core is NULL",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6)
        ),
        data_community_matrix = base::matrix(
          data = base::c(0, 1, 0, 1, 0, 1),
          nrow = 6,
          dimnames = base::list(
            base::c(
              "a__0", "b__0", "c__0", "d__0", "e__0", "f__0"
            ),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::rep(0, 6),
          bio = base::c(10, 12, 14, 16, 18, 20)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = base::c(100, 400, 700, 200, 600, 900),
          coord_y_km = base::c(100, 500, 900, 300, 700, 200)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      base::c("a", "b", "c", "d", "e", "f")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = base::c("a__0", "b__0", "c__0", "d__0", "e__0"),
        test_ids = "f__0"
      )

    data_train_input <-
      res |>
      purrr::chuck("data_train_input")

    testthat::expect_true(
      "data_spatial_to_fit" %in% base::names(data_train_input)
    )
    testthat::expect_equal(
      res[["data_spatial_diagnostics"]][["n_train_locations"]],
      5L
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() z-scores age from train fold",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::c(0, 500, 1000, 1500, 2000, 2500)
        ),
        data_community_matrix = base::matrix(
          data = base::c(0, 1, 0, 1, 0, 1),
          nrow = 6,
          dimnames = base::list(
            base::c(
              "a__0", "b__500", "c__1000", "d__1500", "e__2000",
              "f__2500"
            ),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f"),
          age = base::c(0, 500, 1000, 1500, 2000, 2500),
          bio = base::c(10, 12, 14, 16, 18, 20)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = base::c(100, 400, 700, 200, 600, 900),
          coord_y_km = base::c(100, 500, 900, 300, 700, 200)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      base::c("a", "b", "c", "d", "e", "f")

    route <-
      tibble::tibble(
        route_id = "test_age_z",
        sample_mode = "pooled",
        spatial_mode = "spatial",
        use_age = TRUE,
        age_formula_mode = "main_effect",
        age_scale_mode = "z_score"
      )

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = base::c(
          "a__0", "b__500", "c__1000", "d__1500", "e__2000"
        ),
        test_ids = "f__2500"
      )

    data_train_input <-
      res |>
      purrr::chuck("data_train_input")

    data_test_input <-
      res |>
      purrr::chuck("data_test_input")

    vec_train_age_expected <-
      base::as.numeric(
        base::scale(base::c(0, 500, 1000, 1500, 2000))
      )

    age_test_expected <-
      (2500 - base::mean(base::c(0, 500, 1000, 1500, 2000))) /
        stats::sd(base::c(0, 500, 1000, 1500, 2000))

    testthat::expect_equal(
      data_train_input[["data_abiotic_to_fit"]][["age"]],
      vec_train_age_expected
    )
    testthat::expect_equal(
      data_test_input[["data_abiotic_to_fit"]][["age"]],
      age_test_expected
    )
  }
)

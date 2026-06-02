testthat::test_that(
  "prepare_decomposition_fold_input() filters train-constant taxa",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 0, 0, 0)
        ),
        data_community_matrix = base::matrix(
          data = c(
            1, 0,
            1, 1,
            1, 0,
            0, 1
          ),
          nrow = 4,
          byrow = TRUE,
          dimnames = base::list(
            c("a__0", "b__0", "c__0", "d__0"),
            c("taxon_drop", "taxon_keep")
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 0, 0, 0),
          bio = c(10, 12, 14, 16)
        ),
        data_spatial_mev_core = base::data.frame(mev_1 = c(1, 3, 5, 7)),
        data_coords_projected = base::data.frame(
          coord_x_km = c(1, 2, 3, 4),
          coord_y_km = c(1, 1, 1, 1)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_spatial_mev_core"]]) <-
      c("a", "b", "c", "d")

    base::rownames(inputs[["data_coords_projected"]]) <-
      c("a", "b", "c", "d")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data$route_id == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = c("a__0", "b__0", "c__0"),
        test_ids = "d__0"
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
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() applies train scaling",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 0, 0, 0)
        ),
        data_community_matrix = base::matrix(
          data = c(0, 1, 0, 1),
          nrow = 4,
          dimnames = base::list(
            c("a__0", "b__0", "c__0", "d__0"),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 0, 0, 0),
          bio = c(10, 12, 14, 16)
        ),
        data_spatial_mev_core = base::data.frame(mev_1 = c(1, 3, 5, 7)),
        data_coords_projected = base::data.frame(
          coord_x_km = c(1, 2, 3, 4),
          coord_y_km = c(1, 1, 1, 1)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_spatial_mev_core"]]) <-
      c("a", "b", "c", "d")

    base::rownames(inputs[["data_coords_projected"]]) <-
      c("a", "b", "c", "d")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data$route_id == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = c("a__0", "b__0", "c__0"),
        test_ids = "d__0"
      )

    data_test_input <-
      res |>
      purrr::chuck("data_test_input")

    testthat::expect_equal(
      data_test_input[["data_abiotic_to_fit"]][["bio"]],
      2
    )
    testthat::expect_equal(
      data_test_input[["data_spatial_to_fit"]][["mev_1"]],
      2
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() computes spatial MEM if core is NULL",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("a", "b", "c", "d", "e"),
          age = c(0, 0, 0, 0, 0)
        ),
        data_community_matrix = base::matrix(
          data = c(0, 1, 0, 1, 0),
          nrow = 5,
          dimnames = base::list(
            c("a__0", "b__0", "c__0", "d__0", "e__0"),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = c("a", "b", "c", "d", "e"),
          age = c(0, 0, 0, 0, 0),
          bio = c(10, 12, 14, 16, 18)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = c(0, 1, 3, 6, 10),
          coord_y_km = c(0, 2, 1, 5, 3)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      c("a", "b", "c", "d", "e")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data$route_id == "pooled_spatial_age")

    res <-
      prepare_decomposition_fold_input(
        route = route,
        inputs = inputs,
        train_ids = c("a__0", "b__0", "c__0", "d__0"),
        test_ids = "e__0"
      )

    data_train_input <-
      res |>
      purrr::chuck("data_train_input")

    testthat::expect_true(
      "data_spatial_to_fit" %in% base::names(data_train_input)
    )
  }
)

testthat::test_that(
  "prepare_decomposition_fold_input() z-scores age from train fold",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 500, 1000, 1500)
        ),
        data_community_matrix = base::matrix(
          data = c(0, 1, 0, 1),
          nrow = 4,
          dimnames = base::list(
            c("a__0", "b__500", "c__1000", "d__1500"),
            "taxon_keep"
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = c("a", "b", "c", "d"),
          age = c(0, 500, 1000, 1500),
          bio = c(10, 12, 14, 16)
        ),
        data_spatial_mev_core = base::data.frame(mev_1 = c(1, 3, 5, 7)),
        data_coords_projected = base::data.frame(
          coord_x_km = c(1, 2, 3, 4),
          coord_y_km = c(1, 1, 1, 1)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 1L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_spatial_mev_core"]]) <-
      c("a", "b", "c", "d")

    base::rownames(inputs[["data_coords_projected"]]) <-
      c("a", "b", "c", "d")

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
        train_ids = c("a__0", "b__500", "c__1000"),
        test_ids = "d__1500"
      )

    data_train_input <-
      res |>
      purrr::chuck("data_train_input")

    data_test_input <-
      res |>
      purrr::chuck("data_test_input")

    testthat::expect_equal(
      data_train_input[["data_abiotic_to_fit"]][["age"]],
      c(-1, 0, 1)
    )
    testthat::expect_equal(
      data_test_input[["data_abiotic_to_fit"]][["age"]],
      2
    )
  }
)

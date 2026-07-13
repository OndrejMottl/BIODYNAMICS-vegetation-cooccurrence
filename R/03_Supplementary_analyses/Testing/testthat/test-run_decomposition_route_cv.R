testthat::test_that(
  "run_decomposition_route_cv() marks non-converged variants",
  {
    inputs <-
      base::list(
        data_sample_ids = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f", "g"),
          age = base::rep(0, 7)
        ),
        data_community_matrix = base::matrix(
          data = c(
            1, 0,
            0, 1,
            1, 0,
            0, 1,
            1, 0,
            0, 1,
            1, 0
          ),
          nrow = 7,
          byrow = TRUE,
          dimnames = base::list(
            base::c(
              "a__0", "b__0", "c__0", "d__0", "e__0", "f__0", "g__0"
            ),
            base::c("taxon_a", "taxon_b")
          )
        ),
        data_abiotic_wide = tibble::tibble(
          dataset_name = base::c("a", "b", "c", "d", "e", "f", "g"),
          age = base::rep(0, 7),
          bio = base::seq_len(7)
        ),
        data_spatial_mev_core = NULL,
        data_coords_projected = base::data.frame(
          coord_x_km = base::c(100, 400, 700, 200, 600, 900, 0),
          coord_y_km = base::c(100, 500, 900, 300, 700, 200, 0)
        ),
        config_model_fitting = base::list(error_family = "binomial"),
        config_data_processing = base::list(min_n_taxa = 2L),
        config_spatial_predictors = base::list(n_mev = 1L)
      )

    base::rownames(inputs[["data_coords_projected"]]) <-
      base::c("a", "b", "c", "d", "e", "f", "g")

    route <-
      make_decomposition_diagnostic_routes() |>
      dplyr::filter(.data[["route_id"]] == "pooled_spatial_age")

    fit_fn <- function(...) {
      list_arguments <-
        base::list(...)

      base::list(
        taxa = base::colnames(
          list_arguments[["data_to_fit"]][["data_community_to_fit"]]
        )
      )
    }

    predict_fn <- function(object, newdata, SP, type) {
      data_predicted <-
        base::matrix(
          data = 0.5,
          nrow = base::nrow(newdata),
          ncol = base::length(object[["taxa"]])
        )

      base::colnames(data_predicted) <- object[["taxa"]]

      return(data_predicted)
    }

    convergence_fn <- function(mod_fit) {
      base::list(
        linear_trend_slope = 0.02,
        median_diff = 0.5,
        epochs_run = 10L,
        early_stopping_triggered = FALSE
      )
    }

    res <-
      run_decomposition_route_cv(
        route = route,
        inputs = inputs,
        cv_indices = base::list(base::list(fold_001 = base::c(6L, 7L))),
        fit_config = base::list(device = "cpu"),
        fit_fn = fit_fn,
        predict_fn = predict_fn,
        convergence_fn = convergence_fn,
        verbose = FALSE
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_true(
      base::all(res[["status"]] == "not_converged")
    )
    testthat::expect_false(base::any(res[["converged"]]))
  }
)

testthat::test_that(
  "read_spatial_resolution_prediction_inputs() reads suffixed targets",
  {
    data_meta <-
      tibble::tibble(
        name = c(
          "model_jsdm_selected_genus",
          "model_evaluation_genus",
          "data_model_input_genus",
          "data_coords_projected",
          "data_spatial_mev_core",
          "data_spatial_mev_samples_genus",
          "data_spatial_scaled_list_genus"
        ),
        error = NA_character_
      )

    meta_fn <- function(...) {
      return(data_meta)
    }

    read_target_fn <- function(name, store) {
      return(base::list(name = name, store = store))
    }

    res <-
      read_spatial_resolution_prediction_inputs(
        store_path = "mock_store",
        resolution_id = "genus",
        read_target_fn = read_target_fn,
        meta_fn = meta_fn
      )

    testthat::expect_named(
      res,
      c(
        "mod_jsdm",
        "model_evaluation",
        "data_model_input",
        "data_coords_projected",
        "data_spatial_mev_core",
        "data_spatial_mev_samples",
        "data_spatial_scaled_list"
      )
    )
    testthat::expect_equal(
      purrr::pluck(res, "mod_jsdm", "name"),
      "model_jsdm_selected_genus"
    )
  }
)

testthat::test_that(
  "read_spatial_resolution_prediction_inputs() errors on missing target",
  {
    data_meta <-
      tibble::tibble(
        name = "model_jsdm_selected_genus",
        error = NA_character_
      )

    meta_fn <- function(...) {
      return(data_meta)
    }

    read_target_fn <- function(name, store) {
      return(NULL)
    }

    testthat::expect_error(
      read_spatial_resolution_prediction_inputs(
        store_path = "mock_store",
        resolution_id = "genus",
        read_target_fn = read_target_fn,
        meta_fn = meta_fn
      ),
      regexp = "missing or errored"
    )
  }
)

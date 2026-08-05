testthat::test_that(
  "load_decomposition_diagnostic_inputs() reads required targets",
  {
    vec_read_names <- base::character()

    tar_read_fn <- function(name, store) {
      vec_read_names <<- base::c(vec_read_names, name)
      name
    }

    res <-
      load_decomposition_diagnostic_inputs(
        store_path = "store",
        resolution_id = "genus",
        tar_read_fn = tar_read_fn
      )

    testthat::expect_named(
      res,
      c(
        "data_sample_ids",
        "data_community_matrix",
        "data_abiotic_wide",
        "data_spatial_mev_core",
        "data_coords_projected",
        "config_data_processing",
        "config_model_fitting",
        "config_spatial_predictors"
      )
    )
    testthat::expect_true(
      "data_community_model_matrix_genus" %in% vec_read_names
    )
  }
)

testthat::test_that(
  "load_decomposition_diagnostic_inputs() falls back to resolution config",
  {
    vec_read_names <- base::character()

    tar_read_fn <- function(name, store) {
      vec_read_names <<- base::c(vec_read_names, name)

      if (
        name == "config_model_fitting"
      ) {
        base::stop("target not found")
      }

      return(name)
    }

    res <-
      load_decomposition_diagnostic_inputs(
        store_path = "store",
        resolution_id = "genus",
        tar_read_fn = tar_read_fn
      )

    testthat::expect_equal(
      res[["config_model_fitting"]],
      "config_model_fitting_genus"
    )

    testthat::expect_true(
      "config_model_fitting" %in% vec_read_names
    )

    testthat::expect_true(
      "config_model_fitting_genus" %in% vec_read_names
    )
  }
)

testthat::test_that(
  "predict_spatial_resolution_grid_age() returns long probabilities",
  {
    climate_fn <- function(
        data_grid,
        age,
        abiotic_variables,
        x_lim,
        y_lim,
        cache_dir) {
      return(
        tibble::tibble(
          grid_id = c(1L, 2L),
          coord_long = c(10, 11),
          coord_lat = c(50, 51),
          bio1 = c(4, 8),
          age = age
        )
      )
    }

    predict_fn <- function(object, newdata, SP, type) {
      return(
        base::matrix(
          data = c(0.2, 0.4, 0.8, 0.6),
          nrow = 2,
          dimnames = base::list(NULL, c("A", "B"))
        )
      )
    }

    list_prediction_inputs <-
      base::list(
        mod_jsdm = base::list(species = c("A", "B")),
        data_model_input = base::list(
          scale_attributes = base::list(
            age = base::list("scaled:center" = 0),
            bio1 = base::list(
              "scaled:center" = 6,
              "scaled:scale" = 2
            )
          )
        )
      )

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    data_coords_projected <-
      base::data.frame(
        coord_long = c(10, 11),
        coord_lat = c(50, 51),
        coord_x_km = c(0, 1),
        coord_y_km = c(0, 1)
      )
    base::rownames(data_coords_projected) <- c("grid_1", "grid_2")

    res <-
      predict_spatial_resolution_grid_age(
        prediction_inputs = list_prediction_inputs,
        data_grid = data_grid,
        data_grid_coords_projected = data_coords_projected,
        age = 0,
        abiotic_variables = "bio1",
        x_lim = c(10, 11),
        y_lim = c(50, 51),
        cache_dir = base::tempdir(),
        spatial_mode = "none",
        climate_fn = climate_fn,
        predict_fn = predict_fn
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_equal(
      base::sort(base::unique(dplyr::pull(res, taxon))),
      c("A", "B")
    )
    testthat::expect_equal(
      base::range(dplyr::pull(res, predicted_probability)),
      c(0.2, 0.8)
    )
  }
)

testthat::test_that(
  "predict_spatial_resolution_grid_age() supports spatial mode",
  {
    climate_fn <- function(
        data_grid,
        age,
        abiotic_variables,
        x_lim,
        y_lim,
        cache_dir) {
      return(
        tibble::tibble(
          grid_id = c(1L, 2L),
          coord_long = c(10, 11),
          coord_lat = c(50, 51),
          bio1 = c(4, 8),
          age = age
        )
      )
    }

    spatial_interpolate_fn <- function(
        data_coords_projected_train,
        data_mev_core,
        data_coords_projected_pred,
        spatial_scale_attributes) {
      return(
        base::data.frame(
          mev1 = c(0.1, 0.2)
        )
      )
    }

    predict_fn <- function(object, newdata, SP, type) {
      testthat::expect_false(base::is.null(SP))
      return(
        base::matrix(
          data = c(0.3, 0.7, 0.2, 0.8),
          nrow = 2,
          dimnames = base::list(NULL, c("A", "B"))
        )
      )
    }

    list_prediction_inputs <-
      base::list(
        mod_jsdm = base::list(species = c("A", "B")),
        data_model_input = base::list(
          scale_attributes = base::list(
            age = base::list("scaled:center" = 0),
            bio1 = base::list(
              "scaled:center" = 6,
              "scaled:scale" = 2
            )
          ),
          spatial_scale_attributes = base::list(
            mev1 = base::list(
              "scaled:center" = 0,
              "scaled:scale" = 1
            )
          )
        ),
        data_coords_projected = base::data.frame(
          coord_x_km = c(0, 1),
          coord_y_km = c(0, 1)
        ),
        data_spatial_mev_core = base::data.frame(mev1 = c(0.1, 0.2))
      )

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    data_coords_projected <-
      base::data.frame(
        coord_x_km = c(0, 1),
        coord_y_km = c(0, 1)
      )
    base::rownames(data_coords_projected) <- c("grid_1", "grid_2")

    res <-
      predict_spatial_resolution_grid_age(
        prediction_inputs = list_prediction_inputs,
        data_grid = data_grid,
        data_grid_coords_projected = data_coords_projected,
        age = 0,
        abiotic_variables = "bio1",
        x_lim = c(10, 11),
        y_lim = c(50, 51),
        cache_dir = base::tempdir(),
        spatial_mode = "spatial",
        climate_fn = climate_fn,
        spatial_interpolate_fn = spatial_interpolate_fn,
        predict_fn = predict_fn
      )

    testthat::expect_equal(base::nrow(res), 4L)
  }
)

testthat::test_that(
  "predict_spatial_resolution_grid_age() supports spatiotemporal mode",
  {
    climate_fn <- function(
        data_grid,
        age,
        abiotic_variables,
        x_lim,
        y_lim,
        cache_dir) {
      return(
        tibble::tibble(
          grid_id = c(1L, 2L),
          coord_long = c(10, 11),
          coord_lat = c(50, 51),
          bio1 = c(4, 8),
          age = age
        )
      )
    }

    spatiotemporal_interpolate_fn <- function(
        data_st_mev_samples,
        data_coords_projected_train,
        data_coords_projected_pred,
        pred_age,
        spatial_scale_attributes) {
      return(
        base::data.frame(
          mev1 = c(0.1, 0.2)
        )
      )
    }

    predict_fn <- function(object, newdata, SP, type) {
      testthat::expect_false(base::is.null(SP))
      return(
        base::matrix(
          data = c(0.3, 0.7, 0.2, 0.8),
          nrow = 2,
          dimnames = base::list(NULL, c("A", "B"))
        )
      )
    }

    list_prediction_inputs <-
      base::list(
        mod_jsdm = base::list(species = c("A", "B")),
        data_model_input = base::list(
          scale_attributes = base::list(
            age = base::list("scaled:center" = 0),
            bio1 = base::list(
              "scaled:center" = 6,
              "scaled:scale" = 2
            )
          ),
          spatial_scale_attributes = base::list(
            mev1 = base::list(
              "scaled:center" = 0,
              "scaled:scale" = 1
            )
          )
        ),
        data_coords_projected = base::data.frame(
          coord_x_km = c(0, 1),
          coord_y_km = c(0, 1)
        ),
        data_spatial_mev_samples = base::data.frame(
          mev1 = c(0.1, 0.2),
          age = c(0, 0)
        )
      )

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    data_coords_projected <-
      base::data.frame(
        coord_x_km = c(0, 1),
        coord_y_km = c(0, 1)
      )
    base::rownames(data_coords_projected) <- c("grid_1", "grid_2")

    res <-
      predict_spatial_resolution_grid_age(
        prediction_inputs = list_prediction_inputs,
        data_grid = data_grid,
        data_grid_coords_projected = data_coords_projected,
        age = 0,
        abiotic_variables = "bio1",
        x_lim = c(10, 11),
        y_lim = c(50, 51),
        cache_dir = base::tempdir(),
        spatial_mode = "spatiotemporal",
        climate_fn = climate_fn,
        spatiotemporal_interpolate_fn =
          spatiotemporal_interpolate_fn,
        predict_fn = predict_fn
      )

    testthat::expect_equal(base::nrow(res), 4L)
  }
)

testthat::test_that(
  "predict_spatial_resolution_grid_age() errors on missing row alignment",
  {
    climate_fn <- function(
        data_grid,
        age,
        abiotic_variables,
        x_lim,
        y_lim,
        cache_dir) {
      return(
        tibble::tibble(
          grid_id = c(1L, 2L),
          coord_long = c(10, 11),
          coord_lat = c(50, 51),
          bio1 = c(4, 8),
          age = age
        )
      )
    }

    list_prediction_inputs <-
      base::list(
        mod_jsdm = base::list(species = c("A", "B")),
        data_model_input = base::list(
          scale_attributes = base::list(
            age = base::list("scaled:center" = 0),
            bio1 = base::list(
              "scaled:center" = 6,
              "scaled:scale" = 2
            )
          ),
          spatial_scale_attributes = base::list(
            mev1 = base::list(
              "scaled:center" = 0,
              "scaled:scale" = 1
            )
          )
        ),
        data_coords_projected = base::data.frame(
          coord_x_km = c(0, 1),
          coord_y_km = c(0, 1)
        ),
        data_spatial_mev_core = base::data.frame(mev1 = c(0.1, 0.2))
      )

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    data_coords_projected <-
      base::data.frame(
        coord_x_km = c(0),
        coord_y_km = c(0)
      )
    base::rownames(data_coords_projected) <- c("grid_1")

    testthat::expect_error(
      predict_spatial_resolution_grid_age(
        prediction_inputs = list_prediction_inputs,
        data_grid = data_grid,
        data_grid_coords_projected = data_coords_projected,
        age = 0,
        abiotic_variables = "bio1",
        x_lim = c(10, 11),
        y_lim = c(50, 51),
        cache_dir = base::tempdir(),
        spatial_mode = "spatial",
        climate_fn = climate_fn,
        spatial_interpolate_fn = function(...) {
          base::data.frame(mev1 = c(0.1, 0.2))
        },
        predict_fn = function(...) {
          base::matrix(c(0.2, 0.8, 0.4, 0.6), nrow = 2)
        }
      ),
      regexp = "could not be aligned"
    )
  }
)

testthat::test_that(
  "predict_spatial_resolution_grid_age() errors on invalid probabilities",
  {
    climate_fn <- function(
        data_grid,
        age,
        abiotic_variables,
        x_lim,
        y_lim,
        cache_dir) {
      return(
        tibble::tibble(
          grid_id = c(1L, 2L),
          coord_long = c(10, 11),
          coord_lat = c(50, 51),
          bio1 = c(4, 8),
          age = age
        )
      )
    }

    list_prediction_inputs <-
      base::list(
        mod_jsdm = base::list(species = c("A", "B")),
        data_model_input = base::list(
          scale_attributes = base::list(
            age = base::list("scaled:center" = 0),
            bio1 = base::list(
              "scaled:center" = 6,
              "scaled:scale" = 2
            )
          )
        )
      )

    data_grid <-
      tibble::tibble(
        grid_id = c(1L, 2L),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    data_coords_projected <-
      base::data.frame(
        coord_x_km = c(0, 1),
        coord_y_km = c(0, 1)
      )
    base::rownames(data_coords_projected) <- c("grid_1", "grid_2")

    testthat::expect_error(
      predict_spatial_resolution_grid_age(
        prediction_inputs = list_prediction_inputs,
        data_grid = data_grid,
        data_grid_coords_projected = data_coords_projected,
        age = 0,
        abiotic_variables = "bio1",
        x_lim = c(10, 11),
        y_lim = c(50, 51),
        cache_dir = base::tempdir(),
        spatial_mode = "none",
        climate_fn = climate_fn,
        predict_fn = function(object, newdata, SP, type) {
          base::matrix(c(1.2, 0.5, 0.4, 0.6), nrow = 2)
        }
      ),
      regexp = "bounded"
    )
  }
)

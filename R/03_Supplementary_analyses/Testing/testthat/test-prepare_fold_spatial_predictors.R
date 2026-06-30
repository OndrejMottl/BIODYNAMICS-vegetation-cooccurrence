make_fold_spatial_test_data <- function() {
  data_coords <-
    base::data.frame(
      coord_x_km = base::c(0, 10, 20, 30, 40),
      coord_y_km = base::c(0, 5, 15, 10, 25),
      row.names = base::c("a", "b", "c", "d", "e")
    )

  data_samples <-
    tidyr::expand_grid(
      dataset_name = base::c("a", "b", "c", "d", "e"),
      age = base::c(0, 500)
    )

  res <-
    base::list(
      data_coords = data_coords,
      data_samples = data_samples
    )

  return(res)
}

make_test_spatial_compute <- function(environment_capture = NULL) {
  res <- function(data_coords_projected, n_mev) {
    if (
      !base::is.null(environment_capture)
    ) {
      environment_capture[["compute_ids"]] <-
        base::rownames(data_coords_projected)
    }

    data_mev <-
      base::data.frame(
        mev_1 = data_coords_projected[["coord_x_km"]]
      )

    base::rownames(data_mev) <-
      base::rownames(data_coords_projected)

    return(data_mev)
  }

  return(res)
}

make_test_spatial_interpolation <- function(environment_capture = NULL) {
  res <- function(
      data_coords_projected_train,
      data_mev_core,
      data_coords_projected_pred,
      spatial_scale_attributes) {
    if (
      !base::is.null(environment_capture)
    ) {
      environment_capture[["interpolation_train_ids"]] <-
        base::rownames(data_coords_projected_train)

      environment_capture[["interpolation_test_ids"]] <-
        base::rownames(data_coords_projected_pred)

      environment_capture[["scale_attributes"]] <-
        spatial_scale_attributes
    }

    data_mev <-
      base::data.frame(
        mev_1 = data_coords_projected_pred[["coord_x_km"]]
      )

    base::rownames(data_mev) <-
      base::rownames(data_coords_projected_pred)

    return(data_mev)
  }

  return(res)
}

testthat::test_that(
  "prepare_fold_spatial_predictors() excludes held-out 2-D locations",
  {
    list_data <-
      make_fold_spatial_test_data()

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    res <-
      prepare_fold_spatial_predictors(
        data_coords_projected = list_data[["data_coords"]],
        data_sample_ids = list_data[["data_samples"]],
        train_ids = base::c("a__0", "b__0", "c__0", "d__0"),
        test_ids = "e__0",
        spatial_mode = "spatial",
        n_mev = 1L,
        compute_spatial_function = make_test_spatial_compute(
          environment_capture = environment_capture
        ),
        interpolate_spatial_function = make_test_spatial_interpolation(
          environment_capture = environment_capture
        )
      )

    testthat::expect_equal(
      environment_capture[["compute_ids"]],
      base::c("a", "b", "c", "d")
    )
    testthat::expect_equal(
      environment_capture[["interpolation_train_ids"]],
      base::c("a", "b", "c", "d")
    )
    testthat::expect_equal(
      environment_capture[["interpolation_test_ids"]],
      "e__0"
    )
    testthat::expect_null(environment_capture[["scale_attributes"]])
    testthat::expect_equal(
      base::rownames(res[["data_spatial_train"]]),
      base::c("a__0", "b__0", "c__0", "d__0")
    )
    testthat::expect_equal(
      base::rownames(res[["data_spatial_test"]]),
      "e__0"
    )
  }
)

testthat::test_that(
  "prepare_fold_spatial_predictors() isolates training MEM construction",
  {
    list_data <-
      make_fold_spatial_test_data()

    data_coords_changed <-
      list_data[["data_coords"]]

    data_coords_changed["e", "coord_x_km"] <- 10000
    data_coords_changed["e", "coord_y_km"] <- -10000

    res_original <-
      prepare_fold_spatial_predictors(
        data_coords_projected = list_data[["data_coords"]],
        data_sample_ids = list_data[["data_samples"]],
        train_ids = base::c("a__0", "b__0", "c__0", "d__0"),
        test_ids = "e__0",
        spatial_mode = "spatial",
        n_mev = 1L,
        compute_spatial_function = make_test_spatial_compute(),
        interpolate_spatial_function = make_test_spatial_interpolation()
      )

    res_changed <-
      prepare_fold_spatial_predictors(
        data_coords_projected = data_coords_changed,
        data_sample_ids = list_data[["data_samples"]],
        train_ids = base::c("a__0", "b__0", "c__0", "d__0"),
        test_ids = "e__0",
        spatial_mode = "spatial",
        n_mev = 1L,
        compute_spatial_function = make_test_spatial_compute(),
        interpolate_spatial_function = make_test_spatial_interpolation()
      )

    testthat::expect_equal(
      res_original[["data_spatial_train"]],
      res_changed[["data_spatial_train"]]
    )
  }
)

testthat::test_that(
  "prepare_fold_spatial_predictors() projects every paleo sample",
  {
    list_data <-
      make_fold_spatial_test_data()

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    environment_capture[["prediction_ages"]] <-
      base::numeric()

    compute_spatiotemporal_function <- function(
        data_coords_projected,
        data_sample_ids,
        n_mev) {
      environment_capture[["compute_ids"]] <-
        base::rownames(data_coords_projected)

      environment_capture[["compute_samples"]] <-
        data_sample_ids

      vec_row_names <-
        stringr::str_c(
          dplyr::pull(data_sample_ids, dataset_name),
          "__",
          dplyr::pull(data_sample_ids, age)
        )

      data_mev <-
        base::data.frame(mev_1 = base::seq_along(vec_row_names))

      base::rownames(data_mev) <- vec_row_names

      return(data_mev)
    }

    interpolate_spatiotemporal_function <- function(
        data_st_mev_samples,
        data_coords_projected_train,
        data_coords_projected_pred,
        pred_age,
        spatial_scale_attributes) {
      environment_capture[["prediction_ages"]] <-
        base::c(environment_capture[["prediction_ages"]], pred_age)

      data_mev <-
        base::data.frame(
          mev_1 = base::rep(
            pred_age / 500,
            base::nrow(data_coords_projected_pred)
          )
        )

      base::rownames(data_mev) <-
        base::rownames(data_coords_projected_pred)

      return(data_mev)
    }

    res <-
      prepare_fold_spatial_predictors(
        data_coords_projected = list_data[["data_coords"]],
        data_sample_ids = list_data[["data_samples"]],
        train_ids = base::c(
          "a__0", "a__500", "b__0", "b__500",
          "c__0", "c__500", "d__0", "d__500"
        ),
        test_ids = base::c("e__0", "e__500"),
        spatial_mode = "spatiotemporal",
        n_mev = 1L,
        compute_spatiotemporal_function =
          compute_spatiotemporal_function,
        interpolate_spatiotemporal_function =
          interpolate_spatiotemporal_function
      )

    testthat::expect_equal(
      environment_capture[["compute_ids"]],
      base::c("a", "b", "c", "d")
    )
    testthat::expect_false(
      "e" %in% dplyr::pull(
        environment_capture[["compute_samples"]],
        dataset_name
      )
    )
    testthat::expect_equal(
      base::sort(environment_capture[["prediction_ages"]]),
      base::c(0, 500)
    )
    testthat::expect_equal(
      base::rownames(res[["data_spatial_test"]]),
      base::c("e__0", "e__500")
    )
    testthat::expect_equal(
      dplyr::pull(res[["data_spatial_test"]], mev_1),
      base::c(0, 1)
    )
  }
)

testthat::test_that(
  "prepare_fold_spatial_predictors() rejects split locations",
  {
    list_data <-
      make_fold_spatial_test_data()

    testthat::expect_error(
      prepare_fold_spatial_predictors(
        data_coords_projected = list_data[["data_coords"]],
        data_sample_ids = list_data[["data_samples"]],
        train_ids = "a__0",
        test_ids = "a__500",
        spatial_mode = "spatiotemporal",
        n_mev = 1L
      ),
      "locations must be disjoint"
    )
  }
)

testthat::test_that(
  "prepare_fold_spatial_predictors() returns finite real ST-MEVs",
  {
    data_coords <-
      base::data.frame(
        coord_x_km = base::c(100, 400, 700, 200, 600, 900),
        coord_y_km = base::c(100, 500, 900, 300, 700, 200),
        row.names = base::letters[1:6]
      )

    data_samples <-
      tidyr::expand_grid(
        dataset_name = base::letters[1:6],
        age = base::c(0, 500)
      )

    vec_train_ids <-
      stringr::str_c(
        base::rep(base::letters[1:5], each = 2),
        "__",
        base::rep(base::c(0, 500), 5)
      )

    res <-
      prepare_fold_spatial_predictors(
        data_coords_projected = data_coords,
        data_sample_ids = data_samples,
        train_ids = vec_train_ids,
        test_ids = base::c("f__0", "f__500"),
        spatial_mode = "spatiotemporal",
        n_mev = 2L
      )

    testthat::expect_equal(
      base::rownames(res[["data_spatial_test"]]),
      base::c("f__0", "f__500")
    )
    testthat::expect_true(
      base::all(
        base::is.finite(base::as.matrix(res[["data_spatial_test"]]))
      )
    )
  }
)

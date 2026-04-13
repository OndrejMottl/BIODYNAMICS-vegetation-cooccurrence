testthat::test_that("interpolate_mev_to_grid() errors if train NULL", {
  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = NULL
    ),
    regexp = "data_coords_projected_train"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors if train non-df", {
  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = "not_a_df"
    ),
    regexp = "data_coords_projected_train"
  )
})

testthat::test_that(
  "interpolate_mev_to_grid() train missing coord_x_km",
  {
    data_train_no_x <-
      base::data.frame(
        coord_y_km = 1.0,
        row.names  = "a"
      )

    testthat::expect_error(
      interpolate_mev_to_grid(
        data_coords_projected_train = data_train_no_x
      ),
      regexp = "data_coords_projected_train"
    )
  }
)

testthat::test_that(
  "interpolate_mev_to_grid() train missing coord_y_km",
  {
    data_train_no_y <-
      base::data.frame(
        coord_x_km = 1.0,
        row.names  = "a"
      )

    testthat::expect_error(
      interpolate_mev_to_grid(
        data_coords_projected_train = data_train_no_y
      ),
      regexp = "data_coords_projected_train"
    )
  }
)

testthat::test_that("interpolate_mev_to_grid() errors if mev_core NULL", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = NULL
    ),
    regexp = "data_mev_core"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors mev_core non-df", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = "not_a_df"
    ),
    regexp = "data_mev_core"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors mev_core 0 rows", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_zero_rows <-
    base::data.frame(
      mev_1 = numeric(0)
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_zero_rows
    ),
    regexp = "data_mev_core"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors mev_core 0 cols", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_zero_cols <-
    base::data.frame(
      row.names = "a"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_zero_cols
    ),
    regexp = "data_mev_core"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors if pred NULL", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_min <-
    base::data.frame(
      mev_1     = 0.5,
      row.names = "a"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_min,
      data_coords_projected_pred  = NULL
    ),
    regexp = "data_coords_projected_pred"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors pred non-df", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_min <-
    base::data.frame(
      mev_1     = 0.5,
      row.names = "a"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_min,
      data_coords_projected_pred  = "not_a_df"
    ),
    regexp = "data_coords_projected_pred"
  )
})

testthat::test_that(
  "interpolate_mev_to_grid() pred missing coord_x_km",
  {
    data_train_min <-
      base::data.frame(
        coord_x_km = 0.0,
        coord_y_km = 0.0,
        row.names  = "a"
      )

    data_mev_min <-
      base::data.frame(
        mev_1     = 0.5,
        row.names = "a"
      )

    data_pred_no_x <-
      base::data.frame(
        coord_y_km = 1.0,
        row.names  = "g"
      )

    testthat::expect_error(
      interpolate_mev_to_grid(
        data_coords_projected_train = data_train_min,
        data_mev_core               = data_mev_min,
        data_coords_projected_pred  = data_pred_no_x
      ),
      regexp = "data_coords_projected_pred"
    )
  }
)

testthat::test_that("interpolate_mev_to_grid() errors if scale NULL", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_min <-
    base::data.frame(
      mev_1     = 0.5,
      row.names = "a"
    )

  data_pred_min <-
    base::data.frame(
      coord_x_km = 1.0,
      coord_y_km = 1.0,
      row.names  = "g"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_min,
      data_coords_projected_pred  = data_pred_min,
      spatial_scale_attributes    = NULL
    ),
    regexp = "spatial_scale_attributes"
  )
})

testthat::test_that("interpolate_mev_to_grid() errors empty scale list", {
  data_train_min <-
    base::data.frame(
      coord_x_km = 0.0,
      coord_y_km = 0.0,
      row.names  = "a"
    )

  data_mev_min <-
    base::data.frame(
      mev_1     = 0.5,
      row.names = "a"
    )

  data_pred_min <-
    base::data.frame(
      coord_x_km = 1.0,
      coord_y_km = 1.0,
      row.names  = "g"
    )

  testthat::expect_error(
    interpolate_mev_to_grid(
      data_coords_projected_train = data_train_min,
      data_mev_core               = data_mev_min,
      data_coords_projected_pred  = data_pred_min,
      spatial_scale_attributes    = base::list()
    ),
    regexp = "spatial_scale_attributes"
  )
})

testthat::test_that(
  "interpolate_mev_to_grid() output correct structure",
  {
    data_coords_train <-
      base::data.frame(
        coord_x_km = c(0.0, 100.0, 200.0),
        coord_y_km = c(0.0, 100.0, 200.0),
        coord_long = c(14.0, 15.0, 16.0),
        coord_lat  = c(50.0, 51.0, 52.0),
        row.names  = c("site_a", "site_b", "site_c")
      )

    data_mev_core <-
      base::data.frame(
        mev_1     = c(0.1, 0.5, 0.9),
        mev_2     = c(0.2, 0.6, 0.8),
        row.names = c("site_a", "site_b", "site_c")
      )

    data_coords_pred <-
      base::data.frame(
        coord_x_km = c(50.0, 150.0),
        coord_y_km = c(50.0, 150.0),
        row.names  = c("grid_1", "grid_2")
      )

    list_scale_attr <-
      base::list(
        mev_1 = base::list(
          "scaled:center" = 0.0,
          "scaled:scale"  = 1.0
        ),
        mev_2 = base::list(
          "scaled:center" = 0.0,
          "scaled:scale"  = 1.0
        )
      )

    res <-
      interpolate_mev_to_grid(
        data_coords_projected_train = data_coords_train,
        data_mev_core               = data_mev_core,
        data_coords_projected_pred  = data_coords_pred,
        spatial_scale_attributes    = list_scale_attr
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )

    testthat::expect_equal(
      base::nrow(res),
      2L
    )

    testthat::expect_equal(
      base::names(res),
      base::names(data_mev_core)
    )

    testthat::expect_equal(
      base::rownames(res),
      c("grid_1", "grid_2")
    )

    testthat::expect_true(
      base::all(
        base::is.finite(
          base::as.matrix(res)
        )
      )
    )
  }
)

testthat::test_that(
  "interpolate_mev_to_grid() IDW recovers exact site",
  {
    data_coords_train <-
      base::data.frame(
        coord_x_km = c(0.0, 100.0, 200.0),
        coord_y_km = c(0.0, 100.0, 200.0),
        coord_long = c(14.0, 15.0, 16.0),
        coord_lat  = c(50.0, 51.0, 52.0),
        row.names  = c("site_a", "site_b", "site_c")
      )

    data_mev_core <-
      base::data.frame(
        mev_1     = c(0.1, 0.5, 0.9),
        mev_2     = c(0.2, 0.6, 0.8),
        row.names = c("site_a", "site_b", "site_c")
      )

    # Prediction at exact training-site coordinates (site_a)
    data_coords_pred_exact <-
      base::data.frame(
        coord_x_km = 0.0,
        coord_y_km = 0.0,
        row.names  = "exact_a"
      )

    list_scale_attr <-
      base::list(
        mev_1 = base::list(
          "scaled:center" = 0.0,
          "scaled:scale"  = 1.0
        ),
        mev_2 = base::list(
          "scaled:center" = 0.0,
          "scaled:scale"  = 1.0
        )
      )

    res_exact <-
      interpolate_mev_to_grid(
        data_coords_projected_train = data_coords_train,
        data_mev_core               = data_mev_core,
        data_coords_projected_pred  = data_coords_pred_exact,
        spatial_scale_attributes    = list_scale_attr
      )

    # With IDW power=2 and epsilon=1e-10, the weight at
    # distance=0 dominates (~1e10) vs remote sites (~5e-5),
    # so the interpolated value should match site_a exactly
    # within tolerance.
    testthat::expect_equal(
      dplyr::pull(res_exact, mev_1),
      0.1,
      tolerance = 1e-4
    )

    testthat::expect_equal(
      dplyr::pull(res_exact, mev_2),
      0.2,
      tolerance = 1e-4
    )
  }
)

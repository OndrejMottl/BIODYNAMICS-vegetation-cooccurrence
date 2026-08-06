testthat::test_that(
  "project_spatial_mev_basis() chunks fast Nyström projection",
  {
    data_pred <-
      base::data.frame(
        coord_x_km = base::seq_len(5L),
        coord_y_km = base::seq_len(5L) * 10,
        row.names = stringr::str_c("pred_", base::seq_len(5L))
      )

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    environment_capture[["chunk_sizes"]] <- base::integer()

    fast_projection_function <- function(meig, coords0) {
      environment_capture[["chunk_sizes"]] <-
        base::c(
          environment_capture[["chunk_sizes"]],
          base::nrow(coords0)
        )

      mat_sf <-
        base::cbind(
          coords0[, 1],
          coords0[, 2],
          coords0[, 1] + coords0[, 2]
        )

      return(base::list(sf = mat_sf))
    }

    list_basis <-
      base::list(
        data_mev = base::data.frame(
          mev_1 = base::numeric(),
          mev_2 = base::numeric()
        ),
        projection_basis = base::list(
          method = "spmoran_nystrom",
          spmoran_basis = base::list(test = TRUE),
          column_indices = base::c(1L, 2L),
          column_signs = base::c(-1, 1)
        )
      )

    res <-
      project_spatial_mev_basis(
        list_spatial_mev_basis = list_basis,
        data_coords_projected_pred = data_pred,
        projection_chunk_size = 2L,
        fast_projection_function = fast_projection_function
      )

    testthat::expect_identical(
      environment_capture[["chunk_sizes"]],
      base::c(2L, 2L, 1L)
    )
    testthat::expect_equal(res[["mev_1"]], -data_pred[["coord_x_km"]])
    testthat::expect_equal(res[["mev_2"]], data_pred[["coord_y_km"]])
    testthat::expect_identical(
      base::rownames(res),
      base::rownames(data_pred)
    )
  }
)

testthat::test_that(
  "project_spatial_mev_basis() retains exact IDW compatibility",
  {
    data_train <-
      base::data.frame(
        coord_x_km = base::c(0, 10),
        coord_y_km = base::c(0, 10),
        row.names = base::c("a", "b")
      )

    data_mev <-
      base::data.frame(
        mev_1 = base::c(1, 2),
        row.names = base::c("a", "b")
      )

    data_pred <-
      base::data.frame(
        coord_x_km = 5,
        coord_y_km = 5,
        row.names = "pred_1"
      )

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    exact_projection_function <- function(
        data_coords_projected_train,
        data_mev_core,
        data_coords_projected_pred,
        spatial_scale_attributes,
        chunk_size) {
      environment_capture[["chunk_size"]] <- chunk_size

      res <-
        base::data.frame(
          mev_1 = 1.5,
          row.names = base::rownames(data_coords_projected_pred)
        )

      return(res)
    }

    list_basis <-
      base::list(
        data_mev = data_mev,
        projection_basis = NULL
      )

    res <-
      project_spatial_mev_basis(
        list_spatial_mev_basis = list_basis,
        data_coords_projected_train = data_train,
        data_coords_projected_pred = data_pred,
        projection_chunk_size = 64L,
        exact_projection_function = exact_projection_function
      )

    testthat::expect_equal(res[["mev_1"]], 1.5)
    testthat::expect_identical(environment_capture[["chunk_size"]], 64L)
  }
)

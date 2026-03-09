#' @title Interpolate 2-D Spatial MEVs to Prediction Grid
#' @description
#' Uses Inverse Distance Weighting (IDW, power = 2) to
#' approximate Moran Eigenvector Map (MEM) values from
#' training-site locations to arbitrary prediction locations,
#' then scales the result using training spatial scale
#' attributes so that the interpolated predictors are on the
#' same scale as those seen during model fitting.
#' @param data_coords_projected_train
#' A data frame with `coord_x_km` and `coord_y_km` columns
#' and `dataset_name` as row names, as returned by
#' `project_coords_to_metric()`. One row per unique training
#' site.
#' @param data_mev_core
#' A data frame with unscaled MEV columns (`mev_1`, `mev_2`,
#' …) and `dataset_name` as row names, as returned by
#' `compute_spatial_mev()`.
#' @param data_coords_projected_pred
#' A data frame with `coord_x_km` and `coord_y_km` columns
#' and arbitrary row names identifying prediction locations
#' (e.g. `"grid_1"`, `"grid_2"`), as returned by
#' `project_coords_to_metric()`.
#' @param spatial_scale_attributes
#' A named list of `"scaled:center"` and `"scaled:scale"`
#' attributes per MEV column, as returned by
#' `scale_spatial_for_fit()` in the `spatial_scale_attributes`
#' element. Used to bring interpolated MEV values onto the
#' same scale as the training spatial predictors.
#' @return
#' A data frame with the same row names as
#' `data_coords_projected_pred` and one column per MEV
#' (names matching `data_mev_core`). All columns are scaled
#' to match the training MEV distribution.
#' @details
#' MEMs are eigenvectors of the spatial connectivity matrix
#' at training sites and cannot be analytically evaluated at
#' new locations. IDW (power = 2) with a small epsilon
#' (1e-10) to prevent division-by-zero provides a smooth
#' spatial interpolation.
#'
#' This function handles the **2-D spatial case** only
#' (x_km, y_km). For models fitted with
#' `spatial_mode = "spatiotemporal"` use
#' `interpolate_st_mev_to_grid()` instead.
#' @seealso
#'   [compute_spatial_mev()],
#'   [interpolate_st_mev_to_grid()],
#'   [project_coords_to_metric()],
#'   [scale_spatial_for_fit()]
#' @export
interpolate_mev_to_grid <- function(
    data_coords_projected_train = NULL,
    data_mev_core = NULL,
    data_coords_projected_pred = NULL,
    spatial_scale_attributes = NULL) {
  assertthat::assert_that(
    is.data.frame(data_coords_projected_train),
    all(
      c("coord_x_km", "coord_y_km") %in%
        base::names(data_coords_projected_train)
    ),
    msg = paste0(
      "data_coords_projected_train must be a data frame",
      " with columns 'coord_x_km' and 'coord_y_km'"
    )
  )

  assertthat::assert_that(
    is.data.frame(data_mev_core),
    nrow(data_mev_core) > 0,
    ncol(data_mev_core) > 0,
    msg = "data_mev_core must be a non-empty data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_coords_projected_pred),
    all(
      c("coord_x_km", "coord_y_km") %in%
        base::names(data_coords_projected_pred)
    ),
    msg = paste0(
      "data_coords_projected_pred must be a data frame",
      " with columns 'coord_x_km' and 'coord_y_km'"
    )
  )

  assertthat::assert_that(
    is.list(spatial_scale_attributes),
    length(spatial_scale_attributes) > 0,
    msg = "spatial_scale_attributes must be a non-empty list"
  )

  # 1. Combine training km coords and unscaled MEV values -----
  vec_mev_cols <-
    base::names(data_mev_core)

  data_train_mev_coords <-
    data_coords_projected_train |>
    tibble::rownames_to_column("dataset_name") |>
    dplyr::inner_join(
      data_mev_core |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by(dataset_name)
    )

  # 2. Build km coordinate matrices -----
  mat_xy_train_km <-
    data_train_mev_coords |>
    dplyr::select(coord_x_km, coord_y_km) |>
    base::as.matrix()

  mat_xy_pred_km <-
    data_coords_projected_pred |>
    dplyr::select(coord_x_km, coord_y_km) |>
    base::as.matrix()

  # 3. 2-D Euclidean distances (rows = pred, cols = train) -----
  mat_dist_km <-
    base::sqrt(
      base::outer(
        mat_xy_pred_km[, 1], mat_xy_train_km[, 1], `-`
      )^2 +
        base::outer(
          mat_xy_pred_km[, 2], mat_xy_train_km[, 2], `-`
        )^2
    )

  # 4. IDW weights (power = 2, epsilon avoids div-by-zero) -----
  mat_idw_weights <-
    1 / (mat_dist_km^2 + 1e-10)

  mat_idw_weights <-
    mat_idw_weights / base::rowSums(mat_idw_weights)

  # 5. Interpolate unscaled MEV values -----
  mat_train_mev <-
    data_train_mev_coords |>
    dplyr::select(dplyr::all_of(vec_mev_cols)) |>
    base::as.matrix()

  data_pred_mev_raw <-
    base::as.data.frame(mat_idw_weights %*% mat_train_mev)

  base::colnames(data_pred_mev_raw) <- vec_mev_cols
  base::rownames(data_pred_mev_raw) <-
    base::rownames(data_coords_projected_pred)

  # 6. Scale using training spatial scale attributes -----
  data_pred_mev_scaled <-
    data_pred_mev_raw |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = ~ {
          col_nm <- dplyr::cur_column()
          center <- base::as.numeric(
            spatial_scale_attributes[[col_nm]][["scaled:center"]]
          )
          sc <- base::as.numeric(
            spatial_scale_attributes[[col_nm]][["scaled:scale"]]
          )
          (.x - center) / sc
        }
      )
    )

  return(data_pred_mev_scaled)
}

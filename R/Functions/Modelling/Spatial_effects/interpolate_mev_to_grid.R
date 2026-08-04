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
#' ...) and `dataset_name` as row names, as returned by
#' `compute_spatial_mev()`.
#' @param data_coords_projected_pred
#' A data frame with `coord_x_km` and `coord_y_km` columns
#' and arbitrary row names identifying prediction locations
#' (e.g. `"grid_1"`, `"grid_2"`), as returned by
#' `project_coords_to_metric()`.
#' @param spatial_scale_attributes
#' Optional named list of `"scaled:center"` and `"scaled:scale"`
#' attributes per MEV column, as returned by
#' `scale_spatial_for_fit()` in the `spatial_scale_attributes`
#' element. Used to bring interpolated MEV values onto the
#' same scale as the training spatial predictors. When `NULL`,
#' unscaled interpolated values are returned for fold-local scaling.
#' @param chunk_size
#' Positive integer limiting the number of prediction locations included in
#' one distance matrix. Default is `5000L`.
#' @return
#' A data frame with the same row names as
#' `data_coords_projected_pred` and one column per MEV
#' (names matching `data_mev_core`). Columns are scaled when
#' `spatial_scale_attributes` is supplied and otherwise remain unscaled.
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
    spatial_scale_attributes = NULL,
    chunk_size = 5000L) {
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
    base::is.null(spatial_scale_attributes) ||
      (
        base::is.list(spatial_scale_attributes) &&
          base::length(spatial_scale_attributes) > 0L
      ),
    msg = "spatial_scale_attributes must be NULL or a non-empty list"
  )

  assertthat::assert_that(
    base::is.numeric(chunk_size),
    base::length(chunk_size) == 1L,
    base::is.finite(chunk_size),
    chunk_size >= 1,
    chunk_size == base::as.integer(chunk_size),
    msg = "`chunk_size` must be one finite positive integer."
  )

  chunk_size_integer <-
    base::as.integer(chunk_size)

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

  # 3. Prepare training MEV values -----
  mat_train_mev <-
    data_train_mev_coords |>
    dplyr::select(dplyr::all_of(vec_mev_cols)) |>
    base::as.matrix()

  # 4. Interpolate prediction chunks with bounded distance matrices -----
  vec_pred_rows <-
    base::seq_len(base::nrow(mat_xy_pred_km))

  vec_chunk_ids <-
    base::ceiling(vec_pred_rows / chunk_size_integer)

  list_pred_mev_chunks <-
    base::unique(vec_chunk_ids) |>
    purrr::map(
      .f = ~ {
        vec_selected_rows <-
          vec_pred_rows[vec_chunk_ids == .x]

        mat_xy_pred_chunk <-
          mat_xy_pred_km[
            vec_selected_rows,
            ,
            drop = FALSE
          ]

        mat_dist_km <-
          base::sqrt(
            base::outer(
              mat_xy_pred_chunk[, 1],
              mat_xy_train_km[, 1],
              `-`
            )^2 +
              base::outer(
                mat_xy_pred_chunk[, 2],
                mat_xy_train_km[, 2],
                `-`
              )^2
          )

        mat_idw_weights <-
          1 / (mat_dist_km^2 + 1e-10)

        mat_idw_weights_normalized <-
          mat_idw_weights / base::rowSums(mat_idw_weights)

        res_chunk <-
          mat_idw_weights_normalized %*% mat_train_mev

        return(res_chunk)
      }
    )

  mat_pred_mev_raw <-
    list_pred_mev_chunks |>
    purrr::reduce(.f = base::rbind)

  data_pred_mev_raw <-
    base::as.data.frame(mat_pred_mev_raw)

  base::colnames(data_pred_mev_raw) <- vec_mev_cols
  base::rownames(data_pred_mev_raw) <-
    base::rownames(data_coords_projected_pred)

  # 5. Scale using training spatial scale attributes -----
  res <-
    if (
      base::is.null(spatial_scale_attributes)
    ) {
      data_pred_mev_raw
    } else {
      scale_predictors_with_training_attributes(
        data_predictors = data_pred_mev_raw,
        scale_attributes = spatial_scale_attributes
      )
    }

  return(res)
}

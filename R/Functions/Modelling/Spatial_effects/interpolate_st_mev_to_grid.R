#' @title Interpolate 3-D Spatiotemporal MEVs to Prediction Grid
#' @description
#' Uses Inverse Distance Weighting (IDW, power = 2) in a
#' z-scored 3-D space `(x_km, y_km, age_kyr)` to approximate
#' spatiotemporal Moran Eigenvector Map (MEM) values from
#' training samples to prediction locations at a given age.
#' The interpolated values are then scaled using the training
#' spatial scale attributes.
#' @param data_st_mev_samples
#' A data frame with row names in the format
#' `"<dataset_name>__<age>"` and unscaled spatiotemporal MEV
#' columns (`mev_1`, …), as returned by
#' `compute_spatiotemporal_mev()`.
#' @param data_coords_projected_train
#' A data frame with `coord_x_km` and `coord_y_km` columns
#' and `dataset_name` as row names (site level), as returned
#' by `project_coords_to_metric()`.
#' @param data_coords_projected_pred
#' A data frame with `coord_x_km` and `coord_y_km` columns
#' and arbitrary row names identifying prediction locations,
#' as returned by `project_coords_to_metric()`.
#' @param pred_age
#' Numeric or integer scalar. Age in years BP at which
#' predictions are made. Used as the temporal dimension of
#' the prediction 3-D coordinate matrix (`age_kyr =
#' pred_age / 1000`).
#' @param spatial_scale_attributes
#' A named list of `"scaled:center"` and `"scaled:scale"`
#' attributes per ST-MEV column, as returned by
#' `scale_spatial_for_fit()` in the `spatial_scale_attributes`
#' element.
#' @return
#' A data frame with the same row names as
#' `data_coords_projected_pred` and one column per ST-MEV
#' (names matching `data_st_mev_samples`). All columns are
#' scaled to match the training ST-MEV distribution.
#' @details
#' 3-D coordinates `(x_km, y_km, age_kyr)` of the training
#' samples are z-scored using `colMeans` and column-wise
#' standard deviations before computing Euclidean distances.
#' This ensures the spatial and temporal extents contribute
#' equally. The same z-score parameters are applied to the
#' prediction grid coordinates, fixing the temporal dimension
#' at `pred_age / 1000`.
#'
#' This function handles the **3-D spatiotemporal case**.
#' For models fitted with `spatial_mode = "spatial"` use
#' `interpolate_mev_to_grid()` instead.
#' @seealso
#'   [compute_spatiotemporal_mev()],
#'   [interpolate_mev_to_grid()],
#'   [project_coords_to_metric()],
#'   [scale_spatial_for_fit()]
#' @export
interpolate_st_mev_to_grid <- function(
    data_st_mev_samples = NULL,
    data_coords_projected_train = NULL,
    data_coords_projected_pred = NULL,
    pred_age = NULL,
    spatial_scale_attributes = NULL) {
  assertthat::assert_that(
    is.data.frame(data_st_mev_samples),
    nrow(data_st_mev_samples) > 0,
    msg = "data_st_mev_samples must be a non-empty data frame"
  )

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
    (is.numeric(pred_age) || is.integer(pred_age)) &&
      length(pred_age) == 1L,
    msg = "pred_age must be a single numeric or integer value"
  )

  assertthat::assert_that(
    is.list(spatial_scale_attributes),
    length(spatial_scale_attributes) > 0,
    msg = "spatial_scale_attributes must be a non-empty list"
  )

  # 1. ST-MEV column names -----
  vec_st_mev_cols <-
    base::names(data_st_mev_samples)

  # 2. Reconstruct training 3-D raw matrix -----
  # Row names follow "dataset_name__age" format.
  data_train_3d_raw <-
    tibble::tibble(
      sample_id = base::rownames(data_st_mev_samples)
    ) |>
    tidyr::separate(
      col = sample_id,
      into = c("dataset_name", "age_chr"),
      sep = "__",
      extra = "merge"
    ) |>
    dplyr::mutate(age = base::as.integer(age_chr)) |>
    dplyr::select(-age_chr) |>
    dplyr::inner_join(
      data_coords_projected_train |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::mutate(age_kyr = age / 1000)

  mat_3d_train_raw <-
    data_train_3d_raw |>
    dplyr::select(coord_x_km, coord_y_km, age_kyr) |>
    base::as.matrix()

  # 3. Z-score parameters from training samples -----
  # Z-scoring ensures spatial and temporal extents
  #   contribute equally to the Euclidean distance.
  vec_3d_center <-
    base::colMeans(mat_3d_train_raw)

  vec_3d_scale <-
    base::apply(mat_3d_train_raw, 2, stats::sd)

  mat_3d_train_z <-
    base::scale(
      mat_3d_train_raw,
      center = vec_3d_center,
      scale = vec_3d_scale
    )

  # 4. Prediction 3-D matrix: grid coords + pred_age -----
  mat_3d_pred_raw <-
    data_coords_projected_pred |>
    dplyr::select(coord_x_km, coord_y_km) |>
    dplyr::mutate(age_kyr = pred_age / 1000) |>
    base::as.matrix()

  # Apply same z-score params as training data -----
  mat_3d_pred_z <-
    base::scale(
      mat_3d_pred_raw,
      center = vec_3d_center,
      scale = vec_3d_scale
    )

  # 5. 3-D Euclidean distances (rows = pred, cols = train) -----
  mat_dist_3d <-
    base::sqrt(
      base::outer(
        mat_3d_pred_z[, 1], mat_3d_train_z[, 1], `-`
      )^2 +
        base::outer(
          mat_3d_pred_z[, 2], mat_3d_train_z[, 2], `-`
        )^2 +
        base::outer(
          mat_3d_pred_z[, 3], mat_3d_train_z[, 3], `-`
        )^2
    )

  # 6. IDW weights (power = 2, epsilon avoids div-by-zero) -----
  mat_idw_weights_3d <-
    1 / (mat_dist_3d^2 + 1e-10)

  mat_idw_weights_3d <-
    mat_idw_weights_3d / base::rowSums(mat_idw_weights_3d)

  # 7. Interpolate unscaled ST-MEV values -----
  mat_train_st_mev <-
    data_st_mev_samples |>
    dplyr::select(dplyr::all_of(vec_st_mev_cols)) |>
    base::as.matrix()

  data_pred_st_mev_raw <-
    base::as.data.frame(
      mat_idw_weights_3d %*% mat_train_st_mev
    )

  base::colnames(data_pred_st_mev_raw) <- vec_st_mev_cols
  base::rownames(data_pred_st_mev_raw) <-
    base::rownames(data_coords_projected_pred)

  # 8. Scale using training spatial scale attributes -----
  data_pred_st_mev_scaled <-
    data_pred_st_mev_raw |>
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

  return(data_pred_st_mev_scaled)
}

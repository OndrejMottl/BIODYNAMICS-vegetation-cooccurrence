#' @title Project a Reusable Spatial MEM Basis
#' @description
#' Projects exact or fast training MEMs to held-out locations with the
#' matching construction method.
#' @param list_spatial_mev_basis
#' List returned by [compute_spatial_mev_basis()].
#' @param data_coords_projected_pred
#' Projected coordinates for prediction locations.
#' @param data_coords_projected_train
#' Training coordinates required for exact IDW compatibility.
#' @param spatial_scale_attributes
#' Optional training scale attributes passed to [apply_scale_attributes()].
#' @param projection_chunk_size
#' Positive integer limiting prediction rows processed in one operation.
#' @param exact_projection_function
#' Exact-basis projection function. Defaults to [interpolate_mev_to_grid()].
#' @param fast_projection_function
#' Fast-basis projection function. Defaults to [spmoran::meigen0()].
#' @return
#' Data frame of projected `mev_*` columns in prediction-row order.
#' @export
project_spatial_mev_basis <- function(
    list_spatial_mev_basis = NULL,
    data_coords_projected_pred = NULL,
    data_coords_projected_train = NULL,
    spatial_scale_attributes = NULL,
    projection_chunk_size = 5000L,
    exact_projection_function = interpolate_mev_to_grid,
    fast_projection_function = spmoran::meigen0) {
  assertthat::assert_that(
    base::is.list(list_spatial_mev_basis),
    base::is.data.frame(list_spatial_mev_basis[["data_mev"]]),
    msg = "`list_spatial_mev_basis` must contain a `data_mev` data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_coords_projected_pred),
    base::all(
      base::c("coord_x_km", "coord_y_km") %in%
        base::colnames(data_coords_projected_pred)
    ),
    base::nrow(data_coords_projected_pred) > 0L,
    msg = "Prediction coordinates must be a non-empty projected data frame."
  )

  assertthat::assert_that(
    base::is.numeric(projection_chunk_size),
    base::length(projection_chunk_size) == 1L,
    base::is.finite(projection_chunk_size),
    projection_chunk_size >= 1,
    projection_chunk_size == base::as.integer(projection_chunk_size),
    msg = "`projection_chunk_size` must be one positive integer."
  )

  assertthat::assert_that(
    base::is.function(exact_projection_function),
    base::is.function(fast_projection_function),
    msg = "Exact and fast projection arguments must be functions."
  )

  mat_pred_coords <-
    data_coords_projected_pred |>
    dplyr::select("coord_x_km", "coord_y_km") |>
    base::as.matrix()

  assertthat::assert_that(
    base::all(base::is.finite(mat_pred_coords)),
    msg = "Prediction coordinates must contain only finite numbers."
  )

  projection_chunk_size_integer <-
    base::as.integer(projection_chunk_size)

  list_projection_basis <-
    list_spatial_mev_basis[["projection_basis"]]

  if (
    base::is.null(list_projection_basis)
  ) {
    assertthat::assert_that(
      base::is.data.frame(data_coords_projected_train),
      msg = "Exact MEM projection requires training coordinates."
    )

    res_raw <-
      exact_projection_function(
        data_coords_projected_train = data_coords_projected_train,
        data_mev_core = list_spatial_mev_basis[["data_mev"]],
        data_coords_projected_pred = data_coords_projected_pred,
        spatial_scale_attributes = spatial_scale_attributes,
        chunk_size = projection_chunk_size_integer
      )

    return(res_raw)
  }

  vec_column_indices <-
    list_projection_basis[["column_indices"]]

  vec_column_signs <-
    list_projection_basis[["column_signs"]]

  assertthat::assert_that(
    base::is.numeric(vec_column_indices),
    base::is.numeric(vec_column_signs),
    base::length(vec_column_indices) == base::length(vec_column_signs),
    msg = "Fast projection basis columns and signs must align."
  )

  vec_row_indices <-
    base::seq_len(base::nrow(data_coords_projected_pred))

  vec_chunk_ids <-
    base::ceiling(vec_row_indices / projection_chunk_size_integer)

  list_projected_chunks <-
    base::unique(vec_chunk_ids) |>
    purrr::map(
      .f = ~ {
        vec_selected_rows <-
          vec_row_indices[vec_chunk_ids == .x]

        list_projected <-
          fast_projection_function(
            meig = list_projection_basis[["spmoran_basis"]],
            coords0 = mat_pred_coords[
              vec_selected_rows,
              ,
              drop = FALSE
            ]
          )

        mat_projected_all <-
          list_projected[["sf"]] |>
          base::as.matrix()

        assertthat::assert_that(
          base::nrow(mat_projected_all) ==
            base::length(vec_selected_rows),
          base::ncol(mat_projected_all) >=
            base::max(vec_column_indices),
          msg = "Fast projection returned an incompatible MEM matrix."
        )

        mat_projected_selected <-
          mat_projected_all[
            ,
            vec_column_indices,
            drop = FALSE
          ]

        mat_signs <-
          base::matrix(
            vec_column_signs,
            nrow = base::nrow(mat_projected_selected),
            ncol = base::length(vec_column_signs),
            byrow = TRUE
          )

        res_chunk <-
          mat_projected_selected * mat_signs

        return(res_chunk)
      }
    )

  mat_projected <-
    list_projected_chunks |>
    purrr::reduce(.f = base::rbind)

  data_projected_raw <-
    base::as.data.frame(mat_projected)

  base::colnames(data_projected_raw) <-
    base::colnames(list_spatial_mev_basis[["data_mev"]])

  base::rownames(data_projected_raw) <-
    base::rownames(data_coords_projected_pred)

  res <-
    if (
      base::is.null(spatial_scale_attributes)
    ) {
      data_projected_raw
    } else {
      apply_scale_attributes(
        data_predictors = data_projected_raw,
        scale_attributes = spatial_scale_attributes
      )
    }

  return(res)
}


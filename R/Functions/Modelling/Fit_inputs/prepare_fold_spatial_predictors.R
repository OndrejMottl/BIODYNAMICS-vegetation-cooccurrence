#' @title Prepare Fold-Local Spatial Predictors
#' @description
#' Computes Moran eigenvector predictors from training locations or samples
#' only and projects them to held-out samples with the production IDW path.
#' @param data_coords_projected
#' Data frame with site row names and `coord_x_km` and `coord_y_km` columns.
#' @param data_sample_ids
#' Data frame containing `dataset_name` and `age` for all candidate samples.
#' @param train_ids,test_ids
#' Disjoint sample identifiers in `"dataset_name__age"` format. Locations
#' represented by the two partitions must also be disjoint.
#' @param spatial_mode
#' Character scalar. Supported values are `"spatial"` and
#' `"spatiotemporal"`.
#' @param n_mev
#' Positive integer giving the requested number of Moran eigenvectors.
#' @param compute_spatial_function,compute_spatiotemporal_function
#' Functions used to compute 2-D and spatiotemporal Moran eigenvectors.
#' @param interpolate_spatial_function,interpolate_spatiotemporal_function
#' Functions used to project training Moran eigenvectors to held-out samples.
#' @return
#' Named list with unscaled training and held-out spatial predictor data
#' frames plus fold-level spatial diagnostics.
#' @examples
#' \dontrun{
#' list_spatial_fold <-
#'   prepare_fold_spatial_predictors(
#'     data_coords_projected = data_coords,
#'     data_sample_ids = data_samples,
#'     train_ids = vec_train_ids,
#'     test_ids = vec_test_ids,
#'     spatial_mode = "spatial",
#'     n_mev = 3L
#'   )
#' }
#' @export
prepare_fold_spatial_predictors <- function(
    data_coords_projected = NULL,
    data_sample_ids = NULL,
    train_ids = NULL,
    test_ids = NULL,
    spatial_mode = NULL,
    n_mev = NULL,
    compute_spatial_function = compute_spatial_mev,
    compute_spatiotemporal_function = compute_spatiotemporal_mev,
    interpolate_spatial_function = interpolate_mev_to_grid,
    interpolate_spatiotemporal_function = interpolate_st_mev_to_grid) {
  assertthat::assert_that(
    base::is.data.frame(data_coords_projected),
    base::all(
      base::c("coord_x_km", "coord_y_km") %in%
        base::colnames(data_coords_projected)
    ),
    msg = "`data_coords_projected` must contain projected coordinates."
  )

  assertthat::assert_that(
    !base::is.null(base::rownames(data_coords_projected)),
    !base::anyDuplicated(base::rownames(data_coords_projected)),
    msg = "`data_coords_projected` must have unique site row names."
  )

  assertthat::assert_that(
    base::is.data.frame(data_sample_ids),
    base::all(
      base::c("dataset_name", "age") %in% base::colnames(data_sample_ids)
    ),
    msg = "`data_sample_ids` must contain `dataset_name` and `age`."
  )

  assertthat::assert_that(
    base::is.character(train_ids),
    base::length(train_ids) > 0L,
    !base::anyDuplicated(train_ids),
    msg = "`train_ids` must be a non-empty unique character vector."
  )

  assertthat::assert_that(
    base::is.character(test_ids),
    base::length(test_ids) > 0L,
    !base::anyDuplicated(test_ids),
    msg = "`test_ids` must be a non-empty unique character vector."
  )

  assertthat::assert_that(
    base::length(base::intersect(train_ids, test_ids)) == 0L,
    msg = "`train_ids` and `test_ids` must be disjoint."
  )

  assertthat::assert_that(
    base::is.character(spatial_mode),
    base::length(spatial_mode) == 1L,
    spatial_mode %in% base::c("spatial", "spatiotemporal"),
    msg = "`spatial_mode` must be 'spatial' or 'spatiotemporal'."
  )

  assertthat::assert_that(
    base::is.numeric(n_mev),
    base::length(n_mev) == 1L,
    base::is.finite(n_mev),
    n_mev >= 1,
    n_mev == base::as.integer(n_mev),
    msg = "`n_mev` must be one finite positive integer."
  )

  list_functions <-
    base::list(
      compute_spatial_function,
      compute_spatiotemporal_function,
      interpolate_spatial_function,
      interpolate_spatiotemporal_function
    )

  assertthat::assert_that(
    base::all(purrr::map_lgl(list_functions, base::is.function)),
    msg = "All compute and interpolation arguments must be functions."
  )

  data_samples_identified <-
    data_sample_ids |>
    dplyr::mutate(
      .row_name = stringr::str_c(
        .data[["dataset_name"]],
        "__",
        .data[["age"]]
      )
    )

  vec_sample_ids <-
    dplyr::pull(data_samples_identified, .row_name)

  if (
    base::anyDuplicated(vec_sample_ids)
  ) {
    cli::cli_abort("Sample identifiers must be unique.")
  }

  vec_partition_ids <-
    base::c(train_ids, test_ids)

  if (
    !base::all(vec_partition_ids %in% vec_sample_ids)
  ) {
    cli::cli_abort("Every fold sample must occur in `data_sample_ids`.")
  }

  make_sample_partition <- function(vec_ids) {
    res_partition <-
      data_samples_identified |>
      dplyr::filter(.data[[".row_name"]] %in% .env[["vec_ids"]]) |>
      dplyr::mutate(
        .fold_order = base::match(
          .data[[".row_name"]],
          .env[["vec_ids"]]
        )
      ) |>
      dplyr::arrange(.data[[".fold_order"]]) |>
      dplyr::select(-".fold_order")

    return(res_partition)
  }

  data_samples_train_identified <-
    make_sample_partition(vec_ids = train_ids)

  data_samples_test_identified <-
    make_sample_partition(vec_ids = test_ids)

  vec_train_locations <-
    data_samples_train_identified |>
    dplyr::pull(dataset_name) |>
    base::unique()

  vec_test_locations <-
    data_samples_test_identified |>
    dplyr::pull(dataset_name) |>
    base::unique()

  if (
    base::length(
      base::intersect(vec_train_locations, vec_test_locations)
    ) > 0L
  ) {
    cli::cli_abort("Training and test locations must be disjoint.")
  }

  vec_coordinate_ids <-
    base::rownames(data_coords_projected)

  if (
    !base::all(
      base::c(vec_train_locations, vec_test_locations) %in%
        vec_coordinate_ids
    )
  ) {
    cli::cli_abort("Every fold location must have projected coordinates.")
  }

  data_coords_train <-
    data_coords_projected[
      vec_train_locations,
      ,
      drop = FALSE
    ]

  data_coords_with_ids <-
    data_coords_projected |>
    tibble::rownames_to_column("dataset_name")

  list_spatial_raw <-
    if (
      spatial_mode == "spatial"
    ) {
      data_mev_core <-
        compute_spatial_function(
          data_coords_projected = data_coords_train,
          n_mev = n_mev
        )

      data_train_raw_unordered <-
        prepare_spatial_predictors_for_fit(
          data_spatial = data_mev_core,
          data_sample_ids = data_samples_train_identified |>
            dplyr::select("dataset_name", "age")
        )

      data_test_coords <-
        data_samples_test_identified |>
        dplyr::inner_join(
          data_coords_with_ids,
          by = dplyr::join_by(dataset_name),
          unmatched = base::c("error", "drop")
        ) |>
        dplyr::select(".row_name", "coord_x_km", "coord_y_km") |>
        tibble::column_to_rownames(".row_name")

      data_test_raw_unordered <-
        interpolate_spatial_function(
          data_coords_projected_train = data_coords_train,
          data_mev_core = data_mev_core,
          data_coords_projected_pred = data_test_coords,
          spatial_scale_attributes = NULL
        )

      base::list(
        train = data_train_raw_unordered,
        test = data_test_raw_unordered
      )
    } else {
      data_samples_train <-
        data_samples_train_identified |>
        dplyr::select("dataset_name", "age")

      data_train_raw_unordered <-
        compute_spatiotemporal_function(
          data_coords_projected = data_coords_train,
          data_sample_ids = data_samples_train,
          n_mev = n_mev
        )

      vec_test_ages <-
        data_samples_test_identified |>
        dplyr::pull(age) |>
        base::unique()

      list_test_by_age <-
        vec_test_ages |>
        purrr::map(
          .f = ~ {
            selected_age <-
              .x

            data_samples_test_age <-
              data_samples_test_identified |>
              dplyr::filter(.data[["age"]] == .env[["selected_age"]])

            data_test_coords_age <-
              data_samples_test_age |>
              dplyr::inner_join(
                data_coords_with_ids,
                by = dplyr::join_by(dataset_name),
                unmatched = base::c("error", "drop")
              ) |>
              dplyr::select(
                ".row_name",
                "coord_x_km",
                "coord_y_km"
              ) |>
              tibble::column_to_rownames(".row_name")

            res_age <-
              interpolate_spatiotemporal_function(
                data_st_mev_samples = data_train_raw_unordered,
                data_coords_projected_train = data_coords_train,
                data_coords_projected_pred = data_test_coords_age,
                pred_age = selected_age,
                spatial_scale_attributes = NULL
              )

            return(res_age)
          }
        )

      data_test_raw_unordered <-
        list_test_by_age |>
        purrr::reduce(.f = base::rbind)

      base::list(
        train = data_train_raw_unordered,
        test = data_test_raw_unordered
      )
    }

  data_spatial_train_unordered <-
    list_spatial_raw |>
    purrr::chuck("train")

  data_spatial_test_unordered <-
    list_spatial_raw |>
    purrr::chuck("test")

  if (
    !base::all(train_ids %in% base::rownames(data_spatial_train_unordered))
  ) {
    cli::cli_abort("Fold-local MEM construction omitted training samples.")
  }

  if (
    !base::all(test_ids %in% base::rownames(data_spatial_test_unordered))
  ) {
    cli::cli_abort("Fold-local MEM projection omitted test samples.")
  }

  data_spatial_train <-
    data_spatial_train_unordered[
      train_ids,
      ,
      drop = FALSE
    ]

  data_spatial_test <-
    data_spatial_test_unordered[
      test_ids,
      ,
      drop = FALSE
    ]

  if (
    !base::identical(
      base::colnames(data_spatial_train),
      base::colnames(data_spatial_test)
    )
  ) {
    cli::cli_abort("Training and test MEM columns must be identical.")
  }

  if (
    !base::all(base::is.finite(base::as.matrix(data_spatial_train))) ||
      !base::all(base::is.finite(base::as.matrix(data_spatial_test)))
  ) {
    cli::cli_abort("Fold-local MEM predictors must contain finite values.")
  }

  n_mev_available <-
    base::ncol(data_spatial_train)

  data_diagnostics <-
    tibble::tibble(
      spatial_mode = spatial_mode,
      n_mev_requested = base::as.integer(n_mev),
      n_mev_available = base::as.integer(n_mev_available),
      n_train_locations = base::length(vec_train_locations),
      n_test_locations = base::length(vec_test_locations),
      n_train_samples = base::nrow(data_spatial_train),
      n_test_samples = base::nrow(data_spatial_test)
    )

  res <-
    base::list(
      data_spatial_train = data_spatial_train,
      data_spatial_test = data_spatial_test,
      data_diagnostics = data_diagnostics
    )

  return(res)
}

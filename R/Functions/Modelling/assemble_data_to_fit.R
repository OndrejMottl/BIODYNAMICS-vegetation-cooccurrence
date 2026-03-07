#' @title Assemble Final Data List for Model Fitting
#' @description
#' Validates that the community matrix and scaled abiotic data
#' share the same sample rows in the same order, then bundles
#' them — together with optional scaled spatial predictors —
#' into the named list expected by `fit_jsdm_model()`.
#' @param data_community_filtered
#' A numeric matrix with row names `"<dataset_name>__<age>"`
#' and taxon columns, as returned by `filter_constant_taxa()`.
#' @param data_abiotic_scaled_list
#' A named list with elements `data_abiotic_scaled` and
#' `scale_attributes`, as returned by
#' `scale_abiotic_for_fit()`. `data_abiotic_scaled` must have
#' row names matching those of the community matrix.
#' @param data_spatial_scaled_list
#' Optional. A named list with elements `data_spatial_scaled`
#' and `spatial_scale_attributes`, as returned by
#' `scale_spatial_for_fit()`. `data_spatial_scaled` must have
#' row names matching those of the community matrix. If `NULL`
#' (default), no spatial predictors are included.
#' @return
#' A named list with three mandatory and up to two optional
#' elements:
#' \describe{
#'   \item{`data_community_to_fit`}{The (filtered) community
#'   matrix.}
#'   \item{`data_abiotic_to_fit`}{The scaled abiotic data
#'   frame.}
#'   \item{`scale_attributes`}{Abiotic scaling attributes for
#'   back-transformation.}
#'   \item{`data_spatial_to_fit`}{Scaled spatial predictor
#'   data frame (only present when `data_spatial_scaled_list`
#'   is supplied).}
#'   \item{`spatial_scale_attributes`}{Spatial scaling
#'   attributes (only present when `data_spatial_scaled_list`
#'   is supplied).}
#' }
#' @details
#' This function performs only validation and assembly; all
#' data transformations are handled by the preceding pipeline
#' targets. An error is raised if any two inputs differ in row
#' count or row name ordering.
#' @seealso [filter_constant_taxa()], [scale_abiotic_for_fit()],
#'   [scale_spatial_for_fit()], [fit_jsdm_model()]
#' @export
assemble_data_to_fit <- function(
    data_community_filtered = NULL,
    data_abiotic_scaled_list = NULL,
    data_spatial_scaled_list = NULL) {
  assertthat::assert_that(
    is.matrix(data_community_filtered),
    msg = "data_community_filtered must be a matrix"
  )

  assertthat::assert_that(
    is.list(data_abiotic_scaled_list),
    all(
      c("data_abiotic_scaled", "scale_attributes") %in%
        names(data_abiotic_scaled_list)
    ),
    msg = paste0(
      "data_abiotic_scaled_list must be a list with elements",
      " 'data_abiotic_scaled' and 'scale_attributes'"
    )
  )

  if (
    !is.null(data_spatial_scaled_list)
  ) {
    assertthat::assert_that(
      is.list(data_spatial_scaled_list),
      all(
        c(
          "data_spatial_scaled",
          "spatial_scale_attributes"
        ) %in% names(data_spatial_scaled_list)
      ),
      msg = paste0(
        "data_spatial_scaled_list must be a list with",
        " elements 'data_spatial_scaled' and",
        " 'spatial_scale_attributes'"
      )
    )
  }

  data_abiotic_scaled <-
    data_abiotic_scaled_list |>
    purrr::chuck("data_abiotic_scaled")

  scale_attributes <-
    data_abiotic_scaled_list |>
    purrr::chuck("scale_attributes")

  # Validate row alignment: community vs abiotic -----

  assertthat::assert_that(
    nrow(data_community_filtered) == nrow(data_abiotic_scaled),
    msg = paste0(
      "Row counts of community and abiotic data",
      " must be identical"
    )
  )

  assertthat::assert_that(
    all(
      rownames(data_community_filtered) ==
        rownames(data_abiotic_scaled)
    ),
    msg = paste0(
      "Row names of community and abiotic data must be",
      " identical and in the same order"
    )
  )

  res <-
    list(
      data_community_to_fit = data_community_filtered,
      data_abiotic_to_fit = data_abiotic_scaled,
      scale_attributes = scale_attributes
    )

  if (
    !is.null(data_spatial_scaled_list)
  ) {
    data_spatial_scaled <-
      data_spatial_scaled_list |>
      purrr::chuck("data_spatial_scaled")

    spatial_scale_attributes <-
      data_spatial_scaled_list |>
      purrr::chuck("spatial_scale_attributes")

    assertthat::assert_that(
      is.data.frame(data_spatial_scaled),
      msg = "data_spatial_scaled must be a data frame"
    )

    assertthat::assert_that(
      nrow(data_spatial_scaled) ==
        nrow(data_community_filtered),
      msg = paste0(
        "Row count of spatial data must match",
        " the community matrix"
      )
    )

    assertthat::assert_that(
      all(
        rownames(data_spatial_scaled) ==
          rownames(data_community_filtered)
      ),
      msg = paste0(
        "Row names of spatial data must match",
        " those of the community matrix"
      )
    )

    res[["data_spatial_to_fit"]] <- data_spatial_scaled
    res[["spatial_scale_attributes"]] <-
      spatial_scale_attributes
  }

  return(res)
}

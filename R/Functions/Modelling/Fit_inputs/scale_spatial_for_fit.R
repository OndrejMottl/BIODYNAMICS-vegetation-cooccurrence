#' @title Scale Spatial Predictors for Model Fitting
#' @description
#' Centres and scales all spatial predictor columns, records
#' the scaling attributes for later back-transformation, and
#' returns both the scaled data frame and the attributes as a
#' named list.
#' @param data_spatial
#' A data frame with row names in the format
#' `"<dataset_name>__<age>"` and numeric columns containing
#' spatial predictor variables (e.g. `coord_x_km`,
#' `coord_y_km`), as returned by
#' `prepare_spatial_predictors_for_fit()`.
#' @return
#' A named list with two elements:
#' \describe{
#'   \item{`data_spatial_scaled`}{A data frame with the same
#'   row names as the input, with all predictor columns
#'   centred and scaled. When only one sample is present,
#'   columns are centred only (scale = FALSE).}
#'   \item{`spatial_scale_attributes`}{A named list of
#'   `center` and `scale` attributes for each predictor
#'   column, which can be used to back-transform
#'   predictions.}
#' }
#' @details
#' All columns are centred (mean subtracted) and divided by
#' their standard deviation using `base::scale()`, provided
#' more than one sample is present. When only one row exists,
#' only centring is applied.
#' @seealso [prepare_spatial_predictors_for_fit()],
#'   [assemble_data_to_fit()]
#' @export
scale_spatial_for_fit <- function(data_spatial = NULL) {
  assertthat::assert_that(
    is.data.frame(data_spatial),
    msg = "data_spatial must be a data frame"
  )

  assertthat::assert_that(
    nrow(data_spatial) > 0,
    msg = "data_spatial must have at least one row"
  )

  assertthat::assert_that(
    ncol(data_spatial) > 0,
    msg = "data_spatial must have at least one column"
  )

  is_scalable <-
    nrow(data_spatial) > 1

  # 1. Capture scale attributes -----

  spatial_scale_attributes <-
    data_spatial |>
    purrr::map(
      .f = ~ scale(
        .x,
        center = TRUE,
        scale = is_scalable
      ) |>
        attributes() %>% # use magrittr pipe for environment handling
        {
          .[-1]
        }
    )

  # 2. Apply scaling -----

  data_spatial_scaled <-
    data_spatial |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = ~ scale(
          .x,
          center = TRUE,
          scale = is_scalable
        ) |>
          as.numeric()
      )
    )

  # 3. Return list -----

  res <-
    list(
      data_spatial_scaled = data_spatial_scaled,
      spatial_scale_attributes = spatial_scale_attributes
    )

  return(res)
}

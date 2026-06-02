#' @title Apply Decomposition Scale Attributes
#' @description
#' Applies training-set scale attributes to held-out predictor rows.
#' @param data_predictors
#' Data frame with row names and predictor columns.
#' @param scale_attributes
#' Named list of scale attributes from `scale_abiotic_for_fit()` or
#' `scale_spatial_for_fit()`.
#' @return
#' Data frame with the same row names as `data_predictors` and scaled
#' columns ordered as `scale_attributes`.
#' @export
apply_decomposition_scale_attributes <- function(
    data_predictors = NULL,
    scale_attributes = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_predictors),
    msg = "`data_predictors` must be a data frame."
  )

  assertthat::assert_that(
    base::is.list(scale_attributes),
    base::length(scale_attributes) > 0L,
    msg = "`scale_attributes` must be a non-empty list."
  )

  vec_predictor_names <-
    base::names(scale_attributes)

  assertthat::assert_that(
    base::all(vec_predictor_names %in% base::colnames(data_predictors)),
    msg = "`data_predictors` must contain all scaled columns."
  )

  list_scaled <-
    vec_predictor_names |>
    rlang::set_names() |>
    purrr::map(
      .f = ~ {
        list_column_attributes <-
          scale_attributes |>
          purrr::chuck(.x)

        center_value <-
          list_column_attributes[["scaled:center"]]

        scale_value <-
          list_column_attributes[["scaled:scale"]]

        if (
          base::is.null(scale_value)
        ) {
          scale_value <- 1
        }

        if (
          !base::is.finite(scale_value) ||
            scale_value == 0
        ) {
          scale_value <- 1
        }

        (
          data_predictors[[.x]] - center_value
        ) / scale_value
      }
    )

  res <-
    base::as.data.frame(list_scaled)

  base::rownames(res) <- base::rownames(data_predictors)

  return(res)
}

#' @title Apply Training Scale Attributes
#' @description
#' Applies scale centres and optional scale factors learned from training data
#' to another predictor data frame without refitting the transformation.
#' @param data_predictors
#' Data frame with row names and numeric predictor columns.
#' @param scale_attributes
#' Named list of scale attributes produced by `scale_abiotic_for_fit()` or
#' `scale_spatial_for_fit()`.
#' @return
#' Data frame with the original row names and columns ordered as
#' `scale_attributes`.
#' @examples
#' data_predictors <-
#'   base::data.frame(temperature = base::c(8, 12))
#' scale_attributes <-
#'   base::list(
#'     temperature = base::list(
#'       "scaled:center" = 10,
#'       "scaled:scale" = 2
#'     )
#'   )
#' apply_scale_attributes(
#'   data_predictors = data_predictors,
#'   scale_attributes = scale_attributes
#' )
#' @export
apply_scale_attributes <- function(
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
    !base::is.null(vec_predictor_names),
    base::all(base::nzchar(vec_predictor_names)),
    !base::anyDuplicated(vec_predictor_names),
    msg = "`scale_attributes` must have unique predictor names."
  )

  assertthat::assert_that(
    base::all(vec_predictor_names %in% base::colnames(data_predictors)),
    msg = "`data_predictors` must contain every scaled predictor."
  )

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        data_predictors[vec_predictor_names],
        .f = base::is.numeric
      )
    ),
    msg = "Every scaled predictor must be numeric."
  )

  list_scaled_predictors <-
    vec_predictor_names |>
    rlang::set_names() |>
    purrr::map(
      .f = ~ {
        list_predictor_attributes <-
          scale_attributes |>
          purrr::chuck(.x)

        center_value <-
          list_predictor_attributes[["scaled:center"]]

        assertthat::assert_that(
          base::is.numeric(center_value),
          base::length(center_value) == 1L,
          base::is.finite(center_value),
          msg = stringr::str_glue(
            "Predictor {.x} must have one finite training centre."
          )
        )

        scale_value_raw <-
          list_predictor_attributes[["scaled:scale"]]

        scale_value <-
          if (
            base::is.null(scale_value_raw)
          ) {
            1
          } else {
            scale_value_raw
          }

        assertthat::assert_that(
          base::is.numeric(scale_value),
          base::length(scale_value) == 1L,
          base::is.finite(scale_value),
          scale_value != 0,
          msg = stringr::str_glue(
            "Predictor {.x} must have one finite non-zero scale."
          )
        )

        res_scaled <-
          (data_predictors[[.x]] - center_value) / scale_value

        return(res_scaled)
      }
    )

  res <-
    base::as.data.frame(
      list_scaled_predictors,
      check.names = FALSE
    )

  base::rownames(res) <-
    base::rownames(data_predictors)

  return(res)
}

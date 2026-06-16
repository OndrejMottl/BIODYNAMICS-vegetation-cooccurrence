#' @title Scale Prediction Abiotic Data
#' @description
#' Applies training-time scale attributes to abiotic predictor data used
#' for model prediction.
#' @param data_climate
#' Data frame containing one column for each entry in
#' `scale_attributes`, typically `age` and selected CHELSA variables.
#' @param scale_attributes
#' Named list of scale attributes as returned by
#' [scale_abiotic_for_fit()].
#' @return
#' Data frame with the same columns as `scale_attributes`, scaled to the
#' training model scale.
#' @examples
#' scale_prediction_abiotic(
#'   data_climate = tibble::tibble(age = 0, bio1 = 8),
#'   scale_attributes = list(
#'     age = list("scaled:center" = 0),
#'     bio1 = list("scaled:center" = 6, "scaled:scale" = 2)
#'   )
#' )
#' @export
scale_prediction_abiotic <- function(
    data_climate,
    scale_attributes) {
  assertthat::assert_that(
    base::is.data.frame(data_climate),
    msg = "`data_climate` must be a data frame."
  )

  assertthat::assert_that(
    base::is.list(scale_attributes) &&
      base::length(scale_attributes) > 0L &&
      !base::is.null(base::names(scale_attributes)),
    msg = "`scale_attributes` must be a non-empty named list."
  )

  vec_predictor_names <-
    base::names(scale_attributes)

  assertthat::assert_that(
    base::all(vec_predictor_names %in% base::colnames(data_climate)),
    msg = stringr::str_glue(
      "`data_climate` must contain columns: ",
      "{stringr::str_c(vec_predictor_names, collapse = ', ')}."
    )
  )

  res_scaled <-
    data_climate |>
    dplyr::select(dplyr::all_of(vec_predictor_names)) |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = ~ {
          column_name <- dplyr::cur_column()
          center_value <-
            scale_attributes[[column_name]][["scaled:center"]]
          scale_value <-
            scale_attributes[[column_name]][["scaled:scale"]]

          assertthat::assert_that(
            !base::is.null(center_value),
            msg = stringr::str_glue(
              "Missing scaled:center for {column_name}."
            )
          )

          center_value <- base::as.numeric(center_value)
          scale_value <- base::as.numeric(scale_value)

          if (
            base::length(scale_value) == 0L ||
              !base::is.finite(scale_value) ||
              scale_value == 0
          ) {
            scale_value <- 1
          }

          (.x - center_value) / scale_value
        }
      )
    ) |>
    base::as.data.frame()

  return(res_scaled)
}

#' @title Scale Abiotic Data for Model Fitting
#' @description
#' Centres and scales abiotic predictor variables, records the
#' scaling attributes for later back-transformation, and returns
#' both the scaled data frame and the attributes as a named list.
#'
#' `age` is centred only (mean subtracted, no division by SD).
#' All other variables are both centred and scaled (divided by SD)
#' when more than one sample is present.
#' @param data_abiotic_wide
#' A data frame in wide format as returned by
#' `prepare_abiotic_for_fit()`, containing real columns
#' `dataset_name`, `age`, and one column per abiotic variable.
#' @return
#' A named list with two elements:
#' \describe{
#'   \item{`data_abiotic_scaled`}{A data frame with row names in
#'   the format `"<dataset_name>__<age>"`, an `age` column
#'   (centre-only scaled), and all other abiotic variable columns
#'   (centre-and-scale). Rows with any `NA` are dropped before
#'   scaling.}
#'   \item{`scale_attributes`}{A named list of `center` and
#'   `scale` attributes for each variable (including `age`),
#'   which can be used to back-transform predictions.}
#' }
#' @details
#' Rows with any `NA` across the abiotic variables are silently
#' dropped via `tidyr::drop_na()` before scaling. The returned
#' `scale_attributes` list preserves the same structure as
#' `attributes(scale(x))[-1]` (i.e., `dim` excluded).
#' @seealso [prepare_abiotic_for_fit()], [assemble_data_to_fit()]
#' @export
scale_abiotic_for_fit <- function(data_abiotic_wide = NULL) {
  assertthat::assert_that(
    is.data.frame(data_abiotic_wide),
    msg = "data_abiotic_wide must be a data frame"
  )

  assertthat::assert_that(
    all(c("dataset_name", "age") %in% names(data_abiotic_wide)),
    msg = paste0(
      "data_abiotic_wide must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  # 1. Drop rows with any NA -----

  data_clean <-
    tidyr::drop_na(data_abiotic_wide)

  is_scalable <-
    nrow(data_clean) > 1

  # 2. Capture scale attributes -----

  vec_age_scaled <-
    data_clean |>
    dplyr::pull(age) |>
    scale(center = TRUE, scale = FALSE)

  list_age_attributes <-
    list(
      age = attributes(vec_age_scaled)[-1]
    )

  list_clim_attributes <-
    data_clean |>
    dplyr::select(-dataset_name, -age) |>
    purrr::map(
      .f = ~ scale(.x, center = TRUE, scale = is_scalable) |>
        attributes() %>% # use magrittr pipe for environment handling
        {
          .[-1]
        }
    )

  scale_attributes <-
    c(
      list_age_attributes,
      list_clim_attributes
    )

  # 3. Apply scaling and add row names -----

  data_abiotic_scaled <-
    data_clean |>
    dplyr::mutate(
      .row_name = paste0(dataset_name, "__", age),
      age = scale(age, center = TRUE, scale = FALSE) |>
        as.numeric()
    ) |>
    dplyr::mutate(
      dplyr::across(
        .cols = -c(dataset_name, age, .row_name),
        .fns = ~ scale(
          .x,
          center = TRUE,
          scale = is_scalable
        ) |>
          as.numeric()
      )
    ) |>
    dplyr::select(-dataset_name) |>
    tibble::column_to_rownames(".row_name")

  # 4. Return list -----

  res <-
    list(
      data_abiotic_scaled = data_abiotic_scaled,
      scale_attributes = scale_attributes
    )

  return(res)
}

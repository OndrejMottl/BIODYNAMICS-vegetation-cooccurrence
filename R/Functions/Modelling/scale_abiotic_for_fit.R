#' @title Scale Abiotic Data for Model Fitting
#' @description
#' Centres and scales abiotic predictor variables, records the scaling
#' attributes for later back-transformation, and returns both the
#' scaled data frame and the attributes as a named list.
#'
#' By default, `age` is centred and scaled to unit standard deviation
#' when age varies. Legacy centre-only scaling is available via
#' `age_scale_mode = "center"`. All other variables are both centred
#' and scaled when more than one sample is present.
#' @param data_abiotic_wide
#' A data frame in wide format as returned by
#' `prepare_abiotic_for_fit()`, containing real columns
#' `dataset_name`, `age`, and one column per abiotic variable.
#' @param age_scale_mode
#' Character scalar. `"z_score"` centres and scales `age` when age
#' varies. `"center"` centres `age` only.
#' @return
#' A named list with two elements:
#' \describe{
#'   \item{`data_abiotic_scaled`}{A data frame with row names in
#'   the format `"<dataset_name>__<age>"`, a scaled `age` column,
#'   and all other scaled abiotic variable columns. Rows with any
#'   `NA` are dropped before scaling.}
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
scale_abiotic_for_fit <- function(
    data_abiotic_wide = NULL,
    age_scale_mode = "z_score") {
  assertthat::assert_that(
    base::is.data.frame(data_abiotic_wide),
    msg = "data_abiotic_wide must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(age_scale_mode) &&
      base::length(age_scale_mode) == 1L,
    msg = "age_scale_mode must be a single character string"
  )

  assertthat::assert_that(
    age_scale_mode %in% base::c("z_score", "center"),
    msg = "age_scale_mode must be either 'z_score' or 'center'"
  )

  assertthat::assert_that(
    base::all(
      base::c("dataset_name", "age") %in% base::names(data_abiotic_wide)
    ),
    msg = stringr::str_c(
      "data_abiotic_wide must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  # 1. Drop rows with any NA -----

  data_clean <-
    tidyr::drop_na(data_abiotic_wide)

  is_scalable <-
    base::nrow(data_clean) > 1L

  age_is_variable <-
    is_scalable &&
    stats::sd(
      data_clean |>
        dplyr::pull(age),
      na.rm = TRUE
    ) > 0

  flag_scale_age <-
    age_scale_mode == "z_score" && isTRUE(age_is_variable)

  # 2. Capture scale attributes -----

  vec_age_scaled <-
    data_clean |>
    dplyr::pull(age) |>
    base::scale(center = TRUE, scale = flag_scale_age)

  list_age_attributes <-
    base::list(
      age = base::attributes(vec_age_scaled)[-1]
    )

  list_clim_attributes <-
    data_clean |>
    dplyr::select(-dataset_name, -age) |>
    purrr::map(
      .f = ~ {
        vec_scaled <-
          base::scale(
            .x,
            center = TRUE,
            scale = is_scalable
          )

        base::attributes(vec_scaled)[-1]
      }
    )

  scale_attributes <-
    base::c(
      list_age_attributes,
      list_clim_attributes
    )

  # 3. Apply scaling and add row names -----

  data_abiotic_scaled <-
    data_clean |>
    dplyr::mutate(
      .row_name = stringr::str_c(dataset_name, "__", age),
      age = base::scale(age, center = TRUE, scale = flag_scale_age) |>
        base::as.numeric()
    ) |>
    dplyr::mutate(
      dplyr::across(
        .cols = -dplyr::all_of(
          base::c("dataset_name", "age", ".row_name")
        ),
        .fns = ~ base::scale(
          .x,
          center = TRUE,
          scale = is_scalable
        ) |>
          base::as.numeric()
      )
    ) |>
    dplyr::select(-dataset_name) |>
    tibble::column_to_rownames(".row_name")

  # 4. Return list -----

  res <-
    base::list(
      data_abiotic_scaled = data_abiotic_scaled,
      scale_attributes = scale_attributes
    )

  return(res)
}

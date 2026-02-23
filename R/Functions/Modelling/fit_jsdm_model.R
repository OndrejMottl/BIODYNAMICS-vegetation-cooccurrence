#' @title Fit an sjSDM Model
#' @description
#' Fits a joint Species Distribution Model (jSDM) using the sjSDM
#' package with specified abiotic, spatial, and error family
#' configurations.
#' @param data_to_fit
#' A list containing the data to fit the model. Must include:
#' - `data_community_to_fit`: matrix of community composition
#' - `data_abiotic_to_fit`: data frame of abiotic variables
#' - `data_coords_to_fit`: data frame of spatial coordinates
#' @param sel_formula
#' A character string of length 1 specifying the formula for the model
#' @param abiotic_method
#' Method for modeling abiotic effects. One of "linear" (default) or
#' "DNN" (deep neural network)
#' @param spatial_method
#' Method for modeling spatial effects. One of "linear" (default) or
#' "DNN" (deep neural network)
#' @param error_family
#' Error family distribution. One of "gaussian" (default) or "binomial".
#' If "binomial", community data is converted to presence/absence and
#' a probit link is used
#' @param device
#' Computing device to use. One of "cpu" (default) or "gpu"
#' @param ...
#' Additional arguments passed to sjSDM::sjSDM
#' @return
#' An object of class sjSDM containing the fitted model
#' @details
#' This function prepares the data and fits a joint Species Distribution
#' Model using the sjSDM package. The spatial structure is modeled using
#' an interaction term between longitude and latitude coordinates. When
#' binomial error family is specified, the community data is converted
#' to binary presence/absence data.
#' @seealso sjSDM::sjSDM, sjSDM::linear, sjSDM::DNN
#' @export
fit_jsdm_model <- function(
    data_to_fit = NULL,
    sel_formula = NULL,
    abiotic_method = c("linear", "DNN"),
    spatial_method = c("linear", "DNN"),
    error_family = c("gaussian", "binomial"),
    device = c("cpu", "gpu"),
    ...,
    verbose = FALSE) {
  assertthat::assert_that(
    is.list(data_to_fit),
    msg = "data_to_fit must be a list"
  )

  assertthat::assert_that(
    "data_community_to_fit" %in% names(data_to_fit),
    msg = "`data_to_fit` must be a list containing `data_community_to_fit`"
  )

  data_community <-
    data_to_fit |>
    purrr::chuck("data_community_to_fit")


  assertthat::assert_that(
    is.matrix(data_community),
    msg = "data_community must be a matrix"
  )

  assertthat::assert_that(
    "data_abiotic_to_fit" %in% names(data_to_fit),
    msg = "`data_to_fit` must be a list containing `data_abiotic_to_fit`"
  )

  data_abiotic <-
    data_to_fit |>
    purrr::chuck("data_abiotic_to_fit")

  assertthat::assert_that(
    is.data.frame(data_abiotic),
    msg = "data_abiotic must be a data frame"
  )

  assertthat::assert_that(
    any(
      abiotic_method %in% c("linear", "DNN")
    ),
    msg = "abiotic_method must be either 'linear' or 'DNN'"
  )

  abiotic_method <- match.arg(abiotic_method)

  assertthat::assert_that(
    "data_coords_to_fit" %in% names(data_to_fit),
    msg = "`data_to_fit` must be a list containing `data_coords_to_fit`"
  )

  data_spatial <-
    data_to_fit |>
    purrr::chuck("data_coords_to_fit")

  assertthat::assert_that(
    is.data.frame(data_spatial),
    msg = "data_spatial must be a data frame"
  )

  assertthat::assert_that(
    any(
      spatial_method %in% c("linear", "DNN")
    ),
    msg = "spatial_method must be either 'linear' or 'DNN'"
  )

  spatial_method <- match.arg(spatial_method)

  spatial <-
    sjSDM::linear(
      data = data_spatial,
      formula = ~ 0 + coord_long:coord_lat
    )

  assertthat::assert_that(
    any(
      device %in% c("cpu", "gpu")
    ),
    msg = "device must be either 'cpu' or 'gpu'"
  )

  device <- match.arg(device)

  assertthat::assert_that(
    any(
      error_family %in% c("gaussian", "binomial")
    ),
    msg = "error_family must be either 'gaussian' or 'binomial'"
  )

  error_family <- match.arg(error_family)

  assertthat::assert_that(
    length(error_family) == 1,
    msg = "error_family must be a character string of length 1"
  )

  if (
    error_family == "binomial"
  ) {
    data_community <-
      data_community > 0

    # we need to filter out taxa with no variation in presence/absence,
    #   as these will cause issues with model fitting
    data_community <-
      data_community[
        ,
        colSums(data_community) > 0 &
          colSums(data_community) < nrow(data_community)
      ]


    error_family <- binomial("probit")
  } else if (
    error_family == "gaussian"
  ) {
    error_family <- gaussian()
  } else {
    stop("Invalid error_family. Must be 'gaussian' or 'binomial'.")
  }

  assertthat::assert_that(
    is.logical(verbose),
    length(verbose) == 1,
    msg = "verbose must be a logical value of length 1"
  )

  if (
    abiotic_method == "linear"
  ) {
    assertthat::assert_that(
      class(sel_formula) == "formula",
      msg = "sel_formula must be a formula object"
    )

    # There is an isseu that `sjSDM::linear()` is looking for `sel_formula` in
    #  the parent environment, but it is not finding it.
    # To work around this, we will manually assign `sel_formula` to
    #   the parent environment before calling `sjSDM::linear()`,
    #   and then remove it from the parent environment after fitting the model.

    current_env <- environment()
    parent_env <- parent.env(current_env)

    # check if sel_formula is in the parent environment
    if (!exists("sel_formula", envir = parent_env)) {
      # add sel_formula to the parent environment
      assign(
        "sel_formula",
        sel_formula,
        envir = parent_env
      )
    }

    sel_biotic <-
      sjSDM::linear(
        data = data_abiotic,
        formula = sel_formula
      )

    mod_sjsdm <-
      sjSDM::sjSDM(
        Y = as.matrix(data_community),
        env = sel_biotic,
        spatial = spatial,
        se = FALSE,
        family = error_family,
        device = device,
        verbose = FALSE,
        ...
      )

    # remove sel_formula from the parent environment
    rm(sel_formula, envir = parent_env)
  } else if (
    abiotic_method == "DNN"
  ) {
    mod_sjsdm <-
      sjSDM::sjSDM(
        Y = as.matrix(data_community),
        env = sjSDM::DNN(data_abiotic),
        spatial = spatial,
        se = FALSE,
        family = error_family,
        device = device,
        verbose = FALSE,
        ...
      )
  } else {
    stop("Invalid abiotic_method. Must be 'linear' or 'DNN'.")
  }



  return(mod_sjsdm)
}

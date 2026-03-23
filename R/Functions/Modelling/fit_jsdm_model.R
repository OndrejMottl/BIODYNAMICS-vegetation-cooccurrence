#' @title Fit an sjSDM Model
#' @description
#' Fits a joint Species Distribution Model (jSDM) using the sjSDM
#' package with specified abiotic, spatial, and error family
#' configurations.
#' @param data_to_fit
#' A list containing the data to fit the model. Must include:
#' - `data_community_to_fit`: matrix of community composition
#'   (constant-presence taxa already removed by
#'   `filter_constant_taxa()`)
#' - `data_abiotic_to_fit`: data frame of abiotic variables,
#'   already scaled by `scale_abiotic_for_fit()`
#' - `data_spatial_to_fit`: data frame of spatial predictors,
#'   already scaled by `scale_spatial_for_fit()`. Required
#'   only when `spatial_method` is not `"none"`.
#' @param sel_abiotic_formula
#' A formula object specifying the abiotic (environmental) predictors
#' @param abiotic_method
#' Method for modeling abiotic effects. One of "linear" (default) or
#' "DNN" (deep neural network)
#' @param sel_spatial_formula
#' A formula object specifying the spatial predictors. Defaults to an
#' interaction between longitude and latitude
#' (`~ 0 + coord_long:coord_lat`). Only used if
#' `spatial_method` is `"linear"` or `"DNN"`.
#' @param spatial_method
#' Method for modeling spatial effects. One of `"linear"` (default),
#' `"DNN"` (deep neural network), or `"none"` (no spatial structure)
#' @param error_family
#' Error family distribution. One of "gaussian" (default) or "binomial".
#' If "binomial", community data is converted to presence/absence and
#' a probit link is used
#' @param device
#' Computing device to use. One of "cpu" (default) or "gpu"
#' @param compute_se
#' Logical indicating whether to compute standard errors inline
#' during model fitting. Default is `FALSE`. Prefer the
#' post-hoc approach via `compute_jsdm_se()` in a separate
#' pipeline target, which allows CPU parallelisation
#' independent of the GPU device setting.
#' @param parallel
#' Number of CPU cores to use for parallel processing.
#' Only applicable if `device = "cpu"`. Default is `0L`
#' (no parallelisation).
#' @param ...
#' Additional arguments passed to `sjSDM::sjSDM()` (e.g.
#' `sampling`, `step_size`, `seed`). Do NOT pass `iter`,
#' `control` or `early_stopping` directly — use the dedicated
#' `iter` and `n_early_stopping` parameters instead.
#' @param iter
#' Positive integer. Number of training epochs. Default is `100L`.
#' @param n_early_stopping
#' Early stopping patience. Controls how many consecutive epochs
#' without improvement are tolerated before training is halted.
#' Three accepted values:
#' - `NULL` (default): auto-compute as `round(iter * 0.20)`, i.e.
#'   at least 20 \% of the epoch budget.
#' - `0L` or negative integer: disables early stopping entirely.
#' - Positive integer: uses `max(value, round(iter * 0.20))` to
#'   ensure patience is never set below 20 \% of `iter`. Passed
#'   as `early_stopping_training` in `sjSDM::sjSDMControl()`.
#' @return
#' An object of class sjSDM containing the fitted model
#' @details
#' This function prepares the data and fits a joint Species Distribution
#' Model using the sjSDM package. The spatial structure is modeled using
#' an interaction term between longitude and latitude coordinates. When
#' binomial error family is specified, the community data is converted
#' to binary presence/absence data.
#'
#' Standard error computation (`compute_se = TRUE`) may fail with certain
#' model configurations, particularly when using DNN methods or complex
#' spatial structures. If SE computation fails, the model will still be
#' returned with a warning.
#' @seealso sjSDM::sjSDM, sjSDM::linear, sjSDM::DNN, compute_jsdm_se
#' @export
fit_jsdm_model <- function(
    data_to_fit = NULL,
    sel_abiotic_formula = NULL,
    abiotic_method = c("linear", "DNN"),
    sel_spatial_formula = as.formula(~ 0 + coord_long:coord_lat),
    spatial_method = c("linear", "DNN", "none"),
    error_family = c("gaussian", "binomial"),
    device = c("cpu", "gpu"),
    parallel = 0L,
    compute_se = FALSE,
    ...,
    iter = 100L,
    n_early_stopping = NULL,
    verbose = FALSE) {
  # Validate `data_to_fit` structure
  assertthat::assert_that(
    is.list(data_to_fit),
    msg = "data_to_fit must be a list"
  )

  assertthat::assert_that(
    "data_community_to_fit" %in% names(data_to_fit),
    msg = "`data_to_fit` must be a list containing `data_community_to_fit`"
  )

  assertthat::assert_that(
    "data_abiotic_to_fit" %in% names(data_to_fit),
    msg = "`data_to_fit` must be a list containing `data_abiotic_to_fit`"
  )

  # Extract data components
  data_community <-
    data_to_fit |>
    purrr::chuck("data_community_to_fit")

  data_abiotic <-
    data_to_fit |>
    purrr::chuck("data_abiotic_to_fit")

  # Validate extracted data types
  assertthat::assert_that(
    is.matrix(data_community),
    msg = "data_community must be a matrix"
  )

  assertthat::assert_that(
    is.data.frame(data_abiotic),
    msg = "data_abiotic must be a data frame"
  )

  # Validate formula arguments
  assertthat::assert_that(
    class(sel_abiotic_formula) == "formula",
    msg = "sel_abiotic_formula must be a formula object"
  )

  assertthat::assert_that(
    class(sel_spatial_formula) == "formula",
    msg = "sel_spatial_formula must be a formula object"
  )

  # Validate and match character arguments
  assertthat::assert_that(
    any(abiotic_method %in% c("linear", "DNN")),
    msg = "abiotic_method must be either 'linear' or 'DNN'"
  )

  abiotic_method <- match.arg(abiotic_method)

  assertthat::assert_that(
    any(spatial_method %in% c("linear", "DNN", "none")),
    msg = "spatial_method must be either 'linear', 'DNN', or 'none'"
  )

  spatial_method <- match.arg(spatial_method)

  # Extract and validate spatial data when needed -----
  # Note: data_spatial_to_fit is pre-scaled by
  #   scale_spatial_for_fit(); no additional scaling applied.
  if (
    spatial_method %in% c("linear", "DNN")
  ) {
    assertthat::assert_that(
      "data_spatial_to_fit" %in% names(data_to_fit),
      msg = paste0(
        "`data_to_fit` must contain `data_spatial_to_fit`",
        " when spatial_method is not 'none'"
      )
    )

    data_spatial <-
      data_to_fit |>
      purrr::chuck("data_spatial_to_fit")

    assertthat::assert_that(
      is.data.frame(data_spatial),
      msg = "data_spatial must be a data frame"
    )
  } else {
    data_spatial <- NULL
  }

  assertthat::assert_that(
    any(error_family %in% c("gaussian", "binomial")),
    msg = "error_family must be either 'gaussian' or 'binomial'"
  )

  error_family <- match.arg(error_family)

  assertthat::assert_that(
    any(device %in% c("cpu", "gpu")),
    msg = "device must be either 'cpu' or 'gpu'"
  )

  device <- match.arg(device)

  # Validate numeric and logical arguments
  assertthat::assert_that(
    is.numeric(parallel),
    length(parallel) == 1,
    msg = "parallel must be a numeric value of length 1"
  )

  assertthat::assert_that(
    is.logical(compute_se),
    length(compute_se) == 1,
    msg = "compute_se must be a logical value of length 1"
  )

  assertthat::assert_that(
    is.logical(verbose),
    length(verbose) == 1,
    msg = "verbose must be a logical value of length 1"
  )

  assertthat::assert_that(
    is.numeric(iter),
    length(iter) == 1,
    iter > 0,
    msg = paste0(
      "`iter` must be a single positive numeric value of length 1"
    )
  )

  assertthat::assert_that(
    is.null(n_early_stopping) ||
      (is.numeric(n_early_stopping) && length(n_early_stopping) == 1),
    msg = paste0(
      "`n_early_stopping` must be NULL or a single numeric",
      " value of length 1"
    )
  )

  # Handle device/parallel conflict
  if (
    device == "gpu" && parallel > 0L
  ) {
    message(
      paste0(
        "Parallel processing is not supported when device = 'gpu'.",
        " Setting parallel to 0L."
      )
    )
    parallel <- 0L
  }

  # Convert community data to presence/absence for binomial
  if (
    error_family == "binomial"
  ) {
    data_community <-
      data_community > 0

    error_family <- binomial("probit")
  } else {
    error_family <- gaussian()
  }

  # Build spatial structure
  # Note: sjSDM::linear/DNN use match.call() internally and re-evaluate
  #   formula symbols in parent.env(environment()) = namespace:sjSDM.
  #   Using do.call passes the formula as an already-evaluated object
  #   (class "formula"), so the bare-name eval branch is never triggered.
  if (
    spatial_method == "linear"
  ) {
    spatial <-
      do.call(
        sjSDM::linear,
        list(
          data = data_spatial,
          formula = sel_spatial_formula
        )
      )
  } else if (spatial_method == "DNN") {
    spatial <-
      do.call(
        sjSDM::DNN,
        list(
          data = data_spatial,
          formula = sel_spatial_formula
        )
      )
  } else if (spatial_method == "none") {
    spatial <- NULL
  }

  # Build abiotic (environmental) structure
  # Note: data_abiotic is already scaled upstream by
  #   scale_abiotic_for_fit(); no additional scaling is applied.
  if (
    abiotic_method == "linear"
  ) {
    sel_biotic <-
      do.call(
        sjSDM::linear,
        list(
          data = data_abiotic,
          formula = sel_abiotic_formula
        )
      )
  } else {
    sel_biotic <-
      do.call(
        sjSDM::DNN,
        list(
          data = data_abiotic,
          formula = sel_abiotic_formula
        )
      )
  }

  # Three-tier early stopping patience:
  #  "NULL"  -> auto: round(iter * 0.20), ensuring >= 20% of budget
  #  <= 0  -> 0 (disabled, maps to sjSDMControl's "disabled" value)
  #  > 0   -> max(value, round(iter * 0.20)), floor at 20% of iter
  sel_early_stopping <-
    if (
      base::is.null(n_early_stopping)
    ) {
      base::as.integer(base::round(iter * 0.20))
    } else if (
      n_early_stopping <= 0
    ) {
      0L
    } else {
      base::max(
        base::as.integer(n_early_stopping),
        base::as.integer(base::round(iter * 0.20))
      )
    }

  sel_control <-
    sjSDM::sjSDMControl(early_stopping_training = sel_early_stopping)

  mod_sjsdm <-
    sjSDM::sjSDM(
      Y = as.matrix(data_community),
      env = sel_biotic,
      spatial = spatial,
      se = compute_se,
      family = error_family,
      device = device,
      verbose = verbose,
      control = sel_control,
      iter = iter,
      ...
    )

  return(mod_sjsdm)
}

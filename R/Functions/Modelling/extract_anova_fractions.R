#' @title Extract ANOVA Fraction Components from a Single Object
#' @description
#' Extracts specified variance partitioning fractions from a
#' single sjSDManova object, returning a two-column tibble with
#' fraction codes and their Nagelkerke R² values.
#' @param anova_object
#' A single sjSDManova-like object containing a
#' \code{$results} element with columns \code{models} and
#' \code{"R2 Nagelkerke"}. Must be a list.
#' @param vec_anova_fractions
#' A non-empty character vector of fraction codes to retain
#' (e.g. \code{c("F_A", "F_B", "F_S")}).
#' @param clamp_negative
#' A single logical (default \code{TRUE}). If \code{TRUE},
#' negative Nagelkerke R² values are clamped to 0.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{component}{Character. Human-readable component label
#'     (e.g. "Abiotic", "Associations", "Spatial").}
#'   \item{R2_Nagelkerke}{Numeric. Nagelkerke R² value for
#'     each fraction, optionally clamped to [0, Inf).}
#' }
#' @details
#' Accesses \code{anova_object$results} via
#' \code{purrr::chuck()}, filters rows whose \code{models}
#' value is in \code{vec_anova_fractions}, renames the
#' columns to \code{component} and \code{R2_Nagelkerke},
#' translates internal fraction codes to human-readable
#' labels, and (when \code{clamp_negative = TRUE}) clamps
#' negative R² values to 0:
#' \itemize{
#'   \item F_A   -> "Abiotic"
#'   \item F_B   -> "Associations"
#'   \item F_S   -> "Spatial"
#'   \item F_AB  -> "Abiotic&Associations"
#'   \item F_AS  -> "Abiotic&Spatial"
#'   \item F_BS  -> "Associations&Spatial"
#'   \item F_ABS -> "Abiotic&Associations&Spatial"
#' }
#' @seealso [aggregate_anova_components()]
#' @export
extract_anova_fractions <- function(
    anova_object,
    vec_anova_fractions = c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS"),
    clamp_negative = TRUE) {
  assertthat::assert_that(
    base::is.list(anova_object),
    msg = "'anova_object' must be a list."
  )

  assertthat::assert_that(
    base::is.character(vec_anova_fractions),
    msg = "'vec_anova_fractions' must be a character vector."
  )

  assertthat::assert_that(
    base::length(vec_anova_fractions) > 0,
    msg = "'vec_anova_fractions' must not be empty."
  )

  assertthat::assert_that(
    assertthat::is.flag(clamp_negative),
    msg = "'clamp_negative' must be a single logical value."
  )

  # Map internal fraction codes to human-readable labels
  #   following the convention used in variance partitioning
  #   plots
  vec_component_labels <-
    c(
      "F_A"   = "Abiotic",
      "F_B"   = "Associations",
      "F_S"   = "Spatial",
      "F_AB"  = "Abiotic&Associations",
      "F_AS"  = "Abiotic&Spatial",
      "F_BS"  = "Associations&Spatial",
      "F_ABS" = "Abiotic&Associations&Spatial"
    )

  res <-
    anova_object |>
    purrr::chuck("results") |>
    dplyr::filter(
      models %in% vec_anova_fractions
    ) |>
    dplyr::select(
      component = "models",
      R2_Nagelkerke = "R2 Nagelkerke"
    ) |>
    dplyr::mutate(
      # Replace internal codes with human-readable labels
      component = vec_component_labels[component],
      # Clamp negative R² to 0 when requested
      R2_Nagelkerke_coorrected = pmax(R2_Nagelkerke, 0),
      R2_Nagelkerke = purrr::map2_dbl(
        .x = R2_Nagelkerke,
        .y = R2_Nagelkerke_coorrected,
        .f = ~ if (clamp_negative) .y else .x
      )
    ) |>
    dplyr::select(
      component,
      R2_Nagelkerke
    )


  return(res)
}

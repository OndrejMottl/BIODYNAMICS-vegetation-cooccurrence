#' @title Extract Variance Fractions from a Single sjSDM Object
#' @description
#' Extracts specified variance partitioning fractions from a
#' single sjSDManova object, returning a two-column tibble with
#' fraction labels and their Nagelkerke R² values.
#' @param anova_object
#' A single sjSDManova-like list containing a named
#' `"results"` element with columns `models` and
#' `"R2 Nagelkerke"`.
#' @param vec_anova_fractions
#' A non-empty character vector of fraction codes to retain
#' (e.g. `c("F_A", "F_B", "F_S")`).
#' @param clamp_negative
#' A single logical (default `TRUE`). If `TRUE`, negative
#' Nagelkerke R² values are clamped to 0.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{component}{Character. Human-readable component label
#'     (e.g. "Abiotic", "Associations", "Spatial").}
#'   \item{R2_Nagelkerke}{Numeric. Nagelkerke R² value for
#'     each fraction, optionally clamped to [0, Inf).}
#' }
#' @details
#' Accesses the named `"results"` element with `purrr::chuck()`,
#' filters the requested fraction codes, and translates them to
#' human-readable component labels.
#' @seealso [aggregate_jsdm_variance_components()]
#' @export
extract_jsdm_variance_fractions <- function(
    anova_object,
    vec_anova_fractions = base::c(
      "F_A",
      "F_B",
      "F_S",
      "F_AB",
      "F_AS",
      "F_BS",
      "F_ABS"
    ),
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

  vec_component_labels <-
    base::c(
      "F_A" = "Abiotic",
      "F_B" = "Associations",
      "F_S" = "Spatial",
      "F_AB" = "Abiotic&Associations",
      "F_AS" = "Abiotic&Spatial",
      "F_BS" = "Associations&Spatial",
      "F_ABS" = "Abiotic&Associations&Spatial"
    )

  res <-
    anova_object |>
    purrr::chuck("results") |>
    dplyr::filter(
      .data[["models"]] %in% vec_anova_fractions
    ) |>
    dplyr::select(
      component = "models",
      R2_Nagelkerke = "R2 Nagelkerke"
    ) |>
    dplyr::mutate(
      component = vec_component_labels[.data[["component"]]],
      R2_Nagelkerke_corrected =
        base::pmax(.data[["R2_Nagelkerke"]], 0),
      R2_Nagelkerke =
        purrr::map2_dbl(
          .x = .data[["R2_Nagelkerke"]],
          .y = .data[["R2_Nagelkerke_corrected"]],
          .f = ~ if (clamp_negative) .y else .x
        )
    ) |>
    dplyr::select(
      dplyr::all_of(
        base::c("component", "R2_Nagelkerke")
      )
    )

  return(res)
}

#' @title Aggregate ANOVA Variance Components Across Time Slices
#' @description
#' Extracts variance partitioning fractions from a named list
#' of sjSDM ANOVA objects and assembles a long-format tibble
#' with one row per age × component combination.
#' @param list_model_anova
#' A named list of sjSDManova objects, one per time slice.
#' Names must end with a numeric age value
#' (e.g. "timeslice_500"). NULL entries and objects without a
#' \code{$results} element are silently discarded.
#' @return
#' A tibble with columns:
#' \describe{
#'   \item{age}{Numeric age (cal yr BP) extracted from the
#'     list-element name.}
#'   \item{component}{Character. Human-readable component label
#'     (e.g. "Abiotic", "Associations", "Spatial").}
#'   \item{R2_Nagelkerke}{Numeric. Nagelkerke R² for the
#'     component, clamped to [0, Inf).}
#' }
#' @details
#' The age is parsed from the list element name by extracting
#' the trailing digit sequence (e.g. "timeslice_500" -> 500).
#' Fraction extraction, code-to-label translation, and
#' negative R² clamping are delegated to
#' [extract_anova_fractions()] (called with
#' \code{clamp_negative = TRUE}).
#' @seealso [get_anova()], [extract_anova_fractions()]
#' @export
aggregate_anova_components <- function(list_model_anova) {
  assertthat::assert_that(
    base::is.list(list_model_anova),
    msg = "'list_model_anova' must be a list."
  )

  vec_anova_fractions <-
    c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS")

  res <-
    list_model_anova |>
    purrr::discard(
      ~ base::is.null(.x) || !("results" %in% base::names(.x))
    ) |>
    purrr::imap(
      .f = ~ {
        age_val <-
          .y |>
          stringr::str_extract("\\d+$") |>
          as.numeric()

        extract_anova_fractions(
          anova_object = .x,
          vec_anova_fractions = vec_anova_fractions,
          clamp_negative = TRUE
        ) |>
          dplyr::mutate(
            age = age_val
          )
      }
    ) |>
    purrr::list_rbind()

  return(res)
}

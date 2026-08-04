#' @title Aggregate sjSDM Variance Components Across Time Slices
#' @description
#' Extracts variance partitioning fractions from a named list
#' of sjSDM ANOVA objects and assembles a long-format tibble
#' with one row per age and component combination.
#' @param list_model_anova
#' A named list of sjSDManova objects, one per time slice.
#' Names must end with a numeric age value
#' (e.g. `"timeslice_500"`). `NULL` entries and objects without
#' a named `"results"` element are silently discarded.
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
#' The age is parsed from the trailing digit sequence in each
#' list-element name. Fraction extraction and negative-value
#' clamping are delegated to [extract_jsdm_variance_fractions()].
#' @seealso [compute_jsdm_variance_partition()],
#'   [extract_jsdm_variance_fractions()]
#' @export
aggregate_jsdm_variance_components <- function(list_model_anova) {
  assertthat::assert_that(
    base::is.list(list_model_anova),
    msg = "'list_model_anova' must be a list."
  )

  vec_anova_fractions <-
    base::c(
      "F_A",
      "F_B",
      "F_S",
      "F_AB",
      "F_AS",
      "F_BS",
      "F_ABS"
    )

  res <-
    list_model_anova |>
    purrr::discard(
      ~ base::is.null(.x) || !"results" %in% base::names(.x)
    ) |>
    purrr::imap(
      .f = ~ {
        age_val <-
          .y |>
          stringr::str_extract("\\d+$") |>
          base::as.numeric()

        extract_jsdm_variance_fractions(
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

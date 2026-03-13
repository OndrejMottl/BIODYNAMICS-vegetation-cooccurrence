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
#' Component labels map internal fraction codes to human-readable
#' names:
#' \itemize{
#'   \item F_A   -> "Abiotic"
#'   \item F_B   -> "Associations"
#'   \item F_S   -> "Spatial"
#'   \item F_AB  -> "Abiotic&Associations"
#'   \item F_AS  -> "Abiotic&Spatial"
#'   \item F_BS  -> "Associations&Spatial"
#'   \item F_ABS -> "Abiotic&Associations&Spatial"
#' }
#' @seealso [get_anova()]
#' @export
aggregate_anova_components <- function(list_model_anova) {
  assertthat::assert_that(
    base::is.list(list_model_anova),
    msg = "'list_model_anova' must be a list."
  )

  vec_anova_fractions <-
    c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS")

  # Map internal fraction codes to human-readable labels
  #   following the convention used in variance partitioning plots
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

        .x |>
          purrr::chuck("results") |>
          dplyr::filter(
            models %in% vec_anova_fractions
          ) |>
          dplyr::select(
            component = "models",
            R2_Nagelkerke = "R2 Nagelkerke"
          ) |>
          dplyr::mutate(
            age = age_val,
            # Clamp negative R² to 0
            R2_Nagelkerke = pmax(R2_Nagelkerke, 0),
            # Replace internal codes with human-readable labels
            component = vec_component_labels[component]
          )
      }
    ) |>
    purrr::list_rbind()

  return(res)
}

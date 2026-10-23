#' @title Compute Predictor-Inclusive Variance Components
#' @description
#' Computes the full variance contribution associated with each predictor
#' domain without dividing shared fractions among domains.
#' @param data_source
#' A non-empty data frame with columns `age`, `component`, and
#' `R2_Nagelkerke`. Missing fraction labels are treated as zero, and negative
#' R-squared values are clamped to zero.
#' @return
#' A tibble with three rows per age and columns `age`, `component`,
#' `R2_Nagelkerke_predictor_inclusive`, and
#' `R2_Nagelkerke_predictor_inclusive_percentage`.
#' @details
#' Each shared fraction contributes in full to every predictor domain that it
#' contains. Percentages use the sum of the seven clamped variance fractions
#' as their denominator, so percentages across domains may exceed 100 percent.
#' @seealso [compute_shapley_variance_components()]
#' @export
compute_predictor_inclusive_variance_components <- function(data_source) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    base::nrow(data_source) > 0L,
    msg = "'data_source' must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("age", "component", "R2_Nagelkerke") %in%
        base::colnames(data_source)
    ),
    msg = stringr::str_c(
      "'data_source' must contain columns",
      " 'age', 'component', and 'R2_Nagelkerke'."
    )
  )

  res <-
    data_source |>
    dplyr::mutate(
      R2_clamped = base::pmax(.data[["R2_Nagelkerke"]], 0)
    ) |>
    dplyr::group_by(.data[["age"]]) |>
    dplyr::group_modify(
      .f = ~ {
        fraction_abiotic <-
          .lookup_jsdm_variance_component(.x, "Abiotic")
        fraction_associations <-
          .lookup_jsdm_variance_component(.x, "Associations")
        fraction_spatial <-
          .lookup_jsdm_variance_component(.x, "Spatial")
        fraction_abiotic_associations <-
          .lookup_jsdm_variance_component(
            .x,
            "Abiotic&Associations"
          )
        fraction_abiotic_spatial <-
          .lookup_jsdm_variance_component(.x, "Abiotic&Spatial")
        fraction_associations_spatial <-
          .lookup_jsdm_variance_component(
            .x,
            "Associations&Spatial"
          )
        fraction_all <-
          .lookup_jsdm_variance_component(
            .x,
            "Abiotic&Associations&Spatial"
          )

        vec_fraction_values <-
          base::c(
            fraction_abiotic,
            fraction_associations,
            fraction_spatial,
            fraction_abiotic_associations,
            fraction_abiotic_spatial,
            fraction_associations_spatial,
            fraction_all
          )
        fraction_total <-
          base::sum(vec_fraction_values)
        vec_inclusive_values <-
          base::c(
            fraction_abiotic +
              fraction_abiotic_associations +
              fraction_abiotic_spatial +
              fraction_all,
            fraction_associations +
              fraction_abiotic_associations +
              fraction_associations_spatial +
              fraction_all,
            fraction_spatial +
              fraction_abiotic_spatial +
              fraction_associations_spatial +
              fraction_all
          )
        vec_inclusive_percentages <-
          if (
            fraction_total > 0
          ) {
            vec_inclusive_values / fraction_total * 100
          } else {
            base::rep(NA_real_, 3L)
          }

        tibble::tibble(
          component = base::c(
            "Abiotic",
            "Associations",
            "Spatial"
          ),
          R2_Nagelkerke_predictor_inclusive = vec_inclusive_values,
          R2_Nagelkerke_predictor_inclusive_percentage =
            vec_inclusive_percentages
        )
      }
    ) |>
    dplyr::ungroup()

  return(res)
}

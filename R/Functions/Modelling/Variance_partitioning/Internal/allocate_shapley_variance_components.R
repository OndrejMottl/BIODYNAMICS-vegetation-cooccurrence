.allocate_shapley_variance_components <- function(
    data_slice,
    group_keys) {
  base::invisible(group_keys)

  fraction_abiotic <-
    .lookup_jsdm_variance_component(data_slice, "Abiotic")
  fraction_associations <-
    .lookup_jsdm_variance_component(data_slice, "Associations")
  fraction_spatial <-
    .lookup_jsdm_variance_component(data_slice, "Spatial")
  fraction_abiotic_associations <-
    .lookup_jsdm_variance_component(
      data_slice,
      "Abiotic&Associations"
    )
  fraction_abiotic_spatial <-
    .lookup_jsdm_variance_component(
      data_slice,
      "Abiotic&Spatial"
    )
  fraction_associations_spatial <-
    .lookup_jsdm_variance_component(
      data_slice,
      "Associations&Spatial"
    )
  fraction_all <-
    .lookup_jsdm_variance_component(
      data_slice,
      "Abiotic&Associations&Spatial"
    )

  res <-
    tibble::tibble(
      component =
        base::c("Abiotic", "Associations", "Spatial"),
      R2_Nagelkerke_adjusted =
        base::c(
          fraction_abiotic +
            fraction_abiotic_associations / 2 +
            fraction_abiotic_spatial / 2 +
            fraction_all / 3,
          fraction_associations +
            fraction_abiotic_associations / 2 +
            fraction_associations_spatial / 2 +
            fraction_all / 3,
          fraction_spatial +
            fraction_abiotic_spatial / 2 +
            fraction_associations_spatial / 2 +
            fraction_all / 3
        )
    )

  return(res)
}

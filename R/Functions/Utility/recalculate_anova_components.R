recalculate_anova_components <- function(data_source) {
  assertthat::assert_that(
    is.data.frame(data_source),
    nrow(data_source) > 0
  )

  assertthat::assert_that(
    "age" %in% colnames(data_source),
    "R2_Nagelkerke" %in% colnames(data_source)
  )

  data_percentage <-
    data_source |>
    dplyr::group_by(age) |>
    dplyr::mutate(
      R2_Nagelkerke_percentage = R2_Nagelkerke / sum(R2_Nagelkerke) * 100
    ) |>
    dplyr::ungroup()

  return(data_percentage)
}

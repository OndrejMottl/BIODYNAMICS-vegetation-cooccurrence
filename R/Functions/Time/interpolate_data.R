interpolate_data <- function(
    data,
    age_var = "age",
    value_var = "pollen_prop",
    method = "linear",
    rule = 1,
    ties = mean,
    age_min = 0,
    age_max = 12e03,
    timestep = 500) {
  data %>%
    tidyr::nest(data_nested = !c("dataset_name", "taxon")) %>%
    dplyr::mutate(
      data_interpolated = purrr::map(
        .x = data_nested,
        .f = purrr::possibly(
          .f = ~ .x %>%
            dplyr::select(
              !!rlang::sym(age_var),
              !!rlang::sym(value_var)
            ) %>%
            grDevices::xy.coords() %>%
            stats::approx(
              xout = seq(
                age_min,
                age_max,
                by = timestep
              ),
              ties = ties,
              method = method,
              rule = rule
            ) %>%
            tibble::as_tibble() %>%
            dplyr::rename(
              !!rlang::sym(age_var) := x,
              !!rlang::sym(value_var) := y
            ),
          otherwise = NULL
        )
      )
    ) %>%
    tidyr::unnest(data_interpolated) %>%
    dplyr::select(
      "dataset_name",
      "taxon",
      !!rlang::sym(age_var),
      !!rlang::sym(value_var)
    ) %>%
    return()
}

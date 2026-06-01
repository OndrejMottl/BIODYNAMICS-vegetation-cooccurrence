#' @title Read Functional-Type Classification
#' @description
#' Reads an explicit functional-type classification `.qs` file.
#' @param file
#' A single readable `.qs` file path.
#' @return
#' A tibble with columns `taxon_name` and `functional_type`.
#' @export
read_functional_type_classification <- function(file) {
  assertthat::assert_that(
    base::is.character(file) &&
      base::length(file) == 1L &&
      assertthat::is.readable(file) &&
      assertthat::has_extension(file, "qs"),
    msg = "`file` must be a single readable `.qs` file."
  )

  data_ft <-
    qs2::qs_read(file = file)

  assertthat::assert_that(
    base::is.data.frame(data_ft) &&
      base::all(
        base::c("taxon_name", "functional_type") %in%
          base::colnames(data_ft)
      ),
    msg = stringr::str_c(
      "`file` must contain columns `taxon_name` and ",
      "`functional_type`."
    )
  )

  res <-
    data_ft |>
    dplyr::select(
      dplyr::all_of(
        base::c("taxon_name", "functional_type")
      )
    )

  return(res)
}

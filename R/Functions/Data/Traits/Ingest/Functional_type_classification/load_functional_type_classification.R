#' @title Load Functional-Type Classification
#' @description
#' Reads an explicit functional-type classification `.qs` file.
#' @param path_classification_file
#' A single readable `.qs` file path.
#' @return
#' A tibble with columns `taxon_name` and `functional_type`.
#' @export
load_functional_type_classification <- function(path_classification_file) {
  assertthat::assert_that(
    base::is.character(path_classification_file) &&
      base::length(path_classification_file) == 1L &&
      assertthat::is.readable(path_classification_file) &&
      assertthat::has_extension(path_classification_file, "qs"),
    msg = "`path_classification_file` must be a single readable `.qs` file."
  )

  data_functional_type_classification <-
    qs2::qs_read(file = path_classification_file)

  assertthat::assert_that(
    base::is.data.frame(data_functional_type_classification) &&
      base::all(
        base::c("taxon_name", "functional_type") %in%
          base::colnames(data_functional_type_classification)
      ),
    msg = stringr::str_c(
      "`path_classification_file` must contain columns `taxon_name` and ",
      "`functional_type`."
    )
  )

  data_functional_type_classification <-
    data_functional_type_classification |>
    dplyr::select(
      dplyr::all_of(
        base::c("taxon_name", "functional_type")
      )
    )

  return(data_functional_type_classification)
}

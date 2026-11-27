#' @title Get ORACLE continuous palette colours
#' @description Returns the four gradient stop colours used for continuous
#'   scales.
#' @return A named character vector of four colour values.
#' @examples
#' \dontrun{
#' build_oracle_continuous_palette()
#' }
build_oracle_continuous_palette <- function() {
  return(
    load_oracle_palette_values(
      base::c("surface_alt", "cyan", "phosphor", "amber")
    )
  )
}

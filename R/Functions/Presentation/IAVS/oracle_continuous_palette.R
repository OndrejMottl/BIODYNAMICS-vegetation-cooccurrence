#' @title Get ORACLE continuous palette colours
#' @description Returns the four gradient stop colours used for continuous
#'   scales.
#' @return A named character vector of four colour values.
#' @examples
#' \dontrun{
#' oracle_continuous_palette()
#' }
oracle_continuous_palette <- function() {
  return(
    oracle_palette_values(
      base::c("surface_alt", "cyan", "phosphor", "amber")
    )
  )
}

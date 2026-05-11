#' @title Get MOTHER continuous palette colours
#' @description Returns the four gradient stop colours used for continuous
#'   scales.
#' @return A named character vector of four colour values.
#' @examples
#' \dontrun{
#' mother_continuous_palette()
#' }
mother_continuous_palette <- function() {
  return(
    mother_palette_values(
      base::c("surface_alt", "cyan", "phosphor", "amber")
    )
  )
}

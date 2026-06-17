#' @title Get ORACLE continuous palette colours
#' @description Returns the four gradient stop colours used for continuous
#'   scales.
#' @return A named character vector of four colour values.
#' @examples
#' \dontrun{
#' get_oracle_continuous_palette()
#' }
get_oracle_continuous_palette <- function() {
  return(
    get_oracle_palette_values(
      base::c("surface_alt", "cyan", "phosphor", "amber")
    )
  )
}

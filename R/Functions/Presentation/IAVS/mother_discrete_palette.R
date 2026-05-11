#' @title Get MOTHER discrete palette colours
#' @description Returns the six categorical colours used for discrete
#'   scales.
#' @return A named character vector of six colour values.
#' @examples
#' \dontrun{
#' mother_discrete_palette()
#' }
mother_discrete_palette <- function() {
  return(
    mother_palette_values(
      base::c("phosphor", "cyan", "amber", "red", "muted", "text")
    )
  )
}

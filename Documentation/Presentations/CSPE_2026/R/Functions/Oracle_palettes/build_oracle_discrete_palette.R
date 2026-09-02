#' @title Get ORACLE discrete palette colours
#' @description Returns the six categorical colours used for discrete
#'   scales.
#' @return A named character vector of six colour values.
#' @examples
#' \dontrun{
#' build_oracle_discrete_palette()
#' }
build_oracle_discrete_palette <- function() {
  return(
    load_oracle_palette_values(
      base::c("phosphor", "cyan", "amber", "red", "muted", "text")
    )
  )
}

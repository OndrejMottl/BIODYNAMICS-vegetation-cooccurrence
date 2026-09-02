#' @title Format Age Label
#' @description
#' Formats age in years before present into a `ka BP` label.
#' @param age
#' Numeric scalar age value in years before present.
#' @return
#' Character scalar label in the form `<age_ka> ka BP`.
#' @examples
#' format_age_label(2000)
#' @export
format_age_label <- function(age) {
  assertthat::assert_that(
    base::is.numeric(age),
    base::length(age) == 1L,
    base::is.finite(age),
    msg = "'age' must be one finite numeric value."
  )

  res_label <-
    base::as.character(
      stringr::str_glue(
        "{base::sprintf('%.1f', age / 1000)} ka BP"
      )
    )

  return(res_label)
}

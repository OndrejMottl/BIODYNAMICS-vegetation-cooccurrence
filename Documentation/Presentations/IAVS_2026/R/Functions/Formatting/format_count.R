#' @title Format Count Values
#' @description
#' Formats numeric count values for slide text and figure labels using
#' grouping separators.
#' @param x
#' Numeric vector of values to format.
#' @param accuracy
#' Numeric scalar passed to [scales::number()] to control rounding.
#' @param big_mark
#' Character scalar used as the thousands separator.
#' @return
#' Character vector with formatted count values.
#' @examples
#' format_count(12345)
#' @export
format_count <- function(
    x,
    accuracy = 1,
    big_mark = ",") {
  assertthat::assert_that(
    base::is.numeric(x),
    msg = "'x' must be numeric."
  )

  assertthat::assert_that(
    base::is.numeric(accuracy),
    base::length(accuracy) == 1L,
    base::is.finite(accuracy),
    accuracy > 0,
    msg = "'accuracy' must be one positive numeric value."
  )

  assertthat::assert_that(
    base::is.character(big_mark),
    base::length(big_mark) == 1L,
    msg = "'big_mark' must be one character value."
  )

  res_count <-
    scales::number(
      x = x,
      accuracy = accuracy,
      big.mark = big_mark,
      trim = TRUE
    )

  return(res_count)
}

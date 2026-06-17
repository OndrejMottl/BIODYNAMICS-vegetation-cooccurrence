#' @title Generate ORACLE QR Code
#' @description
#' Generates a QR code SVG for a URL in ORACLE colours and optionally
#' returns a knitr graphics include object.
#' @param url
#' Character scalar URL encoded in the QR code.
#' @param name
#' Character scalar used in output file name (`qr_<name>.svg`).
#' @param background_color
#' Character scalar. Background colour passed to [qrcode::generate_svg()].
#' @param foreground_color
#' Character scalar. Foreground colour passed to [qrcode::generate_svg()].
#' @param plot
#' Logical scalar. If `TRUE`, returns [knitr::include_graphics()].
#' @param base_path
#' Character scalar output directory for SVG files.
#' @return
#' Character path to generated SVG when `plot = FALSE`, otherwise the
#' object returned by [knitr::include_graphics()].
#' @export
generate_qr_code <- function(
    url,
    name,
    background_color,
    foreground_color,
    plot,
    base_path = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "figures",
      "qrcodes"
    )) {
  assertthat::assert_that(
    base::is.character(url),
    base::length(url) == 1L,
    base::nchar(url) > 0L,
    msg = "'url' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.character(name),
    base::length(name) == 1L,
    base::nchar(name) > 0L,
    msg = "'name' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.character(background_color),
    base::length(background_color) == 1L,
    base::is.character(foreground_color),
    base::length(foreground_color) == 1L,
    msg = paste(
      "'background_color' and 'foreground_color' must each",
      "be one character value."
    )
  )

  assertthat::assert_that(
    assertthat::is.flag(plot),
    msg = "'plot' must be TRUE or FALSE."
  )

  base::dir.create(
    path = base_path,
    showWarnings = FALSE,
    recursive = TRUE
  )

  path_output <-
    stringr::str_glue(
      "{base_path}/qr_{name}.svg"
    )

  qr_code <-
    qrcode::qr_code(
      url,
      ecl = "H"
    )

  qrcode::generate_svg(
    qrcode = qr_code,
    filename = path_output,
    foreground = foreground_color,
    background = background_color
  )

  res <-
    if (
      isTRUE(plot)
    ) {
      knitr::include_graphics(path_output)
    } else {
      path_output
    }

  return(res)
}

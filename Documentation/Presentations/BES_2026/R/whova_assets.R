#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Whova images for the BES 2026 online talk
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds the images requested by the Whova ePresentation form from the
#   rendered deck: a cover photo (800 x 450 px), a logo banner
#   (700 x 210 px) and full-size photos of key slides. Run after
#   R/render.R; needs decktape on the PATH.

here::i_am("Documentation/Presentations/BES_2026/R/whova_assets.R")


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

path_presentation <-
  here::here("Documentation/Presentations/BES_2026")

path_output_html <-
  base::file.path(path_presentation, "_output", "index.html")

dir_whova <-
  base::file.path(path_presentation, "_output", "whova")

dir_screenshots <-
  base::file.path(dir_whova, "screenshots")

base::dir.create(
  path = dir_screenshots,
  showWarnings = FALSE,
  recursive = TRUE
)

# Slide numbers in the rendered deck (decktape counts from 1); the
#   equal-taxa slide is one of the extra slides.
vec_photo_slides <-
  base::c(
    "title" = 1L,
    "spatial_results" = 11L,
    "taxonomic_resolution" = 13L,
    "temporal_trajectories" = 16L,
    "matrix_size" = 18L,
    "take_home" = 20L,
    "equal_taxa" = 27L
  )

colour_background <- "#010301"


#----------------------------------------------------------#
# 1. Screenshot slides -----
#----------------------------------------------------------#

url_deck <-
  stringr::str_c(
    "file:///",
    base::chartr(old = "\\", new = "/", x = path_output_html),
    "?pdf-static=true"
  )

vec_status <-
  base::system2(
    command = "decktape.cmd",
    args = base::c(
      "reveal",
      "--size", "1600x900",
      "--screenshots",
      "--screenshots-directory", dir_screenshots,
      "--screenshots-size", "1600x900",
      "--slides", stringr::str_c(vec_photo_slides, collapse = ","),
      url_deck,
      base::file.path(dir_screenshots, "selected_slides.pdf")
    )
  )

if (
  !base::identical(vec_status, 0L)
) {
  cli::cli_abort("decktape failed while taking slide screenshots.")
}

vec_screenshot_files <-
  base::list.files(
    path = dir_screenshots,
    pattern = "[.]png$",
    full.names = TRUE
  )

# decktape names screenshots by slide number (..._<n>_1600x900.png).
data_screenshots <-
  tibble::tibble(
    file = vec_screenshot_files,
    slide = base::as.integer(
      stringr::str_match(
        string = base::basename(vec_screenshot_files),
        pattern = "_([0-9]+)_1600x900[.]png$"
      )[, 2]
    )
  ) |>
  dplyr::filter(!base::is.na(.data[["slide"]]))


#----------------------------------------------------------#
# 2. Cover photo and slide photos -----
#----------------------------------------------------------#

purrr::iwalk(
  .x = vec_photo_slides,
  .f = ~ {
    file_source <-
      data_screenshots |>
      dplyr::filter(.data[["slide"]] == .x) |>
      dplyr::pull("file")

    if (
      base::length(file_source) != 1L
    ) {
      cli::cli_abort("No screenshot found for slide {.x}.")
    }

    image_slide <-
      magick::image_read(file_source)

    magick::image_write(
      image = image_slide,
      path = base::file.path(
        dir_whova,
        stringr::str_glue("photo_{sprintf('%02d', .x)}_{.y}.png")
      ),
      format = "png"
    )

    if (
      .y == "title"
    ) {
      magick::image_write(
        image = magick::image_resize(image_slide, "800x450!"),
        path = base::file.path(dir_whova, "cover_800x450.png"),
        format = "png"
      )
    }
  }
)


#----------------------------------------------------------#
# 3. Logo banner -----
#----------------------------------------------------------#

vec_logo_files <-
  here::here(
    "Documentation/Materials/Logos",
    base::c("BIODYNAMICS.png", "VegVault_logo.png", "loqe_logo_nobg.jpg")
  )

list_logos <-
  vec_logo_files |>
  purrr::map(
    .f = ~ magick::image_read(.x) |>
      magick::image_resize("180x180") |>
      magick::image_background(colour_background)
  )

image_logo_row <-
  list_logos |>
  purrr::map(
    .f = ~ magick::image_border(.x, colour_background, "20x0")
  ) |>
  magick::image_join() |>
  magick::image_append()

image_banner <-
  magick::image_blank(
    width = 700,
    height = 210,
    color = colour_background
  ) |>
  magick::image_composite(
    composite_image = image_logo_row,
    gravity = "center"
  )

magick::image_write(
  image = image_banner,
  path = base::file.path(dir_whova, "logo_700x210.png"),
  format = "png"
)

cli::cli_inform("Whova images written to {.path {dir_whova}}.")


#----------------------------------------------------------#
# 4. Handout PDF under 10 MB -----
#----------------------------------------------------------#

# Whova accepts PDFs of at most 10 MB; the decktape PDF is larger because
#   the terminal effects are rasterised. The handout holds the main slides
#   (not the extra slides) as JPEG pages, so its text is not searchable;
#   the full searchable PDF is published on the project website.
file_deck_pdf <-
  base::file.path(path_presentation, "_output", "bes_2026_presentation.pdf")

n_main_slides <- 24L

vec_page_size <-
  pdftools::pdf_pagesize(file_deck_pdf)[1, ]

dpi_handout <-
  1600 / (vec_page_size[["width"]] / 72)

list_handout_pages <-
  base::seq_len(n_main_slides) |>
  purrr::map(
    .f = ~ pdftools::pdf_render_page(
      pdf = file_deck_pdf,
      page = .x,
      dpi = dpi_handout
    ) |>
      magick::image_read()
  )

magick::image_write(
  image = magick::image_join(list_handout_pages),
  path = base::file.path(dir_whova, "bes_2026_handout.pdf"),
  format = "pdf",
  compression = "JPEG",
  quality = 80
)

size_handout_mb <-
  base::file.size(
    base::file.path(dir_whova, "bes_2026_handout.pdf")
  ) / 1e6

cli::cli_inform(
  "Handout size: {base::round(size_handout_mb, 1)} MB."
)

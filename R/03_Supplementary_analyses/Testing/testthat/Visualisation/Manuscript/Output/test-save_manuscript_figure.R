testthat::test_that(
  "save_manuscript_figure() writes PDF TIFF and PNG outputs",
  {
    path_output <-
      withr::local_tempdir()
    file_base <-
      base::file.path(path_output, "test_figure")
    plot_test <-
      ggplot2::ggplot(
        tibble::tibble(x = 1:2, y = 1:2),
        ggplot2::aes(x = .data$x, y = .data$y)
      ) +
      ggview::canvas(
        width = 40,
        height = 30,
        units = "mm",
        dpi = 72,
        bg = "white"
      ) +
      ggplot2::geom_point()
    graphical_options <-
      base::list(
        width = 40,
        height = 30,
        units = "mm",
        dpi = 72,
        bg = "white",
        panel_scale = 1
      )

    vec_files <-
      save_manuscript_figure(
        plot = plot_test,
        file_base = file_base,
        graphical_options = graphical_options
      )

    testthat::expect_named(vec_files, base::c("pdf", "tiff", "png"))
    testthat::expect_true(base::all(base::file.exists(vec_files)))
    testthat::expect_true(
      base::all(base::file.info(vec_files)[["size"]] > 0)
    )
  }
)

testthat::test_that(
  "save_manuscript_figure() requires an extension-free base path",
  {
    plot_test <-
      ggplot2::ggplot() +
      ggplot2::geom_blank()

    testthat::expect_error(
      save_manuscript_figure(
        plot = plot_test,
        file_base = "figure.png",
        graphical_options = base::list(
          bg = "white"
        )
      ),
      "without a file extension"
    )
  }
)

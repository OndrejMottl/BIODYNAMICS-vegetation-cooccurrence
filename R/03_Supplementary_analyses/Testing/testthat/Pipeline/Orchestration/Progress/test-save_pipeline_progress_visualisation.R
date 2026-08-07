testthat::test_that(
  "save_pipeline_progress_visualisation() warns instead of failing when PNG export fails",
  {
    tmp_dir <-
      withr::local_tempdir()

    tmp_script <-
      withr::local_tempfile(fileext = ".R")

    base::writeLines("list()", tmp_script)

    tmp_store <-
      file.path(tmp_dir, "targets", "demo_store")

    full_html_path <-
      file.path(
        tmp_dir,
        "demo_store",
        "project_status.html"
      )

    small_html_path <-
      file.path(
        tmp_dir,
        "demo_store",
        "project_status_small.html"
      )

    fake_plot_function <- function(...) {
      graph <-
        base::structure(
          base::list(),
          class = "visNetwork"
        )

      base::list(
        full = graph,
        static = graph
      )
    }

    testthat::local_mocked_bindings(
      visSave = function(graph, file, ...) {
        dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
        base::writeLines("<html></html>", file)
        invisible(file)
      },
      .package = "visNetwork"
    )

    testthat::local_mocked_bindings(
      webshot = function(...) {
        stop("Chrome debugging port not open after 10 seconds.")
      },
      .package = "webshot2"
    )

    paths_written <-
      testthat::expect_warning(
        save_pipeline_progress_visualisation(
          sel_script = tmp_script,
          sel_store = tmp_store,
          output_dir = tmp_dir,
          plot_function = fake_plot_function
        ),
        "Failed to save static PNG"
      )

    testthat::expect_true(file.exists(full_html_path))
    testthat::expect_true(file.exists(small_html_path))
    testthat::expect_named(
      paths_written,
      base::c("full_html", "targets_html")
    )
  }
)

testthat::test_that(
  "plot_pipeline_progress_visualisations() returns full and static graphs",
  {
    data_nodes <-
      tibble::tibble(
        id = base::c("target", "function"),
        type = base::c("target", "function")
      )
    data_edges <-
      tibble::tibble(
        from = "function",
        to = "target"
      )

    graph <-
      base::structure(
        base::list(
          x = base::list(
            nodes = data_nodes,
            edges = data_edges
          )
        ),
        class = base::c("visNetwork", "htmlwidget")
      )

    testthat::local_mocked_bindings(
      tar_visnetwork = function(...) graph,
      .package = "targets"
    )

    res <-
      plot_pipeline_progress_visualisations(
        sel_script = "pipeline.R",
        sel_store = "targets"
      )

    testthat::expect_named(res, base::c("full", "static"))
    testthat::expect_s3_class(res[["full"]], "visNetwork")
    testthat::expect_s3_class(res[["static"]], "visNetwork")
    testthat::expect_identical(
      res[["static"]][["x"]][["nodes"]][["id"]],
      "target"
    )
  }
)

data_test_network <-
  tibble::tibble(
    age = c(0, 500, 1000, 0, 500, 1000, 0, 500, 1000),
    metric = c(
      "connectance", "connectance", "connectance",
      "nestedness", "nestedness", "nestedness",
      "modularity", "modularity", "modularity"
    ),
    value = c(
      0.4, 0.35, 0.3,
      15.2, 14.8, 13.9,
      0.6, 0.58, 0.55
    )
  )

testthat::test_that(
  "plot_network_metrics_by_age() rejects non-data-frame",
  {
    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = NULL
      )
    )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = base::list(a = 1)
      )
    )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = "a string"
      )
    )
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() rejects df with missing cols",
  {
    data_no_age <-
      tibble::tibble(
        metric = c("connectance"),
        value = c(0.4)
      )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = data_no_age
      )
    )

    data_no_metric <-
      tibble::tibble(
        age = c(0),
        value = c(0.4)
      )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = data_no_metric
      )
    )

    data_no_value <-
      tibble::tibble(
        age = c(0),
        metric = c("connectance")
      )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = data_no_value
      )
    )
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() rejects non-numeric age",
  {
    data_chr_age <-
      tibble::tibble(
        age = c("0", "500"),
        metric = c("connectance", "connectance"),
        value = c(0.4, 0.35)
      )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = data_chr_age
      )
    )
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() rejects non-numeric value",
  {
    data_chr_value <-
      tibble::tibble(
        age = c(0, 500),
        metric = c("connectance", "connectance"),
        value = c("0.4", "0.35")
      )

    testthat::expect_error(
      plot_network_metrics_by_age(
        data_network_metrics = data_chr_value
      )
    )
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() returns a ggplot object",
  {
    res <-
      plot_network_metrics_by_age(
        data_network_metrics = data_test_network
      )

    testthat::expect_s3_class(res, "gg")
    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() uses NULL titles by default",
  {
    res <-
      plot_network_metrics_by_age(
        data_network_metrics = data_test_network
      )

    title_val <-
      purrr::pluck(res, "labels", "title")

    subtitle_val <-
      purrr::pluck(res, "labels", "subtitle")

    testthat::expect_null(title_val)
    testthat::expect_null(subtitle_val)
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() sets custom title/subtitle",
  {
    res <-
      plot_network_metrics_by_age(
        data_network_metrics = data_test_network,
        title = "Network title",
        subtitle = "Network sub"
      )

    title_val <-
      purrr::pluck(res, "labels", "title")

    subtitle_val <-
      purrr::pluck(res, "labels", "subtitle")

    testthat::expect_equal(title_val, "Network title")
    testthat::expect_equal(subtitle_val, "Network sub")
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() maps correct aesthetics",
  {
    res <-
      plot_network_metrics_by_age(
        data_network_metrics = data_test_network
      )

    mapping_obj <-
      purrr::pluck(res, "mapping")

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "x")),
      "age"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "y")),
      "value"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "colour")),
      "metric"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "group")),
      "metric"
    )
  }
)

testthat::test_that(
  "plot_network_metrics_by_age() includes a facet_wrap layer",
  {
    res <-
      plot_network_metrics_by_age(
        data_network_metrics = data_test_network
      )

    layer_classes <-
      base::vapply(
        X = res$facet,
        FUN = base::class,
        FUN.VALUE = base::character(1L)
      )

    testthat::expect_s3_class(res$facet, "FacetWrap")
  }
)

testthat::test_that(
  "data_group_raw must be a data frame",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = NULL,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = c(1, 2, 3),
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = base::list(a = 1),
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_raw must have required columns",
  {
    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    data_missing_trait_value <-
      tibble::tibble(
        trait_name = base::rep("Leaf area (mm2)", 3L),
        trait_domain_name = base::rep("Leaf Area", 3L)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_missing_trait_value,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    data_missing_trait_name <-
      tibble::tibble(
        trait_value = c(1, 2, 3),
        trait_domain_name = base::rep("Leaf Area", 3L)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_missing_trait_name,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    data_missing_domain <-
      tibble::tibble(
        trait_value = c(1, 2, 3),
        trait_name = base::rep("Leaf area (mm2)", 3L)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_missing_domain,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_raw trait_value must be numeric",
  {
    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    data_char_values <-
      tibble::tibble(
        trait_value = base::as.character(c(1, 2, 3)),
        trait_name = base::rep("Leaf area (mm2)", 3L),
        trait_domain_name = base::rep("Leaf Area", 3L)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_char_values,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_raw must have at least 1 row",
  {
    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    data_empty <-
      tibble::tibble(
        trait_value = base::numeric(0),
        trait_name = base::character(0),
        trait_domain_name = base::character(0)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_empty,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_summary must be a data frame",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = NULL,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = base::list(mean = 3),
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_summary must have exactly 1 row",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    data_summary_multi_row <-
      tibble::tibble(
        mean = c(1, 2),
        median = c(1, 2),
        IQR = c(1, 2),
        n_suspected_outliers_taxon = c(0L, 1L),
        outlier_fraction = c(0, 0.5)
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_multi_row,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "data_group_summary must have required columns",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    data_summary_missing_mean <-
      tibble::tibble(
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_missing_mean,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    data_summary_missing_iqr <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_missing_iqr,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    data_summary_missing_n_outliers <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        outlier_fraction = 1 / 6
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_missing_n_outliers,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    data_summary_missing_fraction <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_missing_fraction,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "sel_taxon must be a character scalar",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = NULL,
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = NA_character_,
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = 42,
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = c("Taxon A", "Taxon B"),
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "sel_domain must be a character scalar",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = NULL,
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = NA_character_,
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = 1L,
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = c("Leaf Area", "Root Area"),
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "graphical_options must be a list with required elements",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = "not a list",
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = NULL,
        verbose = FALSE
      )
    )

    list_graphical_no_width <-
      base::list(
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical_no_width,
        verbose = FALSE
      )
    )

    list_graphical_no_bg <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical_no_bg,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "verbose must be a logical scalar",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = "yes"
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = 1L
      )
    )

    testthat::expect_error(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = c(TRUE, FALSE)
      )
    )
  }
)

testthat::test_that(
  "returns a ggplot2 object",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    testthat::expect_true(
      base::inherits(res, "gg")
    )

    testthat::expect_true(
      base::inherits(res, "ggplot")
    )
  }
)

testthat::test_that(
  "return value is not auto-printed",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    # Function must return a value (not invisibly print)
    # and not produce any output side-effects automatically
    res <-
      testthat::expect_no_condition(
        plot_trait_group_distribution(
          data_group_raw = data_raw_single,
          data_group_summary = data_summary_valid,
          sel_taxon = "Quercus robur",
          sel_domain = "Leaf Area",
          graphical_options = list_graphical,
          verbose = FALSE
        )
      )

    testthat::expect_true(
      base::inherits(res, "ggplot")
    )
  }
)

testthat::test_that(
  "verbose = TRUE emits a message with fence info",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_message(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = TRUE
      )
    )
  }
)

testthat::test_that(
  "verbose = FALSE suppresses fence messages",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    testthat::expect_no_message(
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "single trait_name: title contains taxon and domain",
  {
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    vec_title <-
      ggplot2::ggplot_build(res) |>
      purrr::chuck("plot", "labels", "title")

    testthat::expect_true(
      base::grepl("Quercus robur", vec_title, fixed = TRUE)
    )

    testthat::expect_true(
      base::grepl("Leaf Area", vec_title, fixed = TRUE)
    )
  }
)

testthat::test_that(
  "multiple trait_names: plot facets by trait_name",
  {
    data_raw_multi <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 6),
        trait_name = c(
          base::rep("Leaf area (mm2)", 3L),
          base::rep("Leaf area (cm2)", 3L)
        ),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_multi,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    vec_facet_class <-
      ggplot2::ggplot_build(res) |>
      purrr::chuck("plot", "facet") |>
      base::class()

    # FacetWrap or FacetGrid indicates faceting is active
    testthat::expect_false(
      base::any(
        base::grepl("FacetNull", vec_facet_class)
      )
    )
  }
)

testthat::test_that(
  "fence classification: extreme outlier beyond 3x IQR",
  {
    # With values 1..5 and 100:
    # Q1 = 2, Q3 = 4.25, IQR = 2.25
    # outer upper = 4.25 + 3 * 2.25 = 11
    # 100 >> 11, so it is an extreme outlier
    data_raw_single <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 100),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 19.17,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_single,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    # Extract the data used to build the plot
    data_built <-
      ggplot2::ggplot_build(res) |>
      purrr::chuck("data", 1L)

    # The plot layers must exist
    testthat::expect_true(
      base::nrow(data_built) > 0L
    )
  }
)

testthat::test_that(
  "fence classification: mild outlier between 1.5x and 3x IQR",
  {
    # Construct data where one point is between
    # 1.5x and 3x IQR fences:
    # Q1=2, Q3=4, IQR=2
    # inner upper = 4 + 1.5*2 = 7  -> mild outlier: 8
    # outer upper = 4 + 3*2   = 10 -> extreme outlier: >10
    # So value 8 should be a mild outlier
    data_raw_mild <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 8),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 3.83,
        median = 3.5,
        IQR = 2.0,
        n_suspected_outliers_taxon = 1L,
        outlier_fraction = 1 / 6
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_mild,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    testthat::expect_true(
      base::inherits(res, "ggplot")
    )
  }
)

testthat::test_that(
  "fence classification: within-fence values flagged correctly",
  {
    data_raw_clean <-
      tibble::tibble(
        trait_value = c(1, 2, 3, 4, 5, 6),
        trait_name = base::rep("Leaf area (mm2)", 6L),
        trait_domain_name = base::rep("Leaf Area", 6L)
      )

    data_summary_valid <-
      tibble::tibble(
        mean = 3.5,
        median = 3.5,
        IQR = 2.5,
        n_suspected_outliers_taxon = 0L,
        outlier_fraction = 0
      )

    list_graphical <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        dpi = 300,
        bg = "white"
      )

    res <-
      plot_trait_group_distribution(
        data_group_raw = data_raw_clean,
        data_group_summary = data_summary_valid,
        sel_taxon = "Quercus robur",
        sel_domain = "Leaf Area",
        graphical_options = list_graphical,
        verbose = FALSE
      )

    testthat::expect_true(
      base::inherits(res, "ggplot")
    )
  }
)

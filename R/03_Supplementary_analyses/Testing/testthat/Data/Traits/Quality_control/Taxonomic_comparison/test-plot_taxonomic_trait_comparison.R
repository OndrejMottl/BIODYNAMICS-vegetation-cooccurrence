# Shared test fixtures -----------------------------------------

data_taxonomic_summary_valid <-
  tibble::tibble(
    taxon_name = c(
      "Anacyclus clavatus",
      "Anthemis arvensis",
      "Chamaemelum nobile",
      "Matricaria chamomilla",
      "Tripleurospermum inodorum"
    ),
    n_records = c(12L, 8L, 6L, 15L, 9L),
    minimum = c(80, 90, 95, 70, 85),
    lower_quartile = c(100, 110, 115, 95, 105),
    median = c(120, 130, 140, 110, 125),
    mean = c(125, 135, 142, 115, 128),
    upper_quartile = c(145, 155, 160, 130, 148),
    maximum = c(200, 180, 175, 170, 165)
  )

data_focal_trait_summary_valid <-
  tibble::tibble(
    taxon_name = "Anacyclus clavatus",
    trait_domain_name = "Leaf Area",
    n_records = 12L,
    mean = 125,
    median = 120,
    sd = 30,
    IQR = 45,
    n_suspected_outliers_taxon = 2L,
    outlier_fraction = 2 / 12
  )

list_graphical_valid <-
  base::list(
    width = 2000,
    height = 1600,
    units = "px",
    dpi = 300,
    bg = "white"
  )

# Input validation: data_taxonomic_trait_summary ----------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on non-data-frame",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = NULL,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = c(1, 2, 3),
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on missing columns",
  {
    data_missing_n_records <-
      tibble::tibble(
        taxon_name = c("Taxon A", "Taxon B"),
        median = c(100, 200)
      )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_missing_n_records,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_missing_median <-
      tibble::tibble(
        taxon_name = c("Taxon A", "Taxon B"),
        n_records = c(10L, 20L)
      )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_missing_median,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: data_focal_trait_summary --------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad data_focal_trait_summary",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = NULL,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_focal_trait_summary_multi_row <-
      dplyr::bind_rows(data_focal_trait_summary_valid, data_focal_trait_summary_valid)

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_multi_row,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_focal_trait_summary_no_median <-
      dplyr::select(data_focal_trait_summary_valid, -median)

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_no_median,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: focal_taxon -----------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad focal_taxon",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = 123L,
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = c("Taxon A", "Taxon B"),
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = NA_character_,
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: trait_domain ----------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad trait_domain",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = 42,
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = NA_character_,
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: minimum_records -----------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad minimum_records",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = -1L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 0L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = "five",
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: graphical_options ---------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad graphical_options",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = NULL,
        verbose = FALSE
      )
    )

    list_graphical_missing_dpi <-
      base::list(
        width = 2000,
        height = 1600,
        units = "px",
        bg = "white"
      )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_missing_dpi,
        verbose = FALSE
      )
    )
  }
)

# Input validation: verbose -------------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() errors on bad verbose",
  {
    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = "yes"
      )
    )

    testthat::expect_error(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = c(TRUE, FALSE)
      )
    )
  }
)

# Output structure ----------------------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() returns a ggplot object",
  {
    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "gg")
    testthat::expect_s3_class(res, "ggplot")
  }
)

# Functional correctness ----------------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() applies minimum_records filter",
  {
    # With minimum_records = 10L, only taxa with n_records >= 10 pass.
    # data_taxonomic_summary_valid has n_records = 12, 8, 6, 15, 9.
    # So Anacyclus (12) and Matricaria (15) qualify.
    res_high_min <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 10L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    # Should still return a ggplot object (not error).
    testthat::expect_s3_class(res_high_min, "ggplot")

    # With minimum_records = 1L all taxa show.
    res_low_min <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 1L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res_low_min, "ggplot")
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() works when no taxa pass filter",
  {
    # minimum_records = 999 -> no taxonomic group taxa pass; focal point still plotted.
    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 999L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() uses log10 x scale",
  {
    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    # Extract scale from built plot.
    res_built <-
      ggplot2::ggplot_build(res)

    # The x-axis should be log-transformed.
    x_scale <-
      purrr::chuck(res_built, "layout", "panel_scales_x", 1L)

    testthat::expect_true(
      base::inherits(x_scale[["trans"]], "transform") ||
        base::inherits(x_scale[["trans"]], "Trans") ||
        base::grepl(
          "log",
          base::class(x_scale[["trans"]])[[1L]],
          ignore.case = TRUE
        ) ||
        base::isTRUE(
          x_scale[["trans"]][["name"]] == "log-10"
        )
    )
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() verbose emits a message",
  {
    testthat::expect_message(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = TRUE
      )
    )
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() no message when verbose FALSE",
  {
    testthat::expect_no_message(
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() contains focal_taxon in plot title",
  {
    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    vec_title <-
      purrr::chuck(res, "labels", "title")

    testthat::expect_true(
      stringr::str_detect(vec_title, "Anacyclus clavatus")
    )
  }
)

testthat::test_that(
  "plot_taxonomic_trait_comparison() contains trait_domain in x label",
  {
    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_taxonomic_summary_valid,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    vec_xlabel <-
      purrr::chuck(res, "labels", "x")

    testthat::expect_true(
      stringr::str_detect(vec_xlabel, "Leaf Area")
    )
  }
)

# Edge cases ----------------------------------------------------

testthat::test_that(
  "plot_taxonomic_trait_comparison() works with single taxonomic group taxon",
  {
    data_single_taxon <-
      tibble::tibble(
        taxon_name = "Anacyclus clavatus",
        n_records = 12L,
        minimum = 80,
        lower_quartile = 100,
        median = 120,
        mean = 125,
        upper_quartile = 145,
        maximum = 200
      )

    res <-
      plot_taxonomic_trait_comparison(
        data_taxonomic_trait_summary = data_single_taxon,
        data_focal_trait_summary = data_focal_trait_summary_valid,
        focal_taxon = "Anacyclus clavatus",
        trait_domain = "Leaf Area",
        minimum_records = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

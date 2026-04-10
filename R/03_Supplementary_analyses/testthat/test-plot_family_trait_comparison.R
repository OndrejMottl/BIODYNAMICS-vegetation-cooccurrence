# Shared test fixtures -----------------------------------------

data_family_valid <-
  tibble::tibble(
    taxon_name = c(
      "Anacyclus clavatus",
      "Anthemis arvensis",
      "Chamaemelum nobile",
      "Matricaria chamomilla",
      "Tripleurospermum inodorum"
    ),
    n = c(12L, 8L, 6L, 15L, 9L),
    min = c(80, 90, 95, 70, 85),
    q25 = c(100, 110, 115, 95, 105),
    median = c(120, 130, 140, 110, 125),
    mean = c(125, 135, 142, 115, 128),
    q75 = c(145, 155, 160, 130, 148),
    max = c(200, 180, 175, 170, 165)
  )

data_summary_valid <-
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

# Input validation: data_family_comparison ----------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on non-data-frame",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = NULL,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = c(1, 2, 3),
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "plot_family_trait_comparison() errors on missing columns",
  {
    data_missing_n <-
      tibble::tibble(
        taxon_name = c("Taxon A", "Taxon B"),
        median = c(100, 200)
      )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_missing_n,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_missing_median <-
      tibble::tibble(
        taxon_name = c("Taxon A", "Taxon B"),
        n = c(10L, 20L)
      )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_missing_median,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: data_group_summary --------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad data_group_summary",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = NULL,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_summary_multi_row <-
      dplyr::bind_rows(data_summary_valid, data_summary_valid)

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_multi_row,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    data_summary_no_median <-
      dplyr::select(data_summary_valid, -median)

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_no_median,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: sel_taxon -----------------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad sel_taxon",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = 123L,
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = c("Taxon A", "Taxon B"),
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = NA_character_,
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: sel_domain ----------------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad sel_domain",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = 42,
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = NA_character_,
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: sel_min_n -----------------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad sel_min_n",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = -1L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 0L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = "five",
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

# Input validation: graphical_options ---------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad graphical_options",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
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
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_missing_dpi,
        verbose = FALSE
      )
    )
  }
)

# Input validation: verbose -------------------------------------

testthat::test_that(
  "plot_family_trait_comparison() errors on bad verbose",
  {
    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = "yes"
      )
    )

    testthat::expect_error(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = c(TRUE, FALSE)
      )
    )
  }
)

# Output structure ----------------------------------------------

testthat::test_that(
  "plot_family_trait_comparison() returns a ggplot object",
  {
    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "gg")
    testthat::expect_s3_class(res, "ggplot")
  }
)

# Functional correctness ----------------------------------------

testthat::test_that(
  "plot_family_trait_comparison() applies sel_min_n filter",
  {
    # With sel_min_n = 10L, only taxa with n >= 10 pass.
    # data_family_valid has: n = 12, 8, 6, 15, 9
    # So Anacyclus (12) and Matricaria (15) qualify.
    res_high_min <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 10L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    # Should still return a ggplot object (not error).
    testthat::expect_s3_class(res_high_min, "ggplot")

    # With sel_min_n = 1L all taxa show.
    res_low_min <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 1L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res_low_min, "ggplot")
  }
)

testthat::test_that(
  "plot_family_trait_comparison() works when no taxa pass filter",
  {
    # sel_min_n = 999 -> no family taxa pass; focal point still plotted.
    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 999L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

testthat::test_that(
  "plot_family_trait_comparison() uses log10 x scale",
  {
    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
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
      base::inherits(x_scale$trans, "transform") ||
        base::inherits(x_scale$trans, "Trans") ||
        base::grepl(
          "log",
          base::class(x_scale$trans)[[1L]],
          ignore.case = TRUE
        ) ||
        base::isTRUE(
          x_scale$trans$name == "log-10"
        )
    )
  }
)

testthat::test_that(
  "plot_family_trait_comparison() verbose emits a message",
  {
    testthat::expect_message(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = TRUE
      )
    )
  }
)

testthat::test_that(
  "plot_family_trait_comparison() no message when verbose FALSE",
  {
    testthat::expect_no_message(
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "plot_family_trait_comparison() contains sel_taxon in plot title",
  {
    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
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
  "plot_family_trait_comparison() contains sel_domain in x label",
  {
    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_family_valid,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
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
  "plot_family_trait_comparison() works with single family taxon",
  {
    data_single_taxon <-
      tibble::tibble(
        taxon_name = "Anacyclus clavatus",
        n = 12L,
        min = 80,
        q25 = 100,
        median = 120,
        mean = 125,
        q75 = 145,
        max = 200
      )

    res <-
      plot_family_trait_comparison(
        data_family_comparison = data_single_taxon,
        data_group_summary = data_summary_valid,
        sel_taxon = "Anacyclus clavatus",
        sel_domain = "Leaf Area",
        sel_min_n = 5L,
        graphical_options = list_graphical_valid,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "ggplot")
  }
)

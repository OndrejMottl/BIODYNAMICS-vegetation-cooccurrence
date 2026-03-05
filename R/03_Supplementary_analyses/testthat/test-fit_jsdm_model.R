#----------------------------------------------------------#
# Input validation tests -----
#----------------------------------------------------------#

testthat::test_that(
  "fit_jsdm_model() validates data_to_fit must be a list",
  {
    testthat::expect_error(
      fit_jsdm_model(data_to_fit = "not a list"),
      "data_to_fit must be a list"
    )
    testthat::expect_error(
      fit_jsdm_model(data_to_fit = data.frame(a = 1)),
      "`data_to_fit` must be a list containing `data_community_to_fit`"
    )
    testthat::expect_error(
      fit_jsdm_model(data_to_fit = NULL),
      "data_to_fit must be a list"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates data_community must be a matrix",
  {
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = "not a matrix",
          data_abiotic_to_fit = data.frame(a = 1)
        )
      ),
      "data_community must be a matrix"
    )
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = data.frame(a = 1),
          data_abiotic_to_fit = data.frame(a = 1)
        )
      ),
      "data_community must be a matrix"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates data_abiotic must be a data.frame",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = "not a df"
        )
      ),
      "data_abiotic must be a data frame"
    )
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = c(1, 2, 3)
        )
      ),
      "data_abiotic must be a data frame"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates data_spatial must be a data.frame",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic,
          data_spatial_to_fit = "not a df"
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "linear"
      ),
      "data_spatial must be a data frame"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates data_spatial_to_fit required",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
          # data_spatial_to_fit missing
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "linear"
      ),
      "data_spatial_to_fit"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates sel_abiotic_formula must be a formula object",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = 123
      ),
      "sel_abiotic_formula must be a formula object"
    )
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = NULL
      ),
      "sel_abiotic_formula must be a formula object"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates sel_abiotic_formula length",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = c("formula1", "formula2")
      ),
      "sel_abiotic_formula must be a formula object"
    )
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = character(0)
      ),
      "sel_abiotic_formula must be a formula object"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates abiotic_method options",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        abiotic_method = "invalid_method"
      ),
      "abiotic_method must be either 'linear' or 'DNN'"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() validates error_family options",
  {
    mock_community <-
      data.frame(sp1 = c(1, 2, 3), sp2 = c(4, 5, 6))
    mock_abiotic <-
      data.frame(temp = c(10, 15, 20), precip = c(100, 200, 300))

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "poisson"
      ),
      "error_family must be either 'gaussian' or 'binomial'"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() handles NULL in data_to_fit correctly",
  {
    testthat::expect_error(
      fit_jsdm_model(data_to_fit = NULL),
      "data_to_fit must be a list"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() handles empty list in data_to_fit",
  {
    testthat::expect_error(
      fit_jsdm_model(data_to_fit = base::list()),
      "`data_to_fit` must be a list containing `data_community_to_fit`"
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() handles missing required list elements",
  {
    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(wrong_name = data.frame(a = 1))
      ),
      "`data_to_fit` must be a list containing `data_community_to_fit`"
    )
  }
)

#----------------------------------------------------------#
# Model output tests -----
#----------------------------------------------------------#

testthat::test_that(
  "fit_jsdm_model() returns sjSDM class with spatial linear",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(5.2, 3.1, 4.8, 2.9, 6.1),
        sp2 = c(2.3, 4.5, 3.2, 5.1, 1.9),
        sp3 = c(7.1, 4.2, 5.9, 3.8, 6.5)
      )
    mock_abiotic <-
      data.frame(
        temp = c(15.2, 18.3, 12.7, 20.1, 16.5),
        precip = c(850, 920, 780, 1050, 890)
      )
    mock_spatial <-
      data.frame(
        coord_x_km = c(-0.8, -0.4, 0.0, 0.4, 0.8),
        coord_y_km = c(-0.6, -0.3, 0.0, 0.3, 0.6)
      )

    result <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic,
          data_spatial_to_fit = mock_spatial
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        sel_spatial_formula = ~ 0 + coord_x_km + coord_y_km,
        abiotic_method = "linear",
        spatial_method = "linear",
        error_family = "gaussian",
        device = "cpu",
        sampling = 10L,
        step_size = 10L
      )

    testthat::expect_s3_class(result, "sjSDM")
  }
)

testthat::test_that(
  "fit_jsdm_model() accepts abiotic_method linear",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3),
        sp2 = c(4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20),
        precip = c(100, 200, 300)
      )

    testthat::expect_no_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        abiotic_method = "linear",
        spatial_method = "none",
        sampling = 5L,
        step_size = 5L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() accepts abiotic_method DNN",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3),
        sp2 = c(4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20)
      )

    testthat::expect_no_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        abiotic_method = "DNN",
        spatial_method = "none",
        sel_abiotic_formula = stats::as.formula("~ temp"),
        sampling = 5L,
        step_size = 5L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() converts binomial to presence/absence",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(5, 0, 3, 0, 7),
        sp2 = c(0, 8, 0, 4, 0)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30),
        precip = c(100, 200, 300, 400, 500)
      )

    result <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        sampling = 5L,
        step_size = 5L
      )

    testthat::expect_s3_class(result, "sjSDM")
  }
)

testthat::test_that(
  "fit_jsdm_model() accepts both cpu and gpu device options",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3),
        sp2 = c(4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20),
        precip = c(100, 200, 300)
      )

    testthat::expect_no_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        device = "gpu",
        sampling = 5L,
        step_size = 5L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() accepts custom sampling parameter",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3),
        sp2 = c(4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20),
        precip = c(100, 200, 300)
      )

    testthat::expect_no_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 100L,
        step_size = 10L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() accepts custom step_size parameter",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3),
        sp2 = c(4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20),
        precip = c(100, 200, 300)
      )

    testthat::expect_no_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 10L,
        step_size = 25L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() handles zero-row data frames",
  {
    mock_community <-
      data.frame(
        sp1 = numeric(0),
        sp2 = numeric(0)
      )
    mock_abiotic <-
      data.frame(
        temp = numeric(0),
        precip = numeric(0)
      )

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 5L,
        step_size = 5L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() handles single row data",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = 5,
        sp2 = 3
      )
    mock_abiotic <-
      data.frame(
        temp = 15,
        precip = 200
      )

    testthat::expect_error(
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 5L,
        step_size = 5L
      )
    )
  }
)

testthat::test_that(
  "fit_jsdm_model() returns object consistently",
  {
    testthat::skip_if_not_installed("sjSDM")

    mock_community <-
      data.frame(
        sp1 = c(1, 2, 3, 4, 5),
        sp2 = c(2, 3, 4, 5, 6)
      )
    mock_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30),
        precip = c(100, 200, 300, 400, 500)
      )

    set.seed(900723)
    result1 <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 5L,
        step_size = 5L
      )

    set.seed(900723)
    result2 <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(mock_community),
          data_abiotic_to_fit = mock_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        sampling = 5L,
        step_size = 5L
      )

    testthat::expect_s3_class(result1, "sjSDM")
    testthat::expect_s3_class(result2, "sjSDM")
  }
)

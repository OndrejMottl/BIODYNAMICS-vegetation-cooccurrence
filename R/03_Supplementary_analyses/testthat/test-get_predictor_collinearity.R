testthat::test_that(
  "get_predictor_collinearity() validates data_source type",
  {
    testthat::expect_error(
      get_predictor_collinearity(NULL),
      regexp = "data_source must be a data frame"
    )

    testthat::expect_error(
      get_predictor_collinearity(list(
        abiotic_variable_name = "temp",
        abiotic_value = 10
      )),
      regexp = "data_source must be a data frame"
    )

    testthat::expect_error(
      get_predictor_collinearity(1:5),
      regexp = "data_source must be a data frame"
    )
  }
)


testthat::test_that(
  "get_predictor_collinearity() validates required columns",
  {
    # Missing abiotic_value
    testthat::expect_error(
      get_predictor_collinearity(
        data.frame(abiotic_variable_name = "temp")
      ),
      regexp = "abiotic_variable_name.*abiotic_value"
    )

    # Missing abiotic_variable_name
    testthat::expect_error(
      get_predictor_collinearity(
        data.frame(abiotic_value = 10)
      ),
      regexp = "abiotic_variable_name.*abiotic_value"
    )

    # Neither column present
    testthat::expect_error(
      get_predictor_collinearity(
        data.frame(x = 1, y = 2)
      ),
      regexp = "abiotic_variable_name.*abiotic_value"
    )
  }
)


testthat::test_that(
  "get_predictor_collinearity() returns a collinear_output object",
  {
    set.seed(900723)

    data_source <-
      data.frame(
        sample_name = rep(seq_len(30), each = 3),
        abiotic_variable_name = rep(
          c("temp", "precip", "rad"), 30
        ),
        abiotic_value = c(
          stats::rnorm(30, mean = 15, sd = 3),
          stats::rnorm(30, mean = 500, sd = 50),
          stats::rnorm(30, mean = 200, sd = 20)
        )
      )

    res <-
      get_predictor_collinearity(
        data_source = data_source
      )

    testthat::expect_s3_class(res, "collinear_output")
  }
)


testthat::test_that(
  "get_predictor_collinearity() output contains result$selection",
  {
    set.seed(900723)

    data_source <-
      data.frame(
        sample_name = rep(seq_len(30), each = 3),
        abiotic_variable_name = rep(
          c("temp", "precip", "rad"), 30
        ),
        abiotic_value = c(
          stats::rnorm(30, mean = 15, sd = 3),
          stats::rnorm(30, mean = 500, sd = 50),
          stats::rnorm(30, mean = 200, sd = 20)
        )
      )

    res <-
      get_predictor_collinearity(
        data_source = data_source
      )

    testthat::expect_true("result" %in% names(res))
    testthat::expect_true("selection" %in% names(res$result))
    testthat::expect_type(res$result$selection, "character")
    testthat::expect_gt(length(res$result$selection), 0)
  }
)


testthat::test_that(
  "get_predictor_collinearity() selection is subset of wide-format columns",
  {
    set.seed(900723)

    vec_predictor_names <-
      c("temp", "precip", "rad")

    data_source <-
      data.frame(
        sample_name = rep(seq_len(30), each = 3),
        abiotic_variable_name = rep(vec_predictor_names, 30),
        abiotic_value = c(
          stats::rnorm(30, mean = 15, sd = 3),
          stats::rnorm(30, mean = 500, sd = 50),
          stats::rnorm(30, mean = 200, sd = 20)
        )
      )

    res <-
      get_predictor_collinearity(
        data_source = data_source
      )

    # After pivot_wider the candidate pool includes the id column
    # ('sample_name') plus the predictor columns
    vec_candidate_cols <-
      c(vec_predictor_names, "sample_name")

    testthat::expect_true(
      all(res$result$selection %in% vec_candidate_cols)
    )
  }
)


testthat::test_that(
  "get_predictor_collinearity() drops the 'age' column before analysis",
  {
    set.seed(900723)

    # Include 'age' as a variable name; it should be excluded and
    # must not appear in the selection output
    data_source <-
      data.frame(
        sample_name = rep(seq_len(30), each = 4),
        abiotic_variable_name = rep(
          c("temp", "precip", "rad", "age"), 30
        ),
        abiotic_value = c(
          stats::rnorm(30, mean = 15, sd = 3),
          stats::rnorm(30, mean = 500, sd = 50),
          stats::rnorm(30, mean = 200, sd = 20),
          seq(0, 290, by = 10)
        )
      )

    res <-
      get_predictor_collinearity(
        data_source = data_source
      )

    testthat::expect_false("age" %in% res$result$selection)
  }
)


testthat::test_that(
  "get_predictor_collinearity() removes highly collinear predictors",
  {
    set.seed(900723)

    # temp2 is temp + tiny noise => highly collinear with temp
    vec_temp <-
      stats::rnorm(50, mean = 15, sd = 3)

    data_source <-
      data.frame(
        sample_name = rep(seq_len(50), each = 2),
        abiotic_variable_name = rep(c("temp", "temp2"), 50),
        abiotic_value = c(
          vec_temp,
          vec_temp + stats::rnorm(50, mean = 0, sd = 0.0001)
        )
      )

    res <-
      get_predictor_collinearity(
        data_source = data_source
      )

    # At most one of the two near-identical predictors should be
    # retained in the selection
    testthat::expect_false(
      all(c("temp", "temp2") %in% res$result$selection)
    )
  }
)

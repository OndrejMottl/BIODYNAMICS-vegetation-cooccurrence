# Helper: build a minimal collinear_output object
.make_collinear_output <- function(selection) {
  res <-
    list(
      result = list(
        selection = selection
      )
    )
  base::class(res) <- "collinear_output"
  return(res)
}

# Helper: build a minimal abiotic data frame
.make_abiotic_df <- function(vars = c("temp", "precip", "ndvi")) {
  data.frame(
    abiotic_variable_name = vars,
    value = base::seq_along(vars) * 1.5,
    stringsAsFactors = FALSE
  )
}

#----------------------------------------------------------#
# Input validation -----
#----------------------------------------------------------#

testthat::test_that(
  "select_non_collinear_predictors() rejects non-data-frame data_source",
  {
    collinear_res <- .make_collinear_output(c("temp"))

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = "not_a_df",
        collinearity_res = collinear_res
      ),
      regexp = "data_source must be a data frame"
    )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = list(a = 1),
        collinearity_res = collinear_res
      ),
      regexp = "data_source must be a data frame"
    )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = NULL,
        collinearity_res = collinear_res
      ),
      regexp = "data_source must be a data frame"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() rejects wrong collinearity_res type",
  {
    data_abiotic <- .make_abiotic_df()

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = list(result = list(selection = "temp"))
      ),
      regexp = "collinearity_res must be a collinear_output object"
    )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = NULL
      ),
      regexp = "collinearity_res must be a collinear_output object"
    )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = "not_an_object"
      ),
      regexp = "collinearity_res must be a collinear_output object"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() rejects missing result element",
  {
    data_abiotic <- .make_abiotic_df()
    bad_res <-
      base::structure(
        list(other = list()),
        class = "collinear_output"
      )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = bad_res
      ),
      regexp = "collinearity_res should contain a 'result' element"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() errors when result missing 'selection'",
  {
    data_abiotic <- .make_abiotic_df()
    bad_res <-
      base::structure(
        list(result = list(other = "x")),
        class = "collinear_output"
      )

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = bad_res
      ),
      regexp = "collinearity_res\\$result should contain a 'selection' element"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() errors when selection is empty",
  {
    data_abiotic <- .make_abiotic_df()
    bad_res <- .make_collinear_output(base::character(0))

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = bad_res
      ),
      regexp = "Selection of predictors should be a non-empty character vector"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() errors when selection is not character",
  {
    data_abiotic <- .make_abiotic_df()
    bad_res <- .make_collinear_output(1:3)

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = bad_res
      ),
      regexp = "Selection of predictors should be a non-empty character vector"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() errors when no rows match selection",
  {
    data_abiotic <- .make_abiotic_df(c("temp", "precip"))
    collinear_res <- .make_collinear_output(c("ndvi"))

    testthat::expect_error(
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      ),
      regexp = "No predictors selected after filtering"
    )
  }
)

#----------------------------------------------------------#
# Output structure -----
#----------------------------------------------------------#

testthat::test_that(
  "select_non_collinear_predictors() returns a data frame",
  {
    data_abiotic <- .make_abiotic_df()
    collinear_res <- .make_collinear_output(c("temp", "precip"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "select_non_collinear_predictors() preserves all columns of data_source",
  {
    data_abiotic <- .make_abiotic_df()
    collinear_res <- .make_collinear_output(c("temp"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(
      base::colnames(res),
      base::colnames(data_abiotic)
    )
  }
)

#----------------------------------------------------------#
# Functional correctness -----
#----------------------------------------------------------#

testthat::test_that(
  "select_non_collinear_predictors() keeps only selected predictors",
  {
    data_abiotic <- .make_abiotic_df(c("temp", "precip", "ndvi", "ph"))
    collinear_res <- .make_collinear_output(c("temp", "ndvi"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true(
      base::all(
        dplyr::pull(res, abiotic_variable_name) %in% c("temp", "ndvi")
      )
    )
    testthat::expect_false(
      "precip" %in% dplyr::pull(res, abiotic_variable_name)
    )
    testthat::expect_false(
      "ph" %in% dplyr::pull(res, abiotic_variable_name)
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() works when selection equals all rows",
  {
    data_abiotic <- .make_abiotic_df(c("temp", "precip", "ndvi"))
    collinear_res <- .make_collinear_output(c("temp", "precip", "ndvi"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_equal(
      base::sort(dplyr::pull(res, abiotic_variable_name)),
      base::sort(c("temp", "precip", "ndvi"))
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() works when selection is a single predictor",
  {
    data_abiotic <- .make_abiotic_df(c("temp", "precip", "ndvi"))
    collinear_res <- .make_collinear_output("precip")

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, abiotic_variable_name),
      "precip"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() ignores unmatched selection names",
  {
    data_abiotic <- .make_abiotic_df(c("temp", "precip"))
    collinear_res <- .make_collinear_output(c("temp", "ndvi"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, abiotic_variable_name),
      "temp"
    )
  }
)

testthat::test_that(
  "select_non_collinear_predictors() preserves original row values",
  {
    data_abiotic <-
      data.frame(
        abiotic_variable_name = c("temp", "precip", "ndvi"),
        value = c(10.5, 200.0, 0.75),
        units = c("C", "mm", "index"),
        stringsAsFactors = FALSE
      )
    collinear_res <- .make_collinear_output(c("precip"))

    res <-
      select_non_collinear_predictors(
        data_source = data_abiotic,
        collinearity_res = collinear_res
      )

    testthat::expect_equal(dplyr::pull(res, value), 200.0)
    testthat::expect_equal(dplyr::pull(res, units), "mm")
  }
)

#----------------------------------------------------------#
# Scale -----
#----------------------------------------------------------#

testthat::test_that(
  "select_non_collinear_predictors() handles moderately large data frames",
  {
    vec_names <-
      base::paste0("var_", base::seq_len(500))
    data_large <-
      data.frame(
        abiotic_variable_name = vec_names,
        value = stats::runif(500),
        stringsAsFactors = FALSE
      )
    vec_selection <-
      base::sample(vec_names, size = 100)
    collinear_res <- .make_collinear_output(vec_selection)

    res <-
      select_non_collinear_predictors(
        data_source = data_large,
        collinearity_res = collinear_res
      )

    testthat::expect_true(base::is.data.frame(res))
    testthat::expect_equal(base::nrow(res), 100L)
    testthat::expect_true(
      base::all(
        dplyr::pull(res, abiotic_variable_name) %in% vec_selection
      )
    )
  }
)

testthat::test_that(
  "make_env_formula() validates input type", {
    testthat::expect_error(
      make_env_formula(data = "not a data frame"),
      "data must be a data frame"
    )

    testthat::expect_error(
      make_env_formula(data = NULL),
      "data must be a data frame"
    )

    testthat::expect_error(
      make_env_formula(data = list(x = 1, y = 2)),
      "data must be a data frame"
    )

    testthat::expect_error(
      make_env_formula(data = matrix(1:4, nrow = 2)),
      "data must be a data frame"
    )

    testthat::expect_error(
      make_env_formula(data = c(1, 2, 3)),
      "data must be a data frame"
    )
  }
)

testthat::test_that(
  "make_env_formula() validates data frame has columns", {
    data_empty_cols <- data.frame()[1:5, ]

    testthat::expect_error(
      make_env_formula(data = data_empty_cols),
      "data must have at least one column"
    )
  }
)

testthat::test_that(
  "make_env_formula() validates data frame has rows", {
    data_empty_rows <- data.frame(x = numeric(0), y = numeric(0))

    testthat::expect_error(
      make_env_formula(data = data_empty_rows),
      "data must have at least one row"
    )
  }
)

testthat::test_that(
  "make_env_formula() returns formula object", {
    data_test <- data.frame(temp = c(10, 15), precip = c(500, 600))

    res <- make_env_formula(data = data_test)

    testthat::expect_true(inherits(res, "formula"))

    testthat::expect_s3_class(res, "formula")
  }
)

testthat::test_that(
  "make_env_formula() creates correct formula without age", {
    data_test <-
      data.frame(
        temp = c(10, 15),
        precip = c(500, 600)
      )

    res <- make_env_formula(data = data_test)

    expected_formula <- as.formula(" ~ temp + precip")

    testthat::expect_equal(res, expected_formula)

    formula_text <- deparse(res)

    testthat::expect_true(grepl("temp", formula_text))

    testthat::expect_true(grepl("precip", formula_text))

    testthat::expect_false(grepl("- 0", formula_text))

    testthat::expect_false(grepl("age", formula_text))
  }
)

testthat::test_that(
  "make_env_formula() creates correct formula with age", {
    data_test <-
      data.frame(
        age = c(100, 200),
        temp = c(10, 15),
        precip = c(500, 600)
      )

    res <- make_env_formula(data = data_test)

    expected_formula <-
      as.formula(" ~  (temp + precip) * age - age")

    testthat::expect_equal(res, expected_formula)

    formula_text <- deparse(res)

    testthat::expect_true(grepl("age", formula_text))

    testthat::expect_true(grepl("temp", formula_text))

    testthat::expect_true(grepl("precip", formula_text))

    testthat::expect_true(grepl("\\*", formula_text))

    testthat::expect_true(grepl("- age", formula_text))
  }
)

testthat::test_that(
  "make_env_formula() handles single column without age", {
    data_test <- data.frame(var1 = c(1, 2, 3))

    res <- make_env_formula(data = data_test)

    expected_formula <- as.formula(" ~ var1")

    testthat::expect_equal(res, expected_formula)
  }
)

testthat::test_that(
  "make_env_formula() handles single column with age", {
    data_test <- data.frame(age = c(100, 200, 300), var1 = c(1, 2, 3))

    res <- make_env_formula(data = data_test)

    expected_formula <- as.formula(" ~ (var1) * age - age")

    testthat::expect_equal(res, expected_formula)
  }
)

testthat::test_that(
  "make_env_formula() handles multiple columns without age", {
    data_test <-
      data.frame(
        var1 = c(1, 2),
        var2 = c(3, 4),
        var3 = c(5, 6),
        var4 = c(7, 8)
      )

    res <- make_env_formula(data = data_test)

    expected_formula <-
      as.formula(" ~ var1 + var2 + var3 + var4")

    testthat::expect_equal(res, expected_formula)

    formula_text <- deparse(res)

    testthat::expect_true(grepl("var1", formula_text))

    testthat::expect_true(grepl("var2", formula_text))

    testthat::expect_true(grepl("var3", formula_text))

    testthat::expect_true(grepl("var4", formula_text))
  }
)

testthat::test_that(
  "make_env_formula() handles multiple columns with age", {
    data_test <-
      data.frame(
        age = c(100, 200),
        var1 = c(1, 2),
        var2 = c(3, 4),
        var3 = c(5, 6)
      )

    res <- make_env_formula(data = data_test)

    expected_formula <-
      as.formula(" ~ (var1 + var2 + var3) * age - age")

    testthat::expect_equal(res, expected_formula)

    formula_text <- deparse(res)

    testthat::expect_true(grepl("age", formula_text))

    testthat::expect_true(grepl("var1", formula_text))

    testthat::expect_true(grepl("var2", formula_text))

    testthat::expect_true(grepl("var3", formula_text))

    testthat::expect_true(grepl("\\*", formula_text))
  }
)

testthat::test_that(
  "make_env_formula() rejects age as only column", {
    data_test <- data.frame(age = c(100, 200, 300))

    testthat::expect_error(
      make_env_formula(data = data_test),
      "data must have at least one column other than 'age' when 'age' is present"
    )
  }
)

testthat::test_that(
  "make_env_formula() preserves column order in formula", {
    data_test <-
      data.frame(
        z_var = c(1, 2),
        a_var = c(3, 4),
        m_var = c(5, 6)
      )

    res <- make_env_formula(data = data_test)

    formula_text <- as.character(res)[2]

    pos_z <- regexpr("z_var", formula_text)[1]

    pos_a <- regexpr("a_var", formula_text)[1]

    pos_m <- regexpr("m_var", formula_text)[1]

    testthat::expect_true(pos_z < pos_a)

    testthat::expect_true(pos_a < pos_m)
  }
)

testthat::test_that(
  "make_env_formula() handles special characters in column names", {
    data_test <-
      data.frame(
        `var.1` = c(1, 2),
        `var_2` = c(3, 4)
      )

    colnames(data_test) <- c("var.1", "var_2")

    res <- make_env_formula(data = data_test)

    testthat::expect_true(inherits(res, "formula"))

    formula_text <- deparse(res)

    testthat::expect_true(grepl("var.1", formula_text, fixed = TRUE))

    testthat::expect_true(grepl("var_2", formula_text, fixed = TRUE))
  }
)

testthat::test_that(
  "make_env_formula() handles NA values in data", {
    data_test <-
      data.frame(
        var1 = c(1, NA, 3),
        var2 = c(NA, 2, 3)
      )

    res <- make_env_formula(data = data_test)

    testthat::expect_true(inherits(res, "formula"))

    expected_formula <- as.formula(" ~ var1 + var2")

    testthat::expect_equal(res, expected_formula)
  }
)

testthat::test_that(
  "make_env_formula() handles larger dataset", {
    set.seed(900723)

    data_test <-
      as.data.frame(
        matrix(
          rnorm(1000 * 9),
          nrow = 1000,
          ncol = 9
        )
      )

    colnames(data_test) <-
      paste0("var", seq_len(ncol(data_test)))

    res <- make_env_formula(data = data_test)

    testthat::expect_true(inherits(res, "formula"))

    formula_text <- deparse(res)

    for (i in seq_len(9)) {
      testthat::expect_true(
        grepl(paste0("var", i), formula_text)
      )
    }
  }
)

testthat::test_that(
  "make_env_formula() formula excludes intercept", {
    data_test <- data.frame(temp = c(10, 15), precip = c(500, 600))

    res <- make_env_formula(data = data_test)

    formula_text <- deparse(res)

    testthat::expect_false(grepl("- age", formula_text))
  }
)

testthat::test_that(
  "make_env_formula() handles tibble input", {
    data_test <-
      tibble::tibble(
        temp = c(10, 15),
        precip = c(500, 600)
      )

    res <- make_env_formula(data = data_test)

    testthat::expect_true(inherits(res, "formula"))

    expected_formula <- as.formula(" ~ temp + precip")

    testthat::expect_equal(res, expected_formula)
  }
)

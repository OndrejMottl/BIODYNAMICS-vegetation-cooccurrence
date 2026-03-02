testthat::test_that(
  "filter_rare_taxa() validates data parameter type",
  {
    testthat::expect_error(
      filter_rare_taxa(data = "not a data frame"),
      "data must be a data frame"
    )

    testthat::expect_error(
      filter_rare_taxa(data = NULL),
      "data must be a data frame"
    )

    testthat::expect_error(
      filter_rare_taxa(data = list(taxon = 0.5, value = 10)),
      "data must be a data frame"
    )

    testthat::expect_error(
      filter_rare_taxa(data = matrix(1:4, nrow = 2)),
      "data must be a data frame"
    )

    testthat::expect_error(
      filter_rare_taxa(data = c(0.1, 0.2, 0.3)),
      "data must be a data frame"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() validates minimal_proportion is numeric",
  {
    data_test <- data.frame(pollen_prop = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = "0.01"),
      "minimal_proportion must be a number"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = NULL),
      "minimal_proportion must be a number"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = TRUE),
      "minimal_proportion must be a number"
    )

    testthat::expect_error(
      filter_rare_taxa(
        data = data_test,
        minimal_proportion = data.frame(x = 0.01)
      ),
      "minimal_proportion must be a number"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() validates minimal_proportion is greater than 0",
  {
    data_test <- data.frame(pollen_prop = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 0),
      "minimal_proportion must be greater than 0"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = -0.1),
      "minimal_proportion must be greater than 0"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = -1),
      "minimal_proportion must be greater than 0"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() validates minimal_proportion is <= 1",
  {
    data_test <- data.frame(pollen_prop = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 1.1),
      "minimal_proportion must be less than or equal to 1"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 2),
      "minimal_proportion must be less than or equal to 1"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 100),
      "minimal_proportion must be less than or equal to 1"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() accepts valid minimal_proportion values",
  {
    data_test <- data.frame(pollen_prop = c(0.05, 0.15, 0.5, 1))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_true(is.data.frame(res))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.5)

    testthat::expect_true(is.data.frame(res))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 1)

    testthat::expect_true(is.data.frame(res))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.001)

    testthat::expect_true(is.data.frame(res))
  }
)

testthat::test_that(
  "filter_rare_taxa() returns data frame",
  {
    data_test <- data.frame(pollen_prop = c(0.05, 0.15, 0.25))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_true(is.data.frame(res))

    testthat::expect_s3_class(res, "data.frame")
  }
)

testthat::test_that(
  "filter_rare_taxa() filters taxa correctly",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.005, 0.015, 0.025, 0.050, 0.150)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(nrow(res), 4)

    testthat::expect_true(all(res$pollen_prop >= 0.01))

    testthat::expect_false(any(res$pollen_prop < 0.01))
  }
)

testthat::test_that(
  "filter_rare_taxa() filters with different thresholds",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.005, 0.015, 0.025, 0.050, 0.150, 0.250)
      )

    res_01 <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(nrow(res_01), 5)

    testthat::expect_true(all(res_01$pollen_prop >= 0.01))

    res_05 <- filter_rare_taxa(data = data_test, minimal_proportion = 0.05)

    testthat::expect_equal(nrow(res_05), 3)

    testthat::expect_true(all(res_05$pollen_prop >= 0.05))

    res_10 <- filter_rare_taxa(data = data_test, minimal_proportion = 0.10)

    testthat::expect_equal(nrow(res_10), 2)

    testthat::expect_true(all(res_10$pollen_prop >= 0.10))
  }
)

testthat::test_that(
  "filter_rare_taxa() uses default minimal_proportion",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.005, 0.015, 0.025, 0.050)
      )

    res <- filter_rare_taxa(data = data_test)

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(res$pollen_prop >= 0.01))
  }
)

testthat::test_that(
  "filter_rare_taxa() preserves data structure and columns",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, 0.15, 0.25),
        species = c("sp1", "sp2", "sp3"),
        count = c(5, 15, 25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(ncol(res), ncol(data_test))

    testthat::expect_equal(colnames(res), colnames(data_test))

    testthat::expect_true("species" %in% colnames(res))

    testthat::expect_true("count" %in% colnames(res))
  }
)

testthat::test_that(
  "filter_rare_taxa() errors when no taxa meet threshold",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.005, 0.008, 0.009)
      )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 0.01),
      "No taxa found in data"
    )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 0.01),
      "minimal_proportion is too high"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() errors when all taxa filtered out",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, 0.15, 0.25)
      )

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 0.5),
      "No taxa found in data"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() handles exact threshold values",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.01, 0.02, 0.03)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(res$pollen_prop >= 0.01))

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.02)

    testthat::expect_equal(nrow(res), 2)

    testthat::expect_true(min(res$pollen_prop) == 0.02)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles single row data",
  {
    data_test <- data.frame(pollen_prop = 0.05)

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(nrow(res), 1)

    testthat::expect_equal(res$pollen_prop, 0.05)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles single row below threshold",
  {
    data_test <- data.frame(pollen_prop = 0.005)

    testthat::expect_error(
      filter_rare_taxa(data = data_test, minimal_proportion = 0.01),
      "No taxa found in data"
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() handles larger datasets",
  {
    set.seed(900723)

    data_test <-
      data.frame(
        pollen_prop = runif(1000, min = 0, max = 1)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.1)

    testthat::expect_true(is.data.frame(res))

    testthat::expect_true(all(res$pollen_prop >= 0.1))

    testthat::expect_true(nrow(res) < nrow(data_test))

    testthat::expect_equal(
      nrow(res),
      sum(data_test$pollen_prop >= 0.1)
    )
  }
)

testthat::test_that(
  "filter_rare_taxa() preserves row order",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.25, 0.05, 0.15, 0.02, 0.35),
        id = 1:5
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.03)

    expected_ids <- c(1, 2, 3, 5)

    testthat::expect_equal(res$id, expected_ids)

    testthat::expect_equal(res$pollen_prop[1], 0.25)

    testthat::expect_equal(res$pollen_prop[2], 0.05)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles tibble input",
  {
    data_test <-
      tibble::tibble(
        pollen_prop = c(0.05, 0.15, 0.25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_true(is.data.frame(res))

    testthat::expect_equal(nrow(res), 3)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles NA values in pollen_prop column",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, NA, 0.15, 0.25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_true(is.data.frame(res))

    testthat::expect_false(any(is.na(res$pollen_prop)))
  }
)

testthat::test_that(
  "filter_rare_taxa() handles special numeric values",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, Inf, 0.15, -Inf, 0.25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_true(is.data.frame(res))

    testthat::expect_true(Inf %in% res$pollen_prop)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles boundary value 1",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.5, 0.8, 1.0)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 1)

    testthat::expect_equal(nrow(res), 1)

    testthat::expect_equal(res$pollen_prop, 1.0)
  }
)

testthat::test_that(
  "filter_rare_taxa() handles very small threshold",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.00005, 0.00015, 0.00025)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.0001)

    testthat::expect_equal(nrow(res), 2)

    testthat::expect_true(all(res$pollen_prop >= 0.0001))
  }
)

testthat::test_that(
  "filter_rare_taxa() handles mixed positive and negative values",
  {
    data_test <-
      data.frame(
        pollen_prop = c(-0.05, 0.05, 0.15, 0.25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.01)

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_false(any(res$pollen_prop < 0))
  }
)

testthat::test_that(
  "filter_rare_taxa() handles duplicate pollen_prop values",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, 0.05, 0.15, 0.15, 0.25),
        id = 1:5
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = 0.1)

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(res$pollen_prop >= 0.1))
  }
)

testthat::test_that(
  "filter_rare_taxa() handles minimal_proportion with vector input",
  {
    data_test <-
      data.frame(
        pollen_prop = c(0.05, 0.15, 0.25)
      )

    res <- filter_rare_taxa(data = data_test, minimal_proportion = c(0.01))

    testthat::expect_true(is.data.frame(res))

    testthat::expect_equal(nrow(res), 3)
  }
)

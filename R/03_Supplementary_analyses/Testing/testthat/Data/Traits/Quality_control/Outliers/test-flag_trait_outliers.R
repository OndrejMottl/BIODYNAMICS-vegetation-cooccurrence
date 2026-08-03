testthat::test_that(
  "flag_trait_outliers() errors on non-data-frame data",
  {
    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = "not_a_df",
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = NULL,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = base::c(1, 2, 3),
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors on ungrouped data frame",
  {
    data_ungrouped <-
      tibble::tibble(
        group = base::c("a", "a", "b"),
        trait_value = base::c(1, 2, 3)
      )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_ungrouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors when trait_value_column missing",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "no_such_col",
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors on invalid trait_value_column arg",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a"),
        trait_value = base::c(1, 2)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = 123,
        iqr_multiplier = 1.5
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = base::c("trait_value", "group"),
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors when iqr_multiplier is missing",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a"),
        trait_value = base::c(1, 2)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value"
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors on invalid iqr_multiplier",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = "large"
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = -1
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 0
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = base::c(1.5, 2.5)
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors on invalid minimum_group_size",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = "five"
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = -1L
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 0L
      )
    )

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = base::c(3L, 5L)
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() errors on non-numeric trait_value_column column",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c("x", "y", "z", "w")
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() returns a data frame",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "a", "a"),
        trait_value = base::c(1, 2, 3, 4, 5)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() returns an ungrouped data frame",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "b", "b", "b"),
        trait_value = base::c(1, 2, 3, 4, 5, 6)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_equal(
      base::length(dplyr::group_vars(res)),
      0L
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() adds n_group_records and is_trait_outlier columns",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    col_names <-
      base::colnames(res)

    testthat::expect_true(
      "n_group_records" %in% col_names
    )

    testthat::expect_true(
      "is_trait_outlier" %in% col_names
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() n_group_records is integer type",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_type(
      dplyr::pull(res, n_group_records),
      "integer"
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() is_trait_outlier is logical type",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_type(
      dplyr::pull(res, is_trait_outlier),
      "logical"
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() preserves row count",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4, 5)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_equal(
      base::nrow(res),
      5L
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() flags clear outlier in one group",
  {
    # One group, 9 normal values + 1 extreme outlier
    trait_vals <-
      base::c(10, 11, 10, 9, 11, 10, 10, 11, 9, 1000)

    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        trait_value = trait_vals
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    # Only the extreme value (1000) should be flagged
    vec_is_trait_outlier <-
      dplyr::pull(res, is_trait_outlier)

    vec_values <-
      dplyr::pull(res, trait_value)

    testthat::expect_true(
      vec_is_trait_outlier[base::which(vec_values == 1000)]
    )

    testthat::expect_equal(
      base::sum(vec_is_trait_outlier),
      1L
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() does not confuse outliers across groups",
  {
    # Group A: normal values; Group B: outlier only in B
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("A", 6L),
          base::rep("B", 6L)
        ),
        trait_value = base::c(
          5, 6, 5, 6, 5, 6,       # group A: no outlier
          5, 6, 5, 6, 5, 9999     # group B: one outlier
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    res_a <-
      dplyr::filter(res, group == "A")

    res_b <-
      dplyr::filter(res, group == "B")

    # No outliers in group A
    testthat::expect_true(
      base::all(
        dplyr::pull(res_a, is_trait_outlier) == FALSE
      )
    )

    # Exactly one outlier in group B
    testthat::expect_equal(
      base::sum(dplyr::pull(res_b, is_trait_outlier)),
      1L
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() flags no outlier when IQR is zero",
  {
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 5L),
        trait_value = base::rep(5.0, 5L)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    testthat::expect_true(
      base::all(
        dplyr::pull(res, is_trait_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() computes correct n_group_records per group",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("A", 4L),
          base::rep("B", 7L)
        ),
        trait_value = base::c(
          1, 2, 3, 4,
          10, 11, 12, 13, 14, 15, 16
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    res_a <-
      dplyr::filter(res, group == "A")

    res_b <-
      dplyr::filter(res, group == "B")

    testthat::expect_true(
      base::all(dplyr::pull(res_a, n_group_records) == 4L)
    )

    testthat::expect_true(
      base::all(dplyr::pull(res_b, n_group_records) == 7L)
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() symmetric fence flags both tails",
  {
    # Median 50, IQR 20 (Q1=40, Q3=60)
    # Fence: [50 - 1.5*20, 50 + 1.5*20] = [20, 80]
    # 10 should be flagged (below), 90 should be flagged (above)
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 8L),
        trait_value = base::c(
          40, 45, 50, 55, 60, 50,
          10,   # below fence
          90    # above fence
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    vec_values <-
      dplyr::pull(res, trait_value)

    vec_is_trait_outlier <-
      dplyr::pull(res, is_trait_outlier)

    testthat::expect_true(
      vec_is_trait_outlier[base::which(vec_values == 10)]
    )

    testthat::expect_true(
      vec_is_trait_outlier[base::which(vec_values == 90)]
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() with minimum_group_size: small group not flagged",
  {
    # Group A: only 2 rows, minimum_group_size = 3, extreme value present
    data_grouped <-
      tibble::tibble(
        group = base::c("A", "A", "B", "B", "B", "B", "B"),
        trait_value = base::c(
          1, 99999,               # group A: extreme but n < minimum_group_size
          10, 11, 10, 11, 99999  # group B: extreme and n >= minimum_group_size
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 3L
      )

    res_a <-
      dplyr::filter(res, group == "A")

    testthat::expect_true(
      base::all(
        dplyr::pull(res_a, is_trait_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() with minimum_group_size: zero IQR not flagged",
  {
    # Group with all identical values: IQR = 0, minimum_group_size supplied
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 5L),
        trait_value = base::rep(7.0, 5L)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 3L
      )

    testthat::expect_true(
      base::all(
        dplyr::pull(res, is_trait_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() with minimum_group_size: large group still flagged",
  {
    # Group with >= minimum_group_size and clear outlier
    trait_vals <-
      base::c(10, 11, 10, 9, 11, 10, 10, 11, 9, 1000)

    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        trait_value = trait_vals
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 5L
      )

    vec_values <-
      dplyr::pull(res, trait_value)

    vec_is_trait_outlier <-
      dplyr::pull(res, is_trait_outlier)

    testthat::expect_true(
      vec_is_trait_outlier[base::which(vec_values == 1000)]
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() always computes group record counts",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("small", 2L),
          base::rep("large", 8L)
        ),
        trait_value = base::c(
          1, 99,
          10, 11, 10, 11, 10, 11, 10, 9999
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 5L
      )

    res_small <-
      dplyr::filter(res, group == "small")

    res_large <-
      dplyr::filter(res, group == "large")

    testthat::expect_true(
      base::all(dplyr::pull(res_small, n_group_records) == 2L)
    )

    testthat::expect_true(
      base::all(dplyr::pull(res_large, n_group_records) == 8L)
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() single-row group: is_trait_outlier FALSE",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("solo", "multi", "multi", "multi"),
        trait_value = base::c(99999, 1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5
      )

    res_solo <-
      dplyr::filter(res, group == "solo")

    testthat::expect_false(
      dplyr::pull(res_solo, is_trait_outlier)
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() single-row group: FALSE with minimum_group_size",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("solo", "multi", "multi", "multi"),
        trait_value = base::c(99999, 1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 1.5,
        minimum_group_size = 3L
      )

    res_solo <-
      dplyr::filter(res, group == "solo")

    testthat::expect_false(
      dplyr::pull(res_solo, is_trait_outlier)
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() works with non-default trait_value_column",
  {
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        my_value = base::c(
          10, 11, 10, 9, 11, 10, 10, 11, 9, 1000
        )
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "my_value",
        iqr_multiplier = 1.5
      )

    vec_values <-
      dplyr::pull(res, my_value)

    vec_is_trait_outlier <-
      dplyr::pull(res, is_trait_outlier)

    testthat::expect_true(
      vec_is_trait_outlier[base::which(vec_values == 1000)]
    )

    testthat::expect_equal(
      base::sum(vec_is_trait_outlier),
      1L
    )
  }
)

testthat::test_that(
  "flag_trait_outliers() works on large synthetic dataset",
  {
    base::set.seed(900723)

    n_rows <- 120L
    groups <-
      base::sample(
        x = base::c("grp1", "grp2", "grp3", "grp4"),
        size = n_rows,
        replace = TRUE
      )

    values <-
      stats::rnorm(n = n_rows, mean = 50, sd = 5)

    data_grouped <-
      tibble::tibble(
        group = groups,
        trait_value = values
      ) |>
      dplyr::group_by(group)

    res <-
      flag_trait_outliers(
        data_trait_records = data_grouped,
        trait_value_column = "trait_value",
        iqr_multiplier = 3
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )

    testthat::expect_equal(
      base::nrow(res),
      n_rows
    )

    col_names <-
      base::colnames(res)

    testthat::expect_true("n_group_records" %in% col_names)
    testthat::expect_true("is_trait_outlier" %in% col_names)

    testthat::expect_type(
      dplyr::pull(res, n_group_records),
      "integer"
    )

    testthat::expect_type(
      dplyr::pull(res, is_trait_outlier),
      "logical"
    )
  }
)
